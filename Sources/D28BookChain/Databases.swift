//
//  Databases.swift
//  Gass SparsWilde
//

import Foundation
import SQLite3

final class Databases {

    // MARK: - Backward-compatible API

    static func patchDatabase(dbPath: String, uuid: String, ip: String, port: UInt16) throws {
        try patchDownloads28Database(
            dbPath: dbPath,
            uuid: uuid,
            ip: ip,
            port: port,
            blFileNameOnServer: "BLDatabaseManager.sqlite"
        )
    }

    // MARK: - downloads.28.sqlitedb

    static func patchDownloads28Database(
        dbPath: String,
        uuid: String,
        ip: String,
        port: UInt16,
        blFileNameOnServer: String = "BLDatabaseManager.sqlite"
    ) throws {
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            throw NSError(domain: "SQLite", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to open downloads.28 DB"])
        }
        defer { sqlite3_close(db) }

        let bldbLocalPrefix =
            "/private/var/containers/Shared/SystemGroup/\(uuid)/Documents/BLDatabaseManager/BLDatabaseManager.sqlite"

        let sql1 = """
        UPDATE asset
        SET local_path = CASE
            WHEN local_path LIKE '%/BLDatabaseManager.sqlite'
                THEN '\(escapeSQLString(bldbLocalPrefix))'
            WHEN local_path LIKE '%/BLDatabaseManager.sqlite-shm'
                THEN '\(escapeSQLString(bldbLocalPrefix))-shm'
            WHEN local_path LIKE '%/BLDatabaseManager.sqlite-wal'
                THEN '\(escapeSQLString(bldbLocalPrefix))-wal'
        END
        WHERE local_path LIKE '/private/var/containers/Shared/SystemGroup/%/Documents/BLDatabaseManager/BLDatabaseManager.sqlite%';
        """
        try execSQL(db: db, sql: sql1)

        let bldbServerPrefix = "http://\(ip):\(port)/\(blFileNameOnServer)"
        let sql2 = """
        UPDATE asset
        SET url = CASE
            WHEN url LIKE '%/BLDatabaseManager.sqlite'
                THEN '\(escapeSQLString(bldbServerPrefix))'
            WHEN url LIKE '%/BLDatabaseManager.sqlite-shm'
                THEN '\(escapeSQLString(bldbServerPrefix))-shm'
            WHEN url LIKE '%/BLDatabaseManager.sqlite-wal'
                THEN '\(escapeSQLString(bldbServerPrefix))-wal'
        END
        WHERE url LIKE '%/BLDatabaseManager.sqlite%';
        """
        try execSQL(db: db, sql: sql2)

        _ = sqlite3_exec(db, "COMMIT;", nil, nil, nil)
    }

    // MARK: - BLDatabaseManager.sqlite (generic for DisableSound)

    static func patchBLDatabaseManager(
        dbPath: String,
        targetDisclosurePath: String,
        assetURL: String,
        downloadID: String
    ) throws {
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            throw NSError(domain: "SQLite", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to open BLDatabaseManager DB"])
        }
        defer { sqlite3_close(db) }

        let targetEsc = escapeSQLString(targetDisclosurePath)
        let urlEsc = escapeSQLString(assetURL)
        let downloadIDEsc = escapeSQLString(downloadID)

        let sql1 = """
        UPDATE ZBLDOWNLOADINFO
        SET ZASSETPATH = '\(targetEsc)',
            ZPLISTPATH  = '\(targetEsc)',
            ZDOWNLOADID = '\(downloadIDEsc)';
        """

        let sql2 = """
        UPDATE ZBLDOWNLOADINFO
        SET ZURL = '\(urlEsc)';
        """

        try execSQL(db: db, sql: sql1)
        try execSQL(db: db, sql: sql2)
        _ = sqlite3_exec(db, "COMMIT;", nil, nil, nil)
    }

    // MARK: - BLDatabaseManager.sqlite (MobileGestalt specific)

    /// Matches your ZBLDOWNLOADINFO.csv behavior:
    /// - ZASSETPATH => target + ".zassetpath"
    /// - ZDOWNLOADID => "../../../../../../private/var/..." (no leading slash after traversal)
    /// - Keep ZPLISTPATH unchanged (seed uses /var/mobile/Media/com.apple.MobileGestalt.plist)
    static func patchBLDatabaseManagerForMobileGestalt(
        dbPath: String,
        targetPlistPath: String,
        assetURL: String
    ) throws {
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            throw NSError(domain: "SQLite", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to open BLDatabaseManager DB"])
        }
        defer { sqlite3_close(db) }

        let normalized: String
        if targetPlistPath.hasPrefix("/private/var/") {
            normalized = targetPlistPath
        } else if targetPlistPath.hasPrefix("/var/") {
            normalized = "/private" + targetPlistPath
        } else {
            normalized = targetPlistPath
        }

        let zassetPath = normalized + ".zassetpath"
        let trimmedLeadingSlash = normalized.hasPrefix("/") ? String(normalized.dropFirst()) : normalized
        let downloadID = "../../../../../../" + trimmedLeadingSlash

        let zassetPathEsc = escapeSQLString(zassetPath)
        let downloadIDEsc = escapeSQLString(downloadID)
        let urlEsc = escapeSQLString(assetURL)

        let sql1 = """
        UPDATE ZBLDOWNLOADINFO
        SET ZASSETPATH = '\(zassetPathEsc)',
            ZDOWNLOADID = '\(downloadIDEsc)',
            ZURL = '\(urlEsc)';
        """

        // keep same state as seed (2)
        let sql2 = """
        UPDATE ZBLDOWNLOADINFO
        SET ZSTATE = 2;
        """

        try execSQL(db: db, sql: sql1)
        try execSQL(db: db, sql: sql2)
        _ = sqlite3_exec(db, "COMMIT;", nil, nil, nil)
    }

    // MARK: - SQL helpers

    @discardableResult
    static func execSQL(db: OpaquePointer?, sql: String) throws -> Int32 {
        var errMsg: UnsafeMutablePointer<Int8>? = nil
        let result = sqlite3_exec(db, sql, nil, nil, &errMsg)
        if result != SQLITE_OK {
            let message = errMsg.flatMap { String(cString: $0) } ?? "Unknown SQL error"
            sqlite3_free(errMsg)
            throw NSError(domain: "SQLite", code: Int(result), userInfo: [NSLocalizedDescriptionKey: message])
        }
        return result
    }

    private static func escapeSQLString(_ s: String) -> String {
        s.replacingOccurrences(of: "'", with: "''")
    }
}
