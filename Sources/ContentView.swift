import SwiftUI
import UniformTypeIdentifiers
import UIKit
import Network

// MARK: - Main ContentView

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    // Localization
    @ObservedObject private var localizationManager = LocalizationManager.shared

    // Pairing
    @AppStorage("PairingFile") private var pairingFile: String?
    private static let mobileDevicePairingType = UTType(
        importedAs: "com.iamgasgass.mobiledevicepairing",
        conformingTo: .propertyList
    )

    // Services state
    @State private var heartbeatRunning = false
    // DDI state comes from StikDebug's MountingProgress (see DDI/mountDDI.swift)
    @ObservedObject private var mounting = MountingProgress.shared
    private var ddiMounted: Bool { mounting.coolisMounted }
    @State private var heartbeatStartInProgress = false
    private let ddiCheckTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // UI state
    @State private var showPairingFileImporter = false
    @State private var showErrorAlert = false
    @State private var lastError: String?
    @State private var showStatusSheet = false
    @State private var _showApplySheet = false
    @State private var path = NavigationPath()
    @State private var showUUIDAlert = false
    
    // Pairing file replacement confirmation
    @State private var showPairingReplaceConfirm = false
    @State private var pendingPairingFileText: String?
    
    // Binding for external control of apply sheet (default to internal state)
    var showApplySheetBinding: Binding<Bool>? = nil
    var showStatusSheetBinding: Binding<Bool>? = nil
    
    // Hide the bottom Apply button when using navigation bar
    var hideBottomApplyButton: Bool = false
    
    // Optional bindings to track navigation state
    var isInNestedViewBinding: Binding<Bool>?
    var isSystemReadyBinding: Binding<Bool>?
    var heartbeatRunningBinding: Binding<Bool>?
    var ddiMountedBinding: Binding<Bool>?
    
    // Internal state for when used standalone
    @State private var _isInNestedView = false
    @State private var _isSystemReadyState = false
    
    // Computed bindings
    private var isInNestedView: Binding<Bool> {
        isInNestedViewBinding ?? $_isInNestedView
    }
    
    private var isSystemReady: Binding<Bool> {
        isSystemReadyBinding ?? $_isSystemReadyState
    }
    
    // Computed property to handle both internal and external control
    private var showApplySheet: Binding<Bool> {
        showApplySheetBinding ?? $_showApplySheet
    }
    
    private var statusSheet: Binding<Bool> {
        showStatusSheetBinding ?? $showStatusSheet
    }
    
    // Computed system ready state
    private var _isSystemReady: Bool {
        pairingFile != nil && heartbeatRunning && ddiMounted
    }

    // Tools (shared from MainViewWithNavigation)
    @ObservedObject var toolStore: ToolStore
    @ObservedObject var toolRunner: ToolRunner
    @ObservedObject var walletStore: AppleWalletStore
    @ObservedObject var themeStore: PasscodeThemeStore
    @ObservedObject var featureFlagsStore: FeatureFlagsStore

    // Update check
    private let versionJSONURL = URL(string: "https://raw.githubusercontent.com/YangJiiii/EnsWilde/refs/heads/main/version.json")!
    @State private var showUpdateAlert = false
    @State private var updateURL: URL?
    @State private var updateMessage: String = ""
    @State private var lastCheckedBuild: Int = -1
    @AppStorage("IgnoredUpdateBuild") private var ignoredUpdateBuild: Int = 0
    @State private var pendingRemoteBuild: Int = 0
    
    // Network monitoring for VPN auto-refresh
    @State private var networkMonitor: NWPathMonitor?
    
    // Auto-reset pairing file when not ready
    @State private var pairingResetTimer: DispatchWorkItem?
    @State private var pairingResetAttempted = false
    
    
    // Animation Config (Hiệu ứng trượt mượt mà)
    private let panelAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    
    // Custom initializer to accept optional bindings
    init(
        themeStore: PasscodeThemeStore,
        toolStore: ToolStore,
        toolRunner: ToolRunner,
        walletStore: AppleWalletStore,
        featureFlagsStore: FeatureFlagsStore,
        showApplySheetBinding: Binding<Bool>? = nil,
        showStatusSheetBinding: Binding<Bool>? = nil,
        hideBottomApplyButton: Bool = false,
        isInNestedViewBinding: Binding<Bool>? = nil,
        isSystemReadyBinding: Binding<Bool>? = nil,
        heartbeatRunningBinding: Binding<Bool>? = nil,
        ddiMountedBinding: Binding<Bool>? = nil
    ) {
        self.themeStore = themeStore
        self.toolStore = toolStore
        self.toolRunner = toolRunner
        self.walletStore = walletStore
        self.featureFlagsStore = featureFlagsStore
        self.showApplySheetBinding = showApplySheetBinding
        self.showStatusSheetBinding = showStatusSheetBinding
        self.hideBottomApplyButton = hideBottomApplyButton
        self.isInNestedViewBinding = isInNestedViewBinding
        self.isSystemReadyBinding = isSystemReadyBinding
        self.heartbeatRunningBinding = heartbeatRunningBinding
        self.ddiMountedBinding = ddiMountedBinding
    }

    var body: some View {
        NavigationStack(path: $path) {
            GlassForm {
                statusSection
                tweaksSection
            }
            .liquidGlassScreenStyle()
            .headerProminence(.increased)
            .navigationTitle("SparsWilde")
            .navigationDestination(for: String.self) { route in
                destinationView(for: route)
            }
        } // NavigationStack End
        .onChange(of: path) { newPath in
            isInNestedView.wrappedValue = !newPath.isEmpty
        }
        .onChange(of: _isSystemReady) { newValue in
            isSystemReady.wrappedValue = newValue
        }
        .onChange(of: heartbeatRunning) { newValue in
            heartbeatRunningBinding?.wrappedValue = newValue
        }
        .onChange(of: ddiMounted) { newValue in
            ddiMountedBinding?.wrappedValue = newValue
        }
        .onAppear {
            isSystemReady.wrappedValue = _isSystemReady
            heartbeatRunningBinding?.wrappedValue = heartbeatRunning
            ddiMountedBinding?.wrappedValue = ddiMounted
        }
        .sheet(isPresented: statusSheet) {
            statusSheetContent
        }
        .sheet(isPresented: showApplySheet) {
            applySheetContent
        }
        .fileImporter(
            isPresented: $showPairingFileImporter,
            allowedContentTypes: [
                .propertyList,
                Self.mobileDevicePairingType
            ],
            onCompletion: handleFileImport
        )
        .onOpenURL { url in
            // Also support opening a pairing file directly from Files / Share Sheet.
            guard url.isFileURL else { return }
            handleFileImport(.success(url))
        }
        .alert("System Message", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(lastError ?? "An unknown error occurred.")
        }
        .alert("Update Available", isPresented: $showUpdateAlert) {
            Button("Cancel", role: .cancel) { ignoredUpdateBuild = pendingRemoteBuild }
            Button("Open") {
                if let url = updateURL { UIApplication.shared.open(url) }
            }
        } message: {
            Text(updateMessage)
        }
        .alert("UUID Required", isPresented: $showUUIDAlert) {
            Button("Cancel", role: .cancel) { }
            Button("OK") {
                handleUUIDCapture()
            }
        } message: {
            Text("Please open Books app and download a book to capture UUID. The app will automatically return and apply tweaks.")
        }
        .alert("Replace Existing Pairing File?", isPresented: $showPairingReplaceConfirm) {
            Button("Cancel", role: .cancel) {
                pendingPairingFileText = nil
            }
            Button("Replace", role: .destructive) {
                if let text = pendingPairingFileText {
                    importPairingFile(text)
                }
                pendingPairingFileText = nil
            }
        } message: {
            Text("You already have a pairing file loaded. Do you want to replace it with the new one? This will restart the connection.")
        }
        .onAppear {
            runStartupChecksOnce()
            checkForUpdate()
            refreshSystemStatus()
            startNetworkMonitoring()
        }
        .onChange(of: scenePhase) {
            handleScenePhase(scenePhase)
            if scenePhase == .active {
                autoLoadSideStorePairingIfNeeded()
                checkForUpdate()
                refreshSystemStatus()
                if pairingFile != nil && !_isSystemReady {
                    startPairingResetTimer()
                }
            } else if scenePhase == .background {
                cancelPairingResetTimer()
            }
        }
        .onChange(of: heartbeatRunning) {
            if heartbeatRunning {
                print("[Auto-Reset] Heartbeat running, canceling timer")
                cancelPairingResetTimer()
            }
        }
        .onChange(of: _isSystemReady) {
            if _isSystemReady {
                print("[Auto-Reset] System ready, canceling timer")
                cancelPairingResetTimer()
                pairingResetAttempted = false
            } else if pairingFile != nil {
                startPairingResetTimer()
            }
        }
        .onChange(of: pairingFile) {
            pairingResetAttempted = false
            if pairingFile == nil {
                cancelPairingResetTimer()
            }
        }
        .onReceive(ddiCheckTimer) { _ in
            // Same as StikDebug HomeView: poll mount state while not mounted and not mounting
            if pairingFile != nil && heartbeatRunning && mounting.mountingThread == nil && !mounting.coolisMounted {
                MountingProgress.shared.checkforMounted()
            }
        }
        .onDisappear {
            stopNetworkMonitoring()
            cancelPairingResetTimer()
        }
    } // Body End

    // MARK: - Body Sections

    @ViewBuilder
    private var statusSection: some View {
        GlassSection(header: Text(L("section_status"))) {
            CardRow(
                title: L("system_status"),
                subtitle: _isSystemReady ? L("system_status_ready") : L("system_status_not_ready"),
                ok: _isSystemReady,
                showChevron: false,
                trailing: nil
            )

            if pairingFile == nil {
                Button(action: { showPairingFileImporter = true }) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("pairing_file_missing"))
                            Text(L("pairing_file_import_prompt"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }

            if !heartbeatRunning && pairingFile != nil {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("heartbeat_not_running"))
                        Text(L("heartbeat_enable_vpn"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }

            if !ddiMounted && pairingFile != nil && heartbeatRunning {
                ddiStatusLabel
            }
        }
    }

    @ViewBuilder
    private var ddiStatusLabel: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("ddi_not_mounted"))
                if mounting.mountingThread != nil {
                    Text("Mounting Developer Disk Image…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !ddiFilesAreDownloaded() {
                    Text("Download the DDI files in Settings first.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(L("ddi_auto_mount_attempt"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.accentColor)
        }
    }

    @ViewBuilder
    private var tweaksSection: some View {
        GlassCardGroup(header: Text(L("section_tweaks"))) {
            toolNavigationLink(
                value: "MobileGestalt",
                title: L("tool_mobile_gestalt"),
                subtitle: L("tool_mobile_gestalt_desc"),
                icon: "cpu",
                isEnabled: toolStore.replaceMobileGestaltEnabled
            )

            toolNavigationLink(
                value: "ThemesUI",
                title: L("tool_themes_ui"),
                subtitle: L("tool_themes_ui_desc"),
                icon: "paintbrush",
                isEnabled: toolStore.themesUIEnabled
            )

            toolNavigationLink(
                value: "PasscodeTheme",
                title: L("tool_passcode_theme"),
                subtitle: L("tool_passcode_theme_desc"),
                icon: "lock.rectangle",
                isEnabled: themeStore.passcodeThemeEnabled
            )

            toolNavigationLink(
                value: "DisableSound",
                title: L("tool_disable_sound"),
                subtitle: L("tool_disable_sound_desc"),
                icon: "speaker.slash",
                isEnabled: toolStore.disableSoundEnabled
            )

            toolNavigationLink(
                value: "AppleWallet",
                title: L("tool_apple_wallet"),
                subtitle: L("tool_apple_wallet_desc"),
                icon: "wallet.pass",
                isEnabled: walletStore.appleWalletEnabled
            )

            toolNavigationLink(
                value: "FeatureFlags",
                title: L("tool_feature_flags"),
                subtitle: L("tool_feature_flags_desc"),
                icon: "flag",
                isEnabled: featureFlagsStore.featureFlagsEnabled
            )

            toolNavigationLink(
                value: "SystemTweaks",
                title: L("tool_system_tweaks"),
                subtitle: L("tool_system_tweaks_desc"),
                icon: "slider.horizontal.3",
                isEnabled: toolStore.systemTweaksEnabled
            )

            toolNavigationLink(
                value: "zPatchCustom",
                title: L("tool_zpatch_custom"),
                subtitle: L("tool_zpatch_custom_desc"),
                icon: "wrench.and.screwdriver",
                isEnabled: toolStore.zPatchCustomEnabled
            )
        }
    }

    // MARK: - Navigation Destination

    @ViewBuilder
    private func destinationView(for route: String) -> some View {
        if route == "DisableSound" {
            DisableSoundView()
        } else if route == "MobileGestalt" {
            MobileGestaltView(toolStore: toolStore)
        } else if route == "AppleWallet" {
            AppleWalletView(walletStore: walletStore)
        } else if route == "PasscodeTheme" {
            PasscodeThemeView(themeStore: themeStore)
        } else if route == "ThemesUI" {
            ThemesUIView(toolStore: toolStore)
        } else if route == "zPatchCustom" {
            zPatchCustomView()
        } else if route == "FeatureFlags" {
            FeatureFlagsView(store: featureFlagsStore)
        } else if route == "SystemTweaks" {
            NuggetSystemTweaksView(toolStore: toolStore)
        }
    }

    // MARK: - Sheet Contents

    private var statusSheetContent: some View {
        StatusSheet(
            pairingFileLoaded: .constant(pairingFile != nil),
            heartbeatRunning: $heartbeatRunning,
            ddiMounted: $mounting.coolisMounted,
            onImportPairing: { showPairingFileImporter = true },
            onResetPairing: { resetPairing() },
            onMountDDI: { MountingProgress.shared.pubMount() },
            onClose: { statusSheet.wrappedValue = false }
        )
        .presentationDetents([.medium, .large])
    }

    private var applySheetContent: some View {
        ApplySheet(
            logs: .constant(toolRunner.logs.map { $0.text }),
            isRunning: .constant(isApplyRunning(toolRunner.state)),
            progressText: .constant(applyStatusText(toolRunner.state)),
            enableRespring: $toolStore.soundRespringEnabled,
            bookassetdUUID: .constant(toolStore.bookassetdUUID ?? ""),
            onApply: {
                Task {
                    if toolStore.bookassetdUUID == nil || toolStore.bookassetdUUID?.isEmpty == true {
                        showUUIDAlert = true
                        return
                    }
                    
                    await toolRunner.applyAll(isSystemReady: _isSystemReady, store: toolStore, walletStore: walletStore, themeStore: themeStore, featureFlagsStore: featureFlagsStore)
                    
                    if case .success = toolRunner.state {
                        try? await Task.sleep(nanoseconds: 8_000_000_000)
                        
                        if toolStore.soundRespringEnabled {
                            try? respringNow()
                        } else {
                            if let bundleID = Bundle.main.bundleIdentifier {
                                LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: bundleID)
                            }
                        }
                    }
                    
                    if case .failed(let message) = toolRunner.state {
                        lastError = message
                        showErrorAlert = true
                    }
                }
            },
            onClearUUID: { toolStore.bookassetdUUID = nil },
            onClose: { showApplySheet.wrappedValue = false }
        )
        .presentationDetents([.large])
    }

    // MARK: - UUID Capture

    private func handleUUIDCapture() {
        LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.iBooks")
        
        Task {
            do {
                let uuid = try await BookassetdUUIDHelper.captureUUID(
                    timeout: 120,
                    openBooksFirst: false,
                    returnToAppAfterCapture: true
                )
                toolStore.bookassetdUUID = uuid
                
                DispatchQueue.main.async {
                    lastError = "UUID captured successfully! Auto-applying tweaks..."
                    showErrorAlert = true
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        await self.toolRunner.applyAll(isSystemReady: self._isSystemReady, store: self.toolStore, walletStore: self.walletStore, themeStore: self.themeStore, featureFlagsStore: self.featureFlagsStore)
                        
                        if case .success = self.toolRunner.state {
                            try? await Task.sleep(nanoseconds: 8_000_000_000)
                            
                            if self.toolStore.soundRespringEnabled {
                                try? self.respringNow()
                            } else {
                                if let bundleID = Bundle.main.bundleIdentifier {
                                    LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: bundleID)
                                }
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    lastError = "Failed to capture UUID: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }

    // MARK: - Tool Navigation Link (Liquid Glass tile)

    @ViewBuilder
    private func toolNavigationLink(value: String, title: String, subtitle: String, icon: String, isEnabled: Bool) -> some View {
        NavigationLink(value: value) {
            HStack(spacing: 14) {
                GlassIconBadge(systemName: icon, size: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                if isEnabled {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                }

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Logic Functions

    private func isApplyRunning(_ state: ToolRunState) -> Bool {
        if case .running = state { return true }
        return false
    }

    private func applyStatusText(_ state: ToolRunState) -> String {
        if !_isSystemReady {
            if pairingFile == nil { return "Select pairing file to continue." }
            if !heartbeatRunning { return "Enable LocalDevVPN/StikDebug and reopen app." }
            if !ddiMounted { return "Mount DDI to enable tools." }
        }
        switch state {
        case .idle: return "Ready. This will run all enabled tools in order."
        case .running(let toolName): return "Running \(toolName)…"
        case .success: return "Done."
        case .failed(let message): return "Failed: \(message)"
        }
    }

    private var appVersionFooter: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "Version \(v) (\(b))"
    }

    private var currentBuildInt: Int {
        Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0") ?? 0
    }

    private func runStartupChecksOnce() {
        // Fix #4 & #5: Add error handling for file operations
        
        // First, validate the pairingFile from @AppStorage if it exists
        if let existingPairingFile = pairingFile, !existingPairingFile.isEmpty {
            do {
                // Validate it can be parsed
                let _ = try PairingFileParser.parseUDID(fromPlistText: existingPairingFile)
                // Valid - keep it
            } catch {
                // Invalid pairing file in @AppStorage - clear it and show notification
                print("Removing invalid pairing file from @AppStorage: \(error.localizedDescription)")
                pairingFile = nil
                
                // Show alert to user
                DispatchQueue.main.async {
                    self.lastError = L("error_pairing_invalid_appstorage")
                    self.showErrorAlert = true
                }
                
                // Also remove from disk
                let pairingPath = URL.documentsDirectory.appendingPathComponent("pairingFile.plist")
                try? FileManager.default.removeItem(at: pairingPath)
            }
        }
        
        // Then check disk for pairing file if @AppStorage doesn't have one
        if pairingFile == nil {
            let pairingPath = URL.documentsDirectory.appendingPathComponent("pairingFile.plist")
            if FileManager.default.fileExists(atPath: pairingPath.path) {
                if let text = try? String(contentsOf: pairingPath, encoding: .utf8) {
                    // Validate the pairing file before using it
                    do {
                        let _ = try PairingFileParser.parseUDID(fromPlistText: text)
                        // Valid pairing file
                        pairingFile = text
                    } catch {
                        // Invalid pairing file - delete it and notify user
                        print("Removing invalid pairing file from disk: \(error.localizedDescription)")
                        try? FileManager.default.removeItem(at: pairingPath)
                        
                        // Show alert to user
                        DispatchQueue.main.async {
                            self.lastError = L("error_pairing_invalid_disk")
                            self.showErrorAlert = true
                        }
                    }
                }
            }
        }
        
        autoLoadSideStorePairingIfNeeded()
        
        if pairingFile != nil {
            startHeartbeatOnce()
            // Start auto-reset timer if system not ready
            startPairingResetTimer()
        } else {
            heartbeatRunning = false
            MountingProgress.shared.coolisMounted = false
            cancelPairingResetTimer()
        }
    }

    private func handleScenePhase(_ newPhase: ScenePhase) {
        if newPhase == .inactive {
            Utils.bgTask = UIApplication.shared.beginBackgroundTask {
                UIApplication.shared.endBackgroundTask(Utils.bgTask)
                Utils.bgTask = .invalid
            }
        } else if newPhase == .active {
            if Utils.bgTask != .invalid {
                UIApplication.shared.endBackgroundTask(Utils.bgTask)
                Utils.bgTask = .invalid
            }
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let hasSecurityScope = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url, options: [.mappedIfSafe])
                guard !data.isEmpty else {
                    lastError = "Pairing file is empty."
                    showErrorAlert = true
                    return
                }

                // XML and binary property lists are both accepted. Normalize to XML before
                // persisting because the rest of the app stores the pairing record as text.
                let text: String
                do {
                    text = try PairingFileParser.normalizedPlistText(from: data)
                } catch {
                    lastError = "Invalid pairing file: \(error.localizedDescription)"
                    showErrorAlert = true
                    return
                }

                if pairingFile != nil {
                    // Confirm before replacing the currently active pairing record.
                    pendingPairingFileText = text
                    showPairingReplaceConfirm = true
                } else {
                    importPairingFile(text)
                }
            } catch {
                lastError = "Failed to read the pairing file: \(error.localizedDescription)"
                showErrorAlert = true
            }
        case .failure(let error):
            lastError = error.localizedDescription
            showErrorAlert = true
        }
    }

    /// Import and activate a pairing file
    private func importPairingFile(_ text: String) {
        pairingFile = text
        savePairingFileToDocuments(text)
        startHeartbeatOnce()
    }

    private func autoLoadSideStorePairingIfNeeded() {
        guard pairingFile == nil else { return }
        if let altPairingFile = Bundle.main.object(forInfoDictionaryKey: "ALTPairingFile") as? String,
           altPairingFile.count > 5000 {
            // Validate before using
            do {
                let _ = try PairingFileParser.parseUDID(fromPlistText: altPairingFile)
                // Valid - use it
                pairingFile = altPairingFile
                savePairingFileToDocuments(altPairingFile)
            } catch {
                // Invalid pairing file from SideStore
                print("SideStore pairing file is invalid: \(error.localizedDescription)")
                // Don't show alert here as it might be too noisy
            }
        }
    }

    private func savePairingFileToDocuments(_ text: String) {
        // Fix #4 & #5: Add error handling for file writing
        do {
            try text.write(
                to: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"),
                atomically: true,
                encoding: .utf8
            )
        } catch {
            // Silently handle - not critical
            print("Warning: Failed to save pairing file: \(error)")
        }
    }

    private func resetPairing() {
        pairingFile = nil
        // Fix #4 & #5: Add error handling for file deletion
        do {
            let pairingPath = URL.documentsDirectory.appendingPathComponent("pairingFile.plist")
            if FileManager.default.fileExists(atPath: pairingPath.path) {
                try FileManager.default.removeItem(at: pairingPath)
            }
        } catch {
            print("Warning: Failed to delete pairing file: \(error)")
        }
        heartbeatRunning = false
        MountingProgress.shared.coolisMounted = false
    }
    
    /// Start timer to auto-reset pairing file if system not ready after 3 seconds
    private func startPairingResetTimer() {
        // Cancel any existing timer
        cancelPairingResetTimer()
        
        // Only start timer if:
        // 1. Pairing file exists
        // 2. System is not ready
        // 3. Haven't already attempted reset for this pairing file
        guard pairingFile != nil && !heartbeatRunning && !pairingResetAttempted else {
            return
        }
        
        print("[Auto-Reset] Starting 3-second timer for pairing validation")
        
        let workItem = DispatchWorkItem {
            // Double-check conditions before resetting
            if self.pairingFile != nil && !self.heartbeatRunning {
                print("[Auto-Reset] System not ready after 3 seconds, resetting pairing file")
                
                DispatchQueue.main.async {
                    self.pairingResetAttempted = true
                    self.resetPairing()
                    
                    // Show error alert
                    self.lastError = "Pairing file is invalid or LocalDev VPN is not enabled. Please check:\n- SideStore LocalDevVPN or StikDebug is running\n- VPN connection is active\n- Pairing file is valid\nThen import a new pairing file."
                    self.showErrorAlert = true
                }
            }
        }
        
        pairingResetTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0, execute: workItem)
    }
    
    /// Cancel the auto-reset timer
    private func cancelPairingResetTimer() {
        pairingResetTimer?.cancel()
        pairingResetTimer = nil
    }

    /// Heartbeat start, same flow as StikDebug's startHeartbeatInBackground():
    /// start heartbeat on a background queue, then auto-mount the personalized DDI if downloaded.
    private func startHeartbeatOnce() {
        guard pairingFile != nil else { return }
        guard !heartbeatStartInProgress else { return }
        heartbeatStartInProgress = true

        DispatchQueue.global(qos: .userInteractive).async {
            defer {
                DispatchQueue.main.async {
                    self.heartbeatStartInProgress = false
                }
            }
            do {
                try JITEnableContext.shared.startHeartbeat()
                print("[Heartbeat] Heartbeat started successfully")

                DispatchQueue.main.async {
                    self.heartbeatRunning = true
                    let trustcachePath = URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg.trustcache").path
                    guard FileManager.default.fileExists(atPath: trustcachePath),
                          !MountingProgress.shared.coolisMounted,
                          MountingProgress.shared.mountingThread == nil else {
                        MountingProgress.shared.checkforMounted()
                        return
                    }
                    MountingProgress.shared.pubMount()
                }
            } catch {
                let code = (error as NSError).code
                print("[Heartbeat] \(error.localizedDescription) (Code: \(code))")
                DispatchQueue.main.async {
                    self.heartbeatRunning = false
                    MountingProgress.shared.coolisMounted = false
                    if code == -9 {
                        self.resetPairing()
                        self.lastError = "The pairing file is invalid or expired. Please select a new pairing file."
                    } else {
                        self.lastError = "\(error.localizedDescription)\n\nMake sure Wi‑Fi and LocalDevVPN are connected and that the device is reachable."
                    }
                    self.showErrorAlert = true
                }
            }
        }
    }

    /// Refresh system status (VPN, DDI, heartbeat)
    private func refreshSystemStatus() {
        if pairingFile != nil && heartbeatRunning {
            MountingProgress.shared.checkforMounted()
        }
        // Heartbeat status is updated automatically by startHeartbeatOnce
    }
    
    /// Start network monitoring for VPN auto-refresh
    private func startNetworkMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { path in
            // Check if network status changed
            DispatchQueue.main.async {
                // When network changes (VPN connects/disconnects), refresh system status
                if path.status == .satisfied {
                    // Network is available, check if we need to restart heartbeat
                    if self.pairingFile != nil && !self.heartbeatRunning {
                        self.startHeartbeatOnce()
                    }
                    self.refreshSystemStatus()
                }
            }
        }
        
        monitor.start(queue: queue)
        networkMonitor = monitor
    }
    
    /// Stop network monitoring
    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    private func respringNow() throws {
        try RespringHelper.respring()
    }

    private func getRunningProcesses() throws -> [Int32 : String?] {
        try RespringHelper.getRunningProcesses()
    }

    private struct RemoteVersion: Decodable {
        let version: String
        let build: Int
        let url: String
        let notes: String?
    }

    private func checkForUpdate() {
        let buildNow = currentBuildInt
        if lastCheckedBuild == buildNow { return }
        lastCheckedBuild = buildNow
        let request = URLRequest(url: versionJSONURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data else { return }
            guard let remote = try? JSONDecoder().decode(RemoteVersion.self, from: data) else { return }
            guard let url = URL(string: remote.url) else { return }
            if remote.build == ignoredUpdateBuild { return }
            if remote.build > buildNow {
                DispatchQueue.main.async {
                    pendingRemoteBuild = remote.build
                    updateURL = url
                    if let notes = remote.notes, !notes.isEmpty {
                        updateMessage = "New version \(remote.version) (\(remote.build)) is available.\n\n\(notes)"
                    } else {
                        updateMessage = "New version \(remote.version) (\(remote.build)) is available."
                    }
                    showUpdateAlert = true
                }
            }
        }.resume()
    }
}

// MARK: - Status Sheet (Feather-style)
struct StatusSheet: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var pairingFileLoaded: Bool
    @Binding var heartbeatRunning: Bool
    @Binding var ddiMounted: Bool
    var onImportPairing: () -> Void
    var onResetPairing: () -> Void
    var onMountDDI: () -> Void
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            GlassForm {
                GlassSection(header: Text(L("system_status"))) {
                    CardRow(title: L("status_pairing_file"), subtitle: pairingFileLoaded ? L("status_pairing_loaded") : L("status_pairing_missing"), ok: pairingFileLoaded, showChevron: false, trailing: nil)

                    CardRow(title: L("status_heartbeat"), subtitle: heartbeatRunning ? L("status_heartbeat_running") : L("status_heartbeat_stopped"), ok: heartbeatRunning, showChevron: false, trailing: nil)

                    CardRow(title: L("status_ddi"), subtitle: ddiMounted ? L("status_ddi_mounted") : L("status_ddi_unmounted"), ok: ddiMounted, showChevron: false, trailing: nil)
                }

                GlassSection(header: Text(L("section_actions"))) {
                    if heartbeatRunning && !ddiMounted {
                        Button(L("button_mount_ddi")) {
                            onMountDDI()
                        }
                    }
                    
                    Button(pairingFileLoaded ? L("button_reset_pairing") : L("button_select_pairing")) {
                        if pairingFileLoaded { onResetPairing() } else { onImportPairing() }
                        onClose()
                    }
                    .tint(pairingFileLoaded ? .red : .accentColor)
                }
            }
            .liquidGlassScreenStyle()
            .headerProminence(.increased)
            .navigationTitle(L("system_status"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Apply Sheet (Feather-style)
struct ApplySheet: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var logs: [String]
    @Binding var isRunning: Bool
    @Binding var progressText: String
    @Binding var enableRespring: Bool
    @Binding var bookassetdUUID: String
    var onApply: () -> Void
    var onClearUUID: () -> Void
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            GlassForm {
                optionsSection
                statusSection
                if !logs.isEmpty {
                    logsSection
                }
                actionsSection
            }
            .liquidGlassScreenStyle()
            .headerProminence(.increased)
            .navigationTitle(L("apply_tweaks"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var optionsSection: some View {
        GlassSection {
            Toggle(L("respring_after_apply"), isOn: $enableRespring)
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        GlassSection(header: Text(L("section_status"))) {
            HStack(spacing: 12) {
                if isRunning {
                    ProgressView()
                }
                Text(progressText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var logsSection: some View {
        GlassSection(header: Text(L("logs"))) {
            ForEach(logs, id: \.self) { log in
                Text(log)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        GlassSection(header: Text(L("section_actions"))) {
            Button(L("clear_uuid"), role: .destructive) {
                onClearUUID()
            }
            .disabled(bookassetdUUID.isEmpty)
        }

        GlassSection {
            WalletStyleButton(
                title: isRunning ? L("applying") : L("apply_enabled_tweaks"),
                isLoading: isRunning,
                disabled: isRunning,
                action: onApply
            )
        }
    }
}
