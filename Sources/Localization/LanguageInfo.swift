//
//  LanguageInfo.swift
//  Gass SparsWilde
//

import Foundation

/// Language metadata from online repository
struct LanguageInfo: Codable, Identifiable {
    let code: String
    let name: String
    let nativeName: String
    let version: Int
    let downloadURL: String
    let translator: String?
    
    var id: String { code }
}

/// Response from online language list
struct LanguageListResponse: Codable {
    let languages: [LanguageInfo]
}
