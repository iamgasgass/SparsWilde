//
//  SecureString.swift
//  SparsWilde
//
//  String obfuscation utility for IP protection and anti-reverse engineering
//

import Foundation

/// Utility class for obfuscating sensitive strings to prevent them from appearing
/// in the binary's __cstring section during static analysis
final class SecureString {
    
    // MARK: - Byte Array Decoding
    
    /// Reveals a string from an array of UTF-8 byte values
    /// - Parameter bytes: Array of UInt8 values representing UTF-8 encoded string
    /// - Returns: Decoded string
    ///
    /// Example:
    /// ```
    /// let path = SecureString.reveal([0x2F, 0x76, 0x61, 0x72]) // "/var"
    /// ```
    static func reveal(_ bytes: [UInt8]) -> String {
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }
    
    // MARK: - XOR Obfuscation
    
    /// Reveals a string from XOR-obfuscated byte array
    /// - Parameters:
    ///   - obfuscated: XOR-encoded byte array
    ///   - key: XOR key used for obfuscation
    /// - Returns: Decoded string
    ///
    /// Example:
    /// ```
    /// let obfuscated: [UInt8] = [0x72, 0x33, 0x26, 0x37]
    /// let path = SecureString.xorReveal(obfuscated, key: 0x5D) // "/var"
    /// ```
    static func xorReveal(_ obfuscated: [UInt8], key: UInt8) -> String {
        let decoded = obfuscated.map { $0 ^ key }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
    
    // MARK: - Multi-byte XOR Obfuscation
    
    /// Reveals a string from XOR-obfuscated byte array using a multi-byte key
    /// - Parameters:
    ///   - obfuscated: XOR-encoded byte array
    ///   - key: Array of bytes used as repeating XOR key
    /// - Returns: Decoded string
    ///
    /// Example:
    /// ```
    /// let obfuscated: [UInt8] = [0x7E, 0x0B, 0x1E, 0x0E]
    /// let path = SecureString.xorRevealMulti(obfuscated, key: [0x51, 0x6D]) // "/var"
    /// ```
    static func xorRevealMulti(_ obfuscated: [UInt8], key: [UInt8]) -> String {
        guard !key.isEmpty else { return "" }
        let decoded = obfuscated.enumerated().map { index, byte in
            byte ^ key[index % key.count]
        }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
    
    // MARK: - Helper: Obfuscate String (for development use only)
    
    #if DEBUG
    /// Helper function to generate obfuscated byte arrays during development
    /// This should NOT be called in release builds - it's only for generating obfuscated constants
    /// - Parameters:
    ///   - string: String to obfuscate
    ///   - key: XOR key (single byte or you can extend for multi-byte)
    /// - Returns: Array of obfuscated bytes
    static func obfuscate(_ string: String, key: UInt8) -> [UInt8] {
        let bytes = Array(string.utf8)
        return bytes.map { $0 ^ key }
    }
    
    /// Helper function to generate plain byte arrays during development
    static func toBytes(_ string: String) -> [UInt8] {
        return Array(string.utf8)
    }
    #endif
}
