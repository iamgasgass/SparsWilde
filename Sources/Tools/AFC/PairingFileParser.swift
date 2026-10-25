//
//  PairingFileParser.swift
//  SparsWilde
//

import Foundation

enum PairingParseError: LocalizedError {
    case invalidPlist
    case missingUDID

    var errorDescription: String? {
        switch self {
        case .invalidPlist:
            return "Invalid pairing file (plist parse failed)."
        case .missingUDID:
            return "Pairing file does not contain UDID."
        }
    }
}

enum PairingFileParser {
    /// Parses XML or binary plist data and returns the device UDID.
    static func parseUDID(fromPlistData data: Data) throws -> String {
        let object = try parsePropertyList(from: data)
        return try extractUDID(from: object)
    }

    /// Accepts the legacy text representation as well as the new data-based parser.
    static func parseUDID(fromPlistText text: String) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw PairingParseError.invalidPlist
        }
        return try parseUDID(fromPlistData: data)
    }

    /// Validates the pairing record and serializes it as XML plist so AppStorage and
    /// the native pairing-file reader can use one consistent representation.
    static func normalizedPlistText(from data: Data) throws -> String {
        let object = try parsePropertyList(from: data)
        _ = try extractUDID(from: object)
        let xmlData: Data
        do {
            xmlData = try PropertyListSerialization.data(
                fromPropertyList: object,
                format: .xml,
                options: 0
            )
        } catch {
            throw PairingParseError.invalidPlist
        }
        guard let text = String(data: xmlData, encoding: .utf8), !text.isEmpty else {
            throw PairingParseError.invalidPlist
        }
        return text
    }

    private static func parsePropertyList(from data: Data) throws -> Any {
        do {
            return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw PairingParseError.invalidPlist
        }
    }

    private static func extractUDID(from object: Any) throws -> String {
        guard let dict = object as? [String: Any] else {
            throw PairingParseError.invalidPlist
        }

        if let udid = dict["UDID"] as? String,
           !udid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return udid.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Fallback keys found in some pairing-record variants.
        if let udid = dict["UniqueDeviceID"] as? String, !udid.isEmpty { return udid }
        if let udid = dict["DeviceID"] as? String, !udid.isEmpty { return udid }

        throw PairingParseError.missingUDID
    }
}
