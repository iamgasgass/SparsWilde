//
//  LanguageFileUtility.swift
//  SparsWilde
//

import Foundation

/// Utility functions for checking language file existence
enum LanguageFileUtility {
    /// Check if a language file exists locally (downloaded or bundled)
    static func hasLanguageFile(_ code: String) -> Bool {
        // Check downloaded languages in Documents
        let documentsPath = URL.documentsDirectory
            .appendingPathComponent("Languages")
            .appendingPathComponent("\(code).json")
        
        if FileManager.default.fileExists(atPath: documentsPath.path) {
            return true
        }
        
        // Check Resources directory
        if let resourceURL = Bundle.main.resourceURL {
            let resourcePath = resourceURL.appendingPathComponent("\(code).json")
            if FileManager.default.fileExists(atPath: resourcePath.path) {
                return true
            }
        }
        
        // Check as bundle resource
        if Bundle.main.path(forResource: code, ofType: "json") != nil {
            return true
        }
        
        return false
    }
}
