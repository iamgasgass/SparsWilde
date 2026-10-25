import Foundation
import UIKit

enum MobileGestaltApplyTask {

    static let origMGFileName = "OriginalMobileGestalt.plist"
    static let modMGFileName  = "ModifiedMobileGestalt.plist"

    // MARK: - String Obfuscation Example
    // The onDeviceMGPath is obfuscated to prevent it from appearing in the binary's __cstring section.
    // This makes static analysis more difficult for reverse engineers.
    // Note: In production, you may want to obfuscate more paths or use XOR encoding for stronger protection.
    static var onDeviceMGPath: String {
        // Original: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
        // Using byte array to hide the string from static analysis
        return SecureString.reveal([
            0x2F, 0x76, 0x61, 0x72, 0x2F, 0x63, 0x6F, 0x6E, 0x74, 0x61, 0x69, 0x6E, 0x65, 0x72, 0x73, 0x2F,
            0x53, 0x68, 0x61, 0x72, 0x65, 0x64, 0x2F, 0x53, 0x79, 0x73, 0x74, 0x65, 0x6D, 0x47, 0x72, 0x6F,
            0x75, 0x70, 0x2F, 0x73, 0x79, 0x73, 0x74, 0x65, 0x6D, 0x67, 0x72, 0x6F, 0x75, 0x70, 0x2E, 0x63,
            0x6F, 0x6D, 0x2E, 0x61, 0x70, 0x70, 0x6C, 0x65, 0x2E, 0x6D, 0x6F, 0x62, 0x69, 0x6C, 0x65, 0x67,
            0x65, 0x73, 0x74, 0x61, 0x6C, 0x74, 0x63, 0x61, 0x63, 0x68, 0x65, 0x2F, 0x4C, 0x69, 0x62, 0x72,
            0x61, 0x72, 0x79, 0x2F, 0x43, 0x61, 0x63, 0x68, 0x65, 0x73, 0x2F, 0x63, 0x6F, 0x6D, 0x2E, 0x61,
            0x70, 0x70, 0x6C, 0x65, 0x2E, 0x4D, 0x6F, 0x62, 0x69, 0x6C, 0x65, 0x47, 0x65, 0x73, 0x74, 0x61,
            0x6C, 0x74, 0x2E, 0x70, 0x6C, 0x69, 0x73, 0x74
        ])
    }

    static var overwriteSuccessMessage: String {
        // Original: "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist) [Install-Mgr]: Marking download as [finished]"
        // Using byte array obfuscation
        return SecureString.reveal([
            0x2F, 0x70, 0x72, 0x69, 0x76, 0x61, 0x74, 0x65, 0x2F, 0x76, 0x61, 0x72, 0x2F, 0x63, 0x6F, 0x6E,
            0x74, 0x61, 0x69, 0x6E, 0x65, 0x72, 0x73, 0x2F, 0x53, 0x68, 0x61, 0x72, 0x65, 0x64, 0x2F, 0x53,
            0x79, 0x73, 0x74, 0x65, 0x6D, 0x47, 0x72, 0x6F, 0x75, 0x70, 0x2F, 0x73, 0x79, 0x73, 0x74, 0x65,
            0x6D, 0x67, 0x72, 0x6F, 0x75, 0x70, 0x2E, 0x63, 0x6F, 0x6D, 0x2E, 0x61, 0x70, 0x70, 0x6C, 0x65,
            0x2E, 0x6D, 0x6F, 0x62, 0x69, 0x6C, 0x65, 0x67, 0x65, 0x73, 0x74, 0x61, 0x6C, 0x74, 0x63, 0x61,
            0x63, 0x68, 0x65, 0x2F, 0x4C, 0x69, 0x62, 0x72, 0x61, 0x72, 0x79, 0x2F, 0x43, 0x61, 0x63, 0x68,
            0x65, 0x73, 0x2F, 0x63, 0x6F, 0x6D, 0x2E, 0x61, 0x70, 0x70, 0x6C, 0x65, 0x2E, 0x4D, 0x6F, 0x62,
            0x69, 0x6C, 0x65, 0x47, 0x65, 0x73, 0x74, 0x61, 0x6C, 0x74, 0x2E, 0x70, 0x6C, 0x69, 0x73, 0x74,
            0x29, 0x20, 0x5B, 0x49, 0x6E, 0x73, 0x74, 0x61, 0x6C, 0x6C, 0x2D, 0x4D, 0x67, 0x72, 0x5D, 0x3A,
            0x20, 0x4D, 0x61, 0x72, 0x6B, 0x69, 0x6E, 0x67, 0x20, 0x64, 0x6F, 0x77, 0x6E, 0x6C, 0x6F, 0x61,
            0x64, 0x20, 0x61, 0x73, 0x20, 0x5B, 0x66, 0x69, 0x6E, 0x69, 0x73, 0x68, 0x65, 0x64, 0x5D
        ])
    }

    static func run(store: ToolStore) async throws {
        guard let context = JITEnableContext.shared else {
            throw ToolTaskError.invalidContext
        }

        _ = try await Utils.ensureHTTPServerReady(timeoutSeconds: 5)

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let origMGURL = docs.appendingPathComponent(origMGFileName)
        let modMGURL  = docs.appendingPathComponent(modMGFileName)

        // Ensure original exists for UX consistency
        if !FileManager.default.fileExists(atPath: origMGURL.path) {
            let src = URL(filePath: onDeviceMGPath)
            try FileManager.default.copyItem(at: src, to: origMGURL)
            chmod(origMGURL.path, 0o644)
        }

        // IMPORTANT: user must have saved ModifiedMobileGestalt.plist from MobileGestaltView
        guard FileManager.default.fileExists(atPath: modMGURL.path) else {
            throw ToolTaskError.generic("Missing \(modMGFileName). Open MobileGestalt tool and press “Save to ModifiedMobileGestalt.plist” first.")
        }

        // Ensure bookassetd UUID
        let uuid: String
        if let v = store.bookassetdUUID, !v.isEmpty {
            uuid = v
        } else {
            let captured = try await BookassetdUUIDHelper.captureUUID(
                timeout: 120,
                openBooksFirst: true,
                returnToAppAfterCapture: true
            )
            store.bookassetdUUID = captured
            uuid = captured
        }

        // Copy DB files from bundle to Documents (same as SparseBox)
        let d28LocalPath = docs.appendingPathComponent("downloads.28.sqlitedb").path
        let bldLocalPath = docs.appendingPathComponent("BLDatabaseManager.sqlite").path
        let bundle = Bundle.main

        if !FileManager.default.fileExists(atPath: d28LocalPath),
           let resourcePath = bundle.path(forResource: "downloads.28", ofType: "sqlitedb") {
            try? FileManager.default.copyItem(atPath: resourcePath, toPath: d28LocalPath)
        }

        if !FileManager.default.fileExists(atPath: bldLocalPath),
           let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite") {
            try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath)
        }

        if !FileManager.default.fileExists(atPath: bldLocalPath + "-shm"),
           let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite-shm") {
            try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath + "-shm")
        }

        if !FileManager.default.fileExists(atPath: bldLocalPath + "-wal"),
           let resourcePath = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite-wal") {
            try? FileManager.default.copyItem(atPath: resourcePath, toPath: bldLocalPath + "-wal")
        }

        // Patch downloads.28 to point BLDatabaseManager URLs to localhost
        try Databases.patchDatabase(dbPath: d28LocalPath, uuid: uuid, ip: "localhost", port: Utils.port)

        // Stop bookassetd and kill Books
        var processes = try getRunningProcesses()
        if let pid_bookassetd = processes.first(where: { $0.value?.hasSuffix("/bookassetd") == true })?.key {
            try context.killProcess(withPID: pid_bookassetd, signal: SIGSTOP)
        }
        if let pid_books = processes.first(where: { $0.value?.hasSuffix("/Books") == true })?.key {
            try context.killProcess(withPID: pid_books, signal: SIGKILL)
        }

        // Upload ModifiedMobileGestalt.plist as com.apple.MobileGestalt.plist
        try context.afcPushFile(modMGURL.path, toPath: "com.apple.MobileGestalt.plist")

        // Upload downloads.28 trio
        try context.afcPushFile(d28LocalPath, toPath: "Downloads/downloads.28.sqlitedb")
        try context.afcPushFile(d28LocalPath + "-shm", toPath: "Downloads/downloads.28.sqlitedb-shm")
        try context.afcPushFile(d28LocalPath + "-wal", toPath: "Downloads/downloads.28.sqlitedb-wal")

        // Kill itunesstored
        processes = try getRunningProcesses()
        if let pid_itunesstored = processes.first(where: { $0.value?.hasSuffix("/itunesstored") == true })?.key {
            try context.killProcess(withPID: pid_itunesstored, signal: SIGKILL)
        }

        _ = try await waitForSyslogLine(
            matches: { $0.contains("Install complete for download:") && $0.contains("result: Failed") },
            timeout: 2
        )

        // Kill bookassetd + Books again
        processes = try getRunningProcesses()
        if let pid_bookassetd2 = processes.first(where: { $0.value?.hasSuffix("/bookassetd") == true })?.key {
            try context.killProcess(withPID: pid_bookassetd2, signal: SIGKILL)
        }
        if let pid_books2 = processes.first(where: { $0.value?.hasSuffix("/Books") == true })?.key {
            try context.killProcess(withPID: pid_books2, signal: SIGKILL)
        }

        LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.iBooks")
        LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: Bundle.main.bundleIdentifier!)

        _ = try await waitForSyslogLine(matches: { $0.contains(overwriteSuccessMessage) }, timeout: 3)
    }

    // MARK: - Helpers

    private static func getRunningProcesses() throws -> [Int32 : String?] {
        Dictionary(
            uniqueKeysWithValues: (try JITEnableContext.shared?.fetchProcessList() as! [[String: Any]])
                .compactMap { item in
                    guard let pid = item["pid"] as? Int32 else { return nil }
                    let path = item["path"] as? String
                    return (pid, path)
                }
        )
    }

    private static func waitForSyslogLine(matches predicate: @escaping (String) -> Bool, timeout: TimeInterval? = nil) async throws -> String {
        let result = try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            JITEnableContext.shared.startSyslogRelay { line in
                guard let line else { return }
                if predicate(line) {
                    resumed = true
                    continuation.resume(returning: line)
                }
            } onError: { error in
                resumed = true
                continuation.resume(throwing: error ?? ToolTaskError.generic("Syslog relay error"))
            }

            if let timeout {
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                    if resumed { return }
                    continuation.resume(returning: "Timed out waiting for syslog line.")
                }
            }
        }
        JITEnableContext.shared.stopSyslogRelay()
        return result
    }
}
