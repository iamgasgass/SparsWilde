//
//  BookassetdUUIDHelper.swift
//  Gass SparsWilde
//
//  Created by YangJiii on 2/1/26.
//

import Foundation
import UIKit

enum BookassetdUUIDError: Error, LocalizedError {
    case timedOut
    case parseFailed

    var errorDescription: String? {
        switch self {
        case .timedOut:
            return "Timed out waiting for bookassetd UUID. Open Apple Books and download any book while the app is running."
        case .parseFailed:
            return "Failed to parse bookassetd UUID from syslog."
        }
    }
}

enum BookassetdUUIDHelper {
    static func parseUUID(from syslogLine: String) -> String? {
        if let range = syslogLine.range(of: "/var/containers/Shared/SystemGroup/") {
            let tail = syslogLine[range.upperBound...]
            if let slash = tail.firstIndex(of: "/") {
                let uuid = String(tail[..<slash])
                if uuid.count >= 10, !uuid.hasPrefix("systemgroup.com.apple") {
                    return uuid
                }
            }
        }
        if syslogLine.contains("/Documents/BLDownloads/"),
           let part = syslogLine.components(separatedBy: "/var/containers/Shared/SystemGroup/").dropFirst().first,
           let uuid = part.components(separatedBy: "/Documents/BLDownloads").first,
           uuid.count >= 10 {
            return uuid
        }
        return nil
    }

    /// Capture UUID from syslog. Optionally opens Books first, and returns to our app when captured.
    static func captureUUID(
        timeout: TimeInterval = 120,
        openBooksFirst: Bool = true,
        returnToAppAfterCapture: Bool = true
    ) async throws -> String {
        let ourBundleID = Bundle.main.bundleIdentifier

        if openBooksFirst {
            LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: "com.apple.iBooks")
        }

        let uuid: String = try await withCheckedThrowingContinuation { continuation in
            var finished = false

            JITEnableContext.shared.startSyslogRelay { line in
                guard !finished else { return }
                guard let line else { return }

                if line.contains("bookassetd")
                    && (line.contains("/Documents/BLDownloads/") || line.contains("/var/containers/Shared/SystemGroup/")) {

                    if let uuid = parseUUID(from: line) {
                        finished = true
                        JITEnableContext.shared.stopSyslogRelay()
                        continuation.resume(returning: uuid)
                    }
                }
            } onError: { error in
                guard !finished else { return }
                finished = true
                JITEnableContext.shared.stopSyslogRelay()
                continuation.resume(throwing: error ?? BookassetdUUIDError.parseFailed)
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                guard !finished else { return }
                finished = true
                JITEnableContext.shared.stopSyslogRelay()
                continuation.resume(throwing: BookassetdUUIDError.timedOut)
            }
        }

        if returnToAppAfterCapture, let ourBundleID {
            LSApplicationWorkspaceDefaultWorkspace().openApplication(withBundleID: ourBundleID)
        }

        return uuid
    }
}
