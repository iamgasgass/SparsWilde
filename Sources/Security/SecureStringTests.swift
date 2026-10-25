//
//  SecureStringTests.swift
//  Gass SparsWilde
//
//  Unit tests for SecureString obfuscation utility
//

import Foundation

/// Simple test runner for SecureString
enum SecureStringTests {
    
    static func runAllTests() {
        print("=== Running SecureString Tests ===\n")
        
        testReveal()
        testXorReveal()
        testXorRevealMulti()
        testObfuscationRoundTrip()
        
        print("\n=== All SecureString Tests Passed ===")
    }
    
    static func testReveal() {
        print("Test: reveal() - Basic byte array decoding")
        
        // Test 1: Simple string
        let bytes1: [UInt8] = [0x2F, 0x76, 0x61, 0x72] // "/var"
        let result1 = SecureString.reveal(bytes1)
        assert(result1 == "/var", "Expected '/var', got '\(result1)'")
        print("  ✓ Basic reveal works: /var")
        
        // Test 2: Longer path
        let bytes2: [UInt8] = [0x2F, 0x76, 0x61, 0x72, 0x2F, 0x6D, 0x6F, 0x62, 0x69, 0x6C, 0x65] // "/var/mobile"
        let result2 = SecureString.reveal(bytes2)
        assert(result2 == "/var/mobile", "Expected '/var/mobile', got '\(result2)'")
        print("  ✓ Longer path works: /var/mobile")
        
        // Test 3: Empty array
        let result3 = SecureString.reveal([])
        assert(result3 == "", "Expected empty string, got '\(result3)'")
        print("  ✓ Empty array handled correctly")
    }
    
    static func testXorReveal() {
        print("\nTest: xorReveal() - Single-byte XOR decoding")
        
        // Test with key 0x5D
        // "/var" XOR 0x5D = [0x72, 0x33, 0x26, 0x37]
        let obfuscated: [UInt8] = [0x72, 0x33, 0x26, 0x37]
        let result = SecureString.xorReveal(obfuscated, key: 0x5D)
        assert(result == "/var", "Expected '/var', got '\(result)'")
        print("  ✓ XOR decoding works with key 0x5D")
        
        // Test with key 0xFF (inverts all bits)
        let bytes: [UInt8] = [0xD0, 0x89, 0x9E, 0x8D] // "/var" XOR 0xFF
        let result2 = SecureString.xorReveal(bytes, key: 0xFF)
        assert(result2 == "/var", "Expected '/var', got '\(result2)'")
        print("  ✓ XOR decoding works with key 0xFF")
    }
    
    static func testXorRevealMulti() {
        print("\nTest: xorRevealMulti() - Multi-byte XOR decoding")
        
        // Test with repeating key [0x51, 0x6D]
        let obfuscated: [UInt8] = [0x7E, 0x0B, 0x1E, 0x0E] // "/var" XOR [0x51, 0x6D, 0x51, 0x6D]
        let result = SecureString.xorRevealMulti(obfuscated, key: [0x51, 0x6D])
        assert(result == "/var", "Expected '/var', got '\(result)'")
        print("  ✓ Multi-byte XOR decoding works")
        
        // Test with single-byte key (should work same as xorReveal)
        let obfuscated2: [UInt8] = [0x72, 0x33, 0x26, 0x37]
        let result2 = SecureString.xorRevealMulti(obfuscated2, key: [0x5D])
        assert(result2 == "/var", "Expected '/var', got '\(result2)'")
        print("  ✓ Multi-byte with single key works")
        
        // Test with empty key
        let result3 = SecureString.xorRevealMulti([0x2F, 0x76], key: [])
        assert(result3 == "", "Expected empty string for empty key")
        print("  ✓ Empty key handled correctly")
    }
    
    static func testObfuscationRoundTrip() {
        #if DEBUG
        print("\nTest: obfuscate() round-trip - Development helper")
        
        let original = "/var/mobile"
        let key: UInt8 = 0xAB
        
        let obfuscated = SecureString.obfuscate(original, key: key)
        let revealed = SecureString.xorReveal(obfuscated, key: key)
        
        assert(revealed == original, "Round-trip failed: expected '\(original)', got '\(revealed)'")
        print("  ✓ Obfuscate -> reveal round-trip works")
        
        let bytes = SecureString.toBytes(original)
        let direct = SecureString.reveal(bytes)
        assert(direct == original, "toBytes round-trip failed")
        print("  ✓ toBytes -> reveal round-trip works")
        #else
        print("\nTest: obfuscate() - Skipped (DEBUG only)")
        #endif
    }
}

// Run tests if this file is executed directly
#if DEBUG
// Uncomment to run tests:
// SecureStringTests.runAllTests()
#endif
