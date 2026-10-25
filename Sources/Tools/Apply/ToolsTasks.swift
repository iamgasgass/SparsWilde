import Foundation
import SwiftUI

enum ToolTaskError: LocalizedError {
    case invalidContext
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .invalidContext: return "JITEnableContext not available."
        case .generic(let s): return s
        }
    }
}

enum DisableSoundTask {

    static func run(store: ToolStore) async throws {
        // Ensure HTTP server
        _ = try await Utils.ensureHTTPServerReady(timeoutSeconds: 5)

        // Auto-capture UUID if missing
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

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let d28LocalPath = documentsDirectory.appendingPathComponent("downloads.28.sqlitedb").path
        let bldLocalPath = documentsDirectory.appendingPathComponent("BLDatabaseManager.sqlite").path

        try resetAndSeedLocalDBCopies(d28LocalPath: d28LocalPath, bldLocalPath: bldLocalPath)

        // Verify server can serve BL DB trio (itunesstored will fetch them)
        try await Utils.verifyLocalHTTPFileAccessible(pathComponent: "BLDatabaseManager.sqlite")
        try await Utils.verifyLocalHTTPFileAccessible(pathComponent: "BLDatabaseManager.sqlite-shm")
        try await Utils.verifyLocalHTTPFileAccessible(pathComponent: "BLDatabaseManager.sqlite-wal")

        try Databases.patchDownloads28Database(
            dbPath: d28LocalPath,
            uuid: uuid,
            ip: "localhost",
            port: Utils.port,
            blFileNameOnServer: "BLDatabaseManager.sqlite"
        )

        try await runOneSoundTask(
            store: store,
            fileName: "StartDisclosureWithTone.m4a",
            targetPath: "/var/mobile/Library/CallServices/Greetings/default/StartDisclosureWithTone.m4a",
            d28LocalPath: d28LocalPath,
            bldLocalPath: bldLocalPath
        )

        if store.soundDelayAfterStart > 0 {
            try await Task.sleep(nanoseconds: UInt64(store.soundDelayAfterStart * 1_000_000_000))
        }

        try await runOneSoundTask(
            store: store,
            fileName: "StopDisclosure.caf",
            targetPath: "/var/mobile/Library/CallServices/Greetings/default/StopDisclosure.caf",
            d28LocalPath: d28LocalPath,
            bldLocalPath: bldLocalPath
        )

        if store.soundDelayAfterStop > 0 {
            try await Task.sleep(nanoseconds: UInt64(store.soundDelayAfterStop * 1_000_000_000))
        }

        // NOTE: Respring global nên chạy ở nơi khác (ContentView/ToolRunner).
        // Nếu bạn vẫn muốn respring ở đây thì giữ code cũ của bạn.
    }

    private static func runOneSoundTask(
        store: ToolStore,
        fileName: String,
        targetPath: String,
        d28LocalPath: String,
        bldLocalPath: String
    ) async throws {

        guard let context = JITEnableContext.shared else {
            throw ToolTaskError.invalidContext
        }

        try ensureBundledFileCopiedToDocuments(fileName: fileName)

        let nonce = Int(Date().timeIntervalSince1970 * 1000)
        let downloadID = "\(targetPath)|\(nonce)"
        let audioURL = "http://localhost:\(Utils.port)/\(fileName)?t=\(nonce)"

        // Verify audio file accessible
        try await Utils.verifyLocalHTTPFileAccessible(pathComponent: fileName)

        try Databases.patchBLDatabaseManager(
            dbPath: bldLocalPath,
            targetDisclosurePath: targetPath,
            assetURL: audioURL,
            downloadID: downloadID
        )

        var processes = try getRunningProcesses()

        if let pid_bookassetd = processes.first(where: { $0.value?.hasSuffix("/bookassetd") == true })?.key {
            try context.killProcess(withPID: pid_bookassetd, signal: SIGKILL)
        }
        if let pid_books = processes.first(where: { $0.value?.hasSuffix("/Books") == true })?.key {
            try context.killProcess(withPID: pid_books, signal: SIGKILL)
        }

        try context.afcPushFile(d28LocalPath, toPath: "Downloads/downloads.28.sqlitedb")
        try context.afcPushFile(d28LocalPath + "-shm", toPath: "Downloads/downloads.28.sqlitedb-shm")
        try context.afcPushFile(d28LocalPath + "-wal", toPath: "Downloads/downloads.28.sqlitedb-wal")

        processes = try getRunningProcesses()
        if let pid_itunesstored = processes.first(where: { $0.value?.hasSuffix("/itunesstored") == true })?.key {
            try context.killProcess(withPID: pid_itunesstored, signal: SIGKILL)
        }

        try await Task.sleep(nanoseconds: 3_000_000_000)

        processes = try getRunningProcesses()
        if let pid_bookassetd2 = processes.first(where: { $0.value?.hasSuffix("/bookassetd") == true })?.key {
            try context.killProcess(withPID: pid_bookassetd2, signal: SIGKILL)
        }
        if let pid_books2 = processes.first(where: { $0.value?.hasSuffix("/Books") == true })?.key {
            try context.killProcess(withPID: pid_books2, signal: SIGKILL)
        }

        LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.iBooks")
    }

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

    private static func resetAndSeedLocalDBCopies(d28LocalPath: String, bldLocalPath: String) throws {
        let fm = FileManager.default
        let bundle = Bundle.main

        // downloads.28
        try? fm.removeItem(atPath: d28LocalPath)
        try? fm.removeItem(atPath: d28LocalPath + "-wal")
        try? fm.removeItem(atPath: d28LocalPath + "-shm")

        guard let d28Resource = bundle.path(forResource: "downloads.28", ofType: "sqlitedb") else {
            throw ToolTaskError.generic("Missing downloads.28.sqlitedb in bundle")
        }
        try fm.copyItem(atPath: d28Resource, toPath: d28LocalPath)

        // BLDatabaseManager.sqlite (+shm/+wal)
        try? fm.removeItem(atPath: bldLocalPath)
        try? fm.removeItem(atPath: bldLocalPath + "-shm")
        try? fm.removeItem(atPath: bldLocalPath + "-wal")

        guard let bl = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite") else {
            throw ToolTaskError.generic("Missing BLDatabaseManager.sqlite in bundle")
        }
        try fm.copyItem(atPath: bl, toPath: bldLocalPath)

        guard let blShm = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite-shm") else {
            throw ToolTaskError.generic("Missing BLDatabaseManager.sqlite-shm in bundle")
        }
        try fm.copyItem(atPath: blShm, toPath: bldLocalPath + "-shm")

        guard let blWal = bundle.path(forResource: "BLDatabaseManager", ofType: "sqlite-wal") else {
            throw ToolTaskError.generic("Missing BLDatabaseManager.sqlite-wal in bundle")
        }
        try fm.copyItem(atPath: blWal, toPath: bldLocalPath + "-wal")
    }

    private static func ensureBundledFileCopiedToDocuments(fileName: String) throws {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dst = docs.appendingPathComponent(fileName).path
        if FileManager.default.fileExists(atPath: dst) { return }

        if let src = Bundle.main.path(forResource: fileName, ofType: nil) {
            try FileManager.default.copyItem(atPath: src, toPath: dst)
        } else {
            throw ToolTaskError.generic("Missing bundled file: \(fileName)")
        }
    }
}
