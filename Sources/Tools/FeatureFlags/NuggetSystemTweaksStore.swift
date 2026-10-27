import Foundation
import SwiftUI

/// System-plist tweaks adapted from Nugget's public tweak catalog.
/// Each preset is opt-in. Risky presets are deliberately disabled by default.
enum NuggetSystemTweakCategory: String, CaseIterable, Identifiable {
    case springboard
    case internalPreferences
    case liquidGlass
    case risky
    case daemons

    var id: String { rawValue }

    var title: String {
        switch self {
        case .springboard: return "SpringBoard options"
        case .internalPreferences: return "Internal options"
        case .liquidGlass: return "Liquid Glass / Solarium"
        case .risky: return "Risky / experimental"
        case .daemons: return "Daemon options"
        }
    }
}

struct NuggetSystemTweakDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: NuggetSystemTweakCategory
    let targetPath: String
    let values: [String: Any]
    let nullifyFile: Bool
    let warning: String?

    init(
        id: String,
        title: String,
        description: String,
        category: NuggetSystemTweakCategory,
        targetPath: String,
        values: [String: Any],
        nullifyFile: Bool = false,
        warning: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.targetPath = targetPath
        self.values = values
        self.nullifyFile = nullifyFile
        self.warning = warning
    }
}

@MainActor
final class NuggetSystemTweaksStore: ObservableObject {
    private static let persistenceKey = "NuggetStyleSystemTweaksEnabledIDs"

    @Published private(set) var enabledIDs: Set<String> = []

    init() {
        load()
    }

    static let allDefinitions: [NuggetSystemTweakDefinition] = {
        let springBoard = "/var/Managed Preferences/mobile/com.apple.springboard.plist"
        let globalPreferences = "/var/Managed Preferences/mobile/.GlobalPreferences.plist"
        let internalOptions: [NuggetSystemTweakDefinition] = [
            .init(id: "show_build_number", title: "Show OS build number", description: "Adds the build number to the status bar.", category: .internalPreferences, targetPath: globalPreferences, values: ["UIStatusBarShowBuildVersion": true]),
            .init(id: "force_rtl", title: "Force right-to-left layout", description: "For testing RTL language layouts. Mutually exclusive with left-to-right.", category: .internalPreferences, targetPath: globalPreferences, values: ["NSForceRightToLeftWritingDirection": true]),
            .init(id: "force_ltr", title: "Force left-to-right layout", description: "For testing LTR language layouts. Mutually exclusive with right-to-left.", category: .internalPreferences, targetPath: globalPreferences, values: ["NSForceLeftToRightWritingDirection": true]),
            .init(id: "icon_visibility", title: "Internal icon visibility preference", description: "Writes SpringBoard's internal icon-visibility preference.", category: .internalPreferences, targetPath: globalPreferences, values: ["SBIconVisibility": true]),
            .init(id: "metal_hud", title: "Metal performance HUD", description: "Enables an internal Metal HUD preference.", category: .internalPreferences, targetPath: globalPreferences, values: ["MetalForceHudEnabled": true]),
            .init(id: "imessage_diagnostics", title: "Messages diagnostics", description: "Enables internal Messages diagnostic logging.", category: .internalPreferences, targetPath: globalPreferences, values: ["iMessageDiagnosticsEnabled": true]),
            .init(id: "ids_diagnostics", title: "IDS diagnostics", description: "Enables internal Identity Services diagnostics.", category: .internalPreferences, targetPath: globalPreferences, values: ["IDSDiagnosticsEnabled": true]),
            .init(id: "vc_diagnostics", title: "Video calling diagnostics", description: "Enables internal VideoCalling diagnostics.", category: .internalPreferences, targetPath: globalPreferences, values: ["VCDiagnosticsEnabled": true]),
            .init(id: "accessory_developer", title: "Accessory developer mode", description: "Enables an internal accessory developer preference.", category: .internalPreferences, targetPath: globalPreferences, values: ["AccessoryDeveloperEnabled": true]),
            .init(id: "key_flick", title: "Keyboard key-flick gestures", description: "Enables the internal GesturesEnabled preference.", category: .internalPreferences, targetPath: globalPreferences, values: ["GesturesEnabled": true]),
            .init(id: "disable_seconds_hand", title: "Disable Clock icon seconds hand", description: "Disables the animated seconds hand where supported.", category: .internalPreferences, targetPath: globalPreferences, values: ["SBDisableClockIconSecondsHand": true]),
            .init(id: "disable_web_search", title: "Disable Spotlight website search", description: "Writes the internal SBSearchDisabledDomains preference.", category: .internalPreferences, targetPath: globalPreferences, values: ["SBSearchDisabledDomains": true]),
            .init(id: "button_hints", title: "Always show hardware-button hints", description: "Keeps system button hint droplets visible in snapshots.", category: .internalPreferences, targetPath: globalPreferences, values: ["SBHardwareButtonHintDropletsAlwaysVisibleInSnapshots": true]),
            .init(id: "app_store_debug", title: "App Store debug gestures", description: "Enables an internal App Store debugging gesture.", category: .internalPreferences, targetPath: "/var/Managed Preferences/mobile/com.apple.AppStore.plist", values: ["debugGestureEnabled": true]),
            .init(id: "notes_debug", title: "Notes debug mode", description: "Enables internal Notes debugging options.", category: .internalPreferences, targetPath: "/var/Managed Preferences/mobile/com.apple.mobilenotes.plist", values: ["DebugModeEnabled": true]),
            .init(id: "visualize_touches", title: "Visualize touch input", description: "Enables BackBoard digitizer touch visualization.", category: .internalPreferences, targetPath: "/var/Managed Preferences/mobile/com.apple.backboardd.plist", values: ["BKDigitizerVisualizeTouches": true]),
            .init(id: "hide_launch_apple_logo", title: "Hide Apple logo during launch", description: "Sets BackBoard's internal launch-logo preference.", category: .internalPreferences, targetPath: "/var/Managed Preferences/mobile/com.apple.backboardd.plist", values: ["BKHideAppleLogoOnLaunch": true]),
            .init(id: "wake_haptic", title: "Wake gesture haptic", description: "Enables the CoreMotion wake-gesture haptic preference.", category: .internalPreferences, targetPath: "/var/Managed Preferences/mobile/com.apple.CoreMotion.plist", values: ["EnableWakeGestureHaptic": true]),
            .init(id: "play_sound_on_paste", title: "Play sound on paste", description: "Enables the Pasteboard sound preference.", category: .internalPreferences, targetPath: "/var/Managed Preferences/mobile/com.apple.Pasteboard.plist", values: ["PlaySoundOnPaste": true]),
            .init(id: "announce_all_pastes", title: "Announce all pastes", description: "Enables the Pasteboard announce-paste preference.", category: .internalPreferences, targetPath: "/var/Managed Preferences/mobile/com.apple.Pasteboard.plist", values: ["AnnounceAllPastes": true])
        ]

        let springBoardOptions: [NuggetSystemTweakDefinition] = [
            .init(id: "lockscreen_footnote", title: "Remove Lock Screen footnote", description: "Writes an empty LockScreenFootnote value.", category: .springboard, targetPath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/SharedDeviceConfiguration.plist", values: ["LockScreenFootnote": ""]),
            .init(id: "watchos_compatibility", title: "Relax Watch pairing compatibility", description: "Adjusts internal NanoRegistry compatibility fields.", category: .springboard, targetPath: "/var/mobile/Library/Preferences/com.apple.NanoRegistry.plist", values: [
                "IOS_PAIRING_EOL_MIN_PAIRING_COMPATIBILITY_VERSION_CHIPIDS": "",
                "maxPairingCompatibilityVersion": 37,
                "lastRestoreIdentifier": "CD97EEB8-BCD2-486B-BC13-C384E6B916C4",
                "minPairingCompatibilityVersionWithChipID": 1,
                "lastRestoreIdentifier_state": 0,
                "AdvertisingIdentifierSeed": "85E70251-1960-4DA0-A321-B68AC118FAB5",
                "minPairingCompatibilityVersion": 1
            ], warning: "Experimental. This does not guarantee compatibility with a watchOS release and may affect Watch pairing."),
            .init(id: "airdrop_no_limit", title: "Remove AirDrop Everyone time limit", description: "Keeps the Everyone sharing mode from expiring automatically.", category: .springboard, targetPath: "/var/Managed Preferences/mobile/com.apple.sharingd.plist", values: ["OverrideTimeLimitEveryoneMode": true]),
            .init(id: "dont_lock_after_crash", title: "Do not lock after SpringBoard crash", description: "Changes an internal SpringBoard recovery preference.", category: .springboard, targetPath: springBoard, values: ["SBDontLockAfterCrash": true]),
            .init(id: "dont_dim_lock_on_ac", title: "Do not dim or lock while on power", description: "Changes an internal SpringBoard power-state preference.", category: .springboard, targetPath: springBoard, values: ["SBDontDimOrLockOnAC": true]),
            .init(id: "hide_low_power_alerts", title: "Hide Low Power Mode alerts", description: "Suppresses SpringBoard low-power alerts where supported.", category: .springboard, targetPath: springBoard, values: ["SBHideLowPowerAlerts": true]),
            .init(id: "hide_ac_power", title: "Hide connected-to-power UI", description: "Hides internal SpringBoard AC-power indications where supported.", category: .springboard, targetPath: springBoard, values: ["SBHideACPower": true]),
            .init(id: "never_breadcrumb", title: "Hide app-return breadcrumbs", description: "Changes SpringBoard's internal breadcrumb preference.", category: .springboard, targetPath: springBoard, values: ["SBNeverBreadcrumb": true]),
            .init(id: "show_supervision_text", title: "Show supervision text on Lock Screen", description: "Enables the supervised-device text preference.", category: .springboard, targetPath: springBoard, values: ["SBShowSupervisionTextOnLockScreen": true]),
            .init(id: "airplay_extended_display", title: "Enable AirPlay display override support", description: "Enables internal AirPlay extended-display support.", category: .springboard, targetPath: springBoard, values: ["SBExtendedDisplayOverrideSupportForAirPlayAndDontFileRadars": true]),
            .init(id: "min_lockscreen_idle", title: "Short Lock Screen idle timeout", description: "Sets the internal minimum Lock Screen idle time to 5.", category: .springboard, targetPath: springBoard, values: ["SBMinimumLockscreenIdleTime": 5]),
            .init(id: "always_aperture_snapshots", title: "Keep System Aperture in snapshots", description: "Enables System Aperture rendering in snapshots.", category: .springboard, targetPath: springBoard, values: ["SBAlwaysShowSystemApertureInSnapshots": true]),
            .init(id: "hide_dynamic_island", title: "Suppress Dynamic Island completely", description: "Suppresses the Dynamic Island through a SpringBoard preference.", category: .springboard, targetPath: springBoard, values: ["SBSuppressDynamicIslandCompletely": true]),
            .init(id: "auth_engineering_ui", title: "Show authentication engineering UI", description: "Enables an internal authentication engineering interface.", category: .springboard, targetPath: springBoard, values: ["SBShowAuthenticationEngineeringUI": true]),
            .init(id: "disable_floating_tabbar", title: "Disable floating tab bar", description: "Disables the UIKit floating tab-bar preference.", category: .springboard, targetPath: "/var/Managed Preferences/mobile/com.apple.UIKit.plist", values: ["UseFloatingTabBar": false])
        ]

        // Liquid Glass / Solarium global preference overrides from Nugget's public catalog.
        // These options change or disable parts of the system Liquid Glass experience; they are off by default.
        let liquidGlassOptions: [NuggetSystemTweakDefinition] = [
            .init(id: "solarium_force_fallback", title: "Force Liquid Glass fallback", description: "Forces the legacy rendering fallback for Solarium where supported.", category: .liquidGlass, targetPath: globalPreferences, values: ["SolariumForceFallback": true], warning: "Experimental visual override. May be ignored or cause inconsistent appearance on some iOS versions."),
            .init(id: "solarium_disable_swiftui", title: "Disable Solarium in SwiftUI", description: "Requests that SwiftUI use the non-Solarium rendering path.", category: .liquidGlass, targetPath: globalPreferences, values: ["com.apple.SwiftUI.DisableSolarium": true], warning: "This disables parts of the native Liquid Glass experience rather than enabling them."),
            .init(id: "solarium_ignore_linked_check", title: "Ignore Solarium linked-on check", description: "Overrides SwiftUI's internal Solarium linked-on check.", category: .liquidGlass, targetPath: globalPreferences, values: ["com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck": true], warning: "Internal diagnostic preference; behavior varies by OS build."),
            .init(id: "solarium_no_glass_clock", title: "Disable Liquid Glass clock", description: "Requests the legacy clock appearance instead of the glass time style.", category: .liquidGlass, targetPath: globalPreferences, values: ["SBDisallowGlassTime": true]),
            .init(id: "solarium_no_glass_dock", title: "Disable Liquid Glass Dock", description: "Requests the legacy Dock appearance instead of the glass Dock.", category: .liquidGlass, targetPath: globalPreferences, values: ["SBDisableGlassDock": true]),
            .init(id: "solarium_disable_specular_motion", title: "Disable specular motion", description: "Disables the internal system-wide specular highlight motion effect.", category: .liquidGlass, targetPath: globalPreferences, values: ["SBDisableSpecularEverywhereUsingLSSAssertion": true]),
            .init(id: "solarium_disable_outer_refraction", title: "Disable outer refraction", description: "Disables the outer refraction effect where supported.", category: .liquidGlass, targetPath: globalPreferences, values: ["SolariumDisableOuterRefraction": true]),
            .init(id: "solarium_disable_hdr", title: "Disable Liquid Glass HDR", description: "Sets SolariumAllowHDR to false.", category: .liquidGlass, targetPath: globalPreferences, values: ["SolariumAllowHDR": false])
        ]

        let risky: [NuggetSystemTweakDefinition] = [
            .init(id: "disable_ota", title: "Block software update checks (OTA)", description: "Redirects update asset settings to the legacy tvOS seed catalog.", category: .risky, targetPath: "/var/Managed Preferences/mobile/com.apple.MobileAsset.plist", values: [
                "MobileAssetServerURL-com.apple.MobileAsset.MobileSoftwareUpdate.UpdateBrain": "https://mesu.apple.com/assets/tvOS16DeveloperSeed",
                "MobileAssetSUAllowOSVersionChange": false,
                "MobileAssetSUAllowSameVersionFullReplacement": false,
                "MobileAssetServerURL-com.apple.MobileAsset.RecoveryOSUpdate": "https://mesu.apple.com/assets/tvOS16DeveloperSeed",
                "MobileAssetServerURL-com.apple.MobileAsset.RecoveryOSUpdateBrain": "https://mesu.apple.com/assets/tvOS16DeveloperSeed",
                "MobileAssetServerURL-com.apple.MobileAsset.SoftwareUpdate": "https://mesu.apple.com/assets/tvOS16DeveloperSeed",
                "MobileAssetAssetAudience": "65254ac3-f331-4c19-8559-cbe22f5bc1a6"
            ], warning: "Risky and potentially obsolete. May interfere with normal iOS updates. Enable only if you understand how to restore the original preferences."),
            .init(id: "clear_screentime_agent", title: "Clear Screen Time agent plist", description: "Writes an empty ScreenTimeAgent preference file.", category: .risky, targetPath: "/var/mobile/Library/Preferences/ScreenTimeAgent.plist", values: [:], nullifyFile: true, warning: "Destructive: this replaces the target plist with an empty file. Back up the device first.")
        ]

        // The disabled-daemon database is a system-owned aggregate plist. SparseRestore's
        // current writer cannot merge with its live contents, so do not expose a preset
        // that would replace unrelated daemon settings.
        let daemonPreset: [NuggetSystemTweakDefinition] = []

        return springBoardOptions + internalOptions + liquidGlassOptions + risky + daemonPreset
    }()

    static func definitions(for category: NuggetSystemTweakCategory) -> [NuggetSystemTweakDefinition] {
        allDefinitions.filter { $0.category == category }
    }

    var selectedCount: Int { enabledIDs.intersection(Set(Self.allDefinitions.map(\.id))).count }

    func isEnabled(_ id: String) -> Bool { enabledIDs.contains(id) }

    func setEnabled(_ enabled: Bool, for id: String) {
        if enabled {
            enabledIDs.insert(id)
            // Direction flags cannot be active at the same time.
            if id == "force_rtl" { enabledIDs.remove("force_ltr") }
            if id == "force_ltr" { enabledIDs.remove("force_rtl") }
            if id == "solarium_force_fallback" { enabledIDs.remove("solarium_disable_swiftui") }
            if id == "solarium_disable_swiftui" { enabledIDs.remove("solarium_force_fallback") }
        } else {
            enabledIDs.remove(id)
        }
        persist()
    }

    func resetAll() {
        enabledIDs.removeAll()
        persist()
    }

    private func load() {
        let encoded = UserDefaults.standard.string(forKey: Self.persistenceKey) ?? "[]"
        if let data = encoded.data(using: .utf8),
           let values = try? JSONDecoder().decode([String].self, from: data) {
            enabledIDs = Set(values)
        }
    }

    private func persist() {
        let data = (try? JSONEncoder().encode(enabledIDs.sorted())) ?? Data("[]".utf8)
        UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "[]", forKey: Self.persistenceKey)
    }

    static var hasSelectedTweaks: Bool {
        let encoded = UserDefaults.standard.string(forKey: persistenceKey) ?? "[]"
        guard let data = encoded.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: data) else { return false }
        let knownIDs = Set(allDefinitions.map(\.id))
        return !Set(values).intersection(knownIDs).isEmpty
    }

    static func makeBookRestoreFiles() throws -> [BookRestoreFile] {
        let encoded = UserDefaults.standard.string(forKey: persistenceKey) ?? "[]"
        let data = encoded.data(using: .utf8) ?? Data("[]".utf8)
        let selected = Set((try? JSONDecoder().decode([String].self, from: data)) ?? [])
        let definitions = allDefinitions.filter { selected.contains($0.id) }
        guard !definitions.isEmpty else { return [] }

        var grouped: [String: [String: Any]] = [:]
        var nullifiedPaths = Set<String>()
        for definition in definitions {
            if definition.nullifyFile {
                nullifiedPaths.insert(definition.targetPath)
                continue
            }
            var payload = grouped[definition.targetPath] ?? [:]
            for (key, value) in definition.values {
                payload[key] = value
            }
            grouped[definition.targetPath] = payload
        }

        var files: [BookRestoreFile] = []
        for path in nullifiedPaths.sorted() {
            guard grouped[path] == nil else {
                throw ToolTaskError.generic("Conflicting system tweaks target the same plist with both values and a clear-file action: \(path)")
            }
            files.append(.custom(targetPath: path, contents: Data()))
        }
        for path in grouped.keys.sorted() {
            guard let payload = grouped[path] else { continue }
            guard PropertyListSerialization.propertyList(payload, isValidFor: .xml) else {
                throw ToolTaskError.generic("Invalid plist payload for system tweak target: \(path)")
            }
            let data = try PropertyListSerialization.data(fromPropertyList: payload, format: .xml, options: 0)
            files.append(.custom(targetPath: path, contents: data))
        }
        return files
    }
}
