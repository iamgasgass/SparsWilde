//
//  mountDDI.swift
//  StikJIT
//
//  Created by Stossy11 on 29/03/2025.
//
//  SparsWilde: Developer Disk Image logic copied 1:1 from StikDebug
//  (last lockdown/TCP-provider version, StikJIT/Utilities/mountDDI.swift + StikJITApp.swift).
//  Only differences: the typealiases are omitted (types already come from idevice.h via the
//  bridging header) and LogManager calls are replaced with print().
//

import Foundation
import UIKit

func progressCallback(progress: size_t, total: size_t, context: UnsafeMutableRawPointer?) {
    MountingProgress.shared.progressCallback(progress: progress, total: total, context: context)
}

enum MountCheckResult {
    case mounted
    case notMounted
    case unreachable
}

func isMounted() -> Bool {
    return checkMountStatus() == .mounted
}

func checkMountStatus() -> MountCheckResult {
    do {
        let result = try JITEnableContext.shared.getMountedDeviceCount()
        return result > 0 ? .mounted : .notMounted
    } catch {
        return .unreachable
    }
}

func mountPersonalDDI(imagePath: String, trustcachePath: String, manifestPath: String) -> String? {
    do {
        try JITEnableContext.shared.mountPersonalDDI(withImagePath: imagePath, trustcachePath: trustcachePath, manifestPath: manifestPath)
    } catch {
        print("[DDI] Failed to mount DDI: \(error.localizedDescription)")
        return error.localizedDescription
    }
    return nil
}

// MARK: - MountingProgress (StikDebug)

class MountingProgress: ObservableObject {
    static var shared = MountingProgress()
    @Published var mountProgress: Double = 0.0
    @Published var mountingThread: Thread?
    @Published var coolisMounted: Bool = false

    func checkforMounted() {
        DispatchQueue.global(qos: .utility).async {
            let mounted = isMounted()
            DispatchQueue.main.async {
                self.coolisMounted = mounted
            }
        }
    }

    func progressCallback(progress: size_t, total: size_t, context: UnsafeMutableRawPointer?) {
        let percentage = Double(progress) / Double(total) * 100.0
        DispatchQueue.main.async {
            self.mountProgress = percentage
        }
    }

    func pubMount() {
        mount()
    }

    private func mount() {
        let currentlyMounted = isMounted()
        DispatchQueue.main.async {
            self.coolisMounted = currentlyMounted
        }

        if isPairing(), !currentlyMounted {
            if let mountingThread = mountingThread {
                mountingThread.cancel()
                self.mountingThread = nil
            }

            let thread = Thread { [weak self] in
                guard let self = self else { return }
                let mountError = mountPersonalDDI(
                    imagePath: URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg").path,
                    trustcachePath: URL.documentsDirectory.appendingPathComponent("DDI/Image.dmg.trustcache").path,
                    manifestPath: URL.documentsDirectory.appendingPathComponent("DDI/BuildManifest.plist").path
                )

                DispatchQueue.main.async {
                    if let mountError {
                        showAlert(title: "DDI Mount Failed", message: mountError, showOk: true, showTryAgain: true) { shouldTryAgain in
                            if shouldTryAgain { self.mount() }
                        }
                    } else {
                        self.coolisMounted = true
                        self.checkforMounted()
                    }
                    self.mountingThread = nil
                }
            }
            thread.qualityOfService = .background
            thread.name = "mounting"
            thread.start()
            mountingThread = thread
        }
    }
}

func isPairing() -> Bool {
    let pairingpath = URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path
    var pairingFile: OpaquePointer?
    let err = idevice_pairing_file_read(pairingpath, &pairingFile)
    if err != nil {
        idevice_error_free(err)
        return false
    }
    idevice_pairing_file_free(pairingFile)
    return true
}

public func showAlert(title: String, message: String, showOk: Bool, showTryAgain: Bool = false, primaryButtonText: String? = nil, completion: ((Bool) -> Void)? = nil) {
    DispatchQueue.main.async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if showTryAgain {
            alert.addAction(UIAlertAction(title: primaryButtonText ?? "Try Again", style: .default) { _ in
                completion?(true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion?(false)
            })
        } else if showOk {
            alert.addAction(UIAlertAction(title: primaryButtonText ?? "OK", style: .default) { _ in
                completion?(true)
            })
        } else {
             alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion?(true)
            })
        }

        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        topController.present(alert, animated: true)
    }
}

// MARK: - DDI download (StikDebug)

private struct DDIDownloadItem {
    let name: String
    let relativePath: String
    let urlString: String
}

private let ddiDownloadItems: [DDIDownloadItem] = [
    .init(
        name: "Build Manifest",
        relativePath: "DDI/BuildManifest.plist",
        urlString: "https://github.com/doronz88/DeveloperDiskImage/raw/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/BuildManifest.plist"
    ),
    .init(
        name: "Image",
        relativePath: "DDI/Image.dmg",
        urlString: "https://github.com/doronz88/DeveloperDiskImage/raw/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/Image.dmg"
    ),
    .init(
        name: "TrustCache",
        relativePath: "DDI/Image.dmg.trustcache",
        urlString: "https://github.com/doronz88/DeveloperDiskImage/raw/refs/heads/main/PersonalizedImages/Xcode_iOS_DDI_Personalized/Image.dmg.trustcache"
    )
]

/// SparsWilde helper: true when all three DDI files are present in Documents/DDI.
func ddiFilesAreDownloaded() -> Bool {
    ddiDownloadItems.allSatisfy {
        FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent($0.relativePath).path)
    }
}

enum DDIDownloadError: LocalizedError {
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let string):
            return "Invalid download URL: \(string)"
        }
    }
}

func downloadFile(from urlString: String, to destinationURL: URL) async throws {
    guard let url = URL(string: urlString) else {
        throw DDIDownloadError.invalidURL(urlString)
    }
    let (tempLocalUrl, _) = try await URLSession.shared.download(from: url)
    let fileManager = FileManager.default
    try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(),
                                    withIntermediateDirectories: true)
    if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
    }
    try fileManager.moveItem(at: tempLocalUrl, to: destinationURL)
}

func redownloadDDI(progressHandler: ((Double, String) -> Void)? = nil) async throws {
    let fileManager = FileManager.default
    let totalStages = Double(ddiDownloadItems.count + 1)
    var completedStages = 0.0

    progressHandler?(0.0, "Removing existing DDI files…")
    for item in ddiDownloadItems {
        let fileURL = URL.documentsDirectory.appendingPathComponent(item.relativePath)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    completedStages += 1.0
    progressHandler?(completedStages / totalStages, "Starting downloads…")

    for item in ddiDownloadItems {
        progressHandler?(completedStages / totalStages, "Downloading \(item.name)…")
        let destinationURL = URL.documentsDirectory.appendingPathComponent(item.relativePath)
        try await downloadFile(from: item.urlString, to: destinationURL)
        completedStages += 1.0
        progressHandler?(completedStages / totalStages, "\(item.name) ready")
    }
    progressHandler?(1.0, "DDI download complete.")
}
