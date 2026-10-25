//
//  LocalizationExample.swift
//  SparsWilde
//
//  This file shows examples of how to integrate localization into existing views.
//  To use localization, replace hardcoded strings with L() function calls.
//

import SwiftUI

// EXAMPLE 1: Simple text replacement
// Before:
// Text("Settings")
// After:
// Text(L("nav_settings"))

// EXAMPLE 2: In SettingsView
struct SettingsViewLocalized: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Guide button - localized
                Button(action: {}) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text(L("settings_guide"))  // Instead of "Guide"
                        Spacer()
                    }
                }
                
                // Contact button - localized
                Button(action: {}) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text(L("settings_contact"))  // Instead of "Contact me"
                        Spacer()
                    }
                }
                
                // Language button - localized
                Button(action: {}) {
                    HStack {
                        Image(systemName: "globe")
                        Text(L("settings_language"))  // Instead of "Language"
                        Spacer()
                    }
                }
                
                // Donate button - localized
                Button(action: {}) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text(L("settings_donate"))  // Instead of "Donate"
                        Spacer()
                    }
                }
            }
        }
    }
}

// EXAMPLE 3: ContentView home screen
struct ContentViewLocalized: View {
    var body: some View {
        VStack {
            // System Status - localized
            Text(L("system_status"))  // Instead of "System Status"
            
            // Status subtitle - localized
            let isReady = true
            Text(isReady ? L("system_status_ready") : L("system_status_not_ready"))
            
            // Error messages - localized
            Text(L("pairing_file_missing"))  // Instead of "Missing pairing file"
            Text(L("pairing_file_import_prompt"))  // Instead of "Please import..."
            
            // Apply button - localized
            Button(action: {}) {
                Text(L("apply_button"))  // Instead of "Apply"
            }
        }
    }
}

// EXAMPLE 4: Alerts with localization
struct AlertExample: View {
    @State private var showAlert = false
    
    var body: some View {
        Button("Show Alert") {
            showAlert = true
        }
        .alert(L("alert_error"), isPresented: $showAlert) {  // Instead of "Error"
            Button(L("alert_ok"), role: .cancel) {}  // Instead of "OK"
        } message: {
            Text(L("msg_error_unknown"))  // Instead of "An unknown error occurred."
        }
    }
}

// EXAMPLE 5: Dynamic strings with interpolation
// For strings like "Version 1.0 (123)", use String format:
func versionString(version: String, build: String) -> String {
    return L("version_format")
        .replacingOccurrences(of: "{version}", with: version)
        .replacingOccurrences(of: "{build}", with: build)
}

// EXAMPLE 6: Tool descriptions
struct ToolRowLocalized: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text(L("tool_mobile_gestalt"))  // Instead of "MobileGestalt"
            Text(L("tool_mobile_gestalt_desc"))  // Instead of "Modify MobileGestalt file"
        }
    }
}

// EXAMPLE 7: Observing language changes
struct LanguageAwareView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack {
            Text(L("nav_settings"))
            Text("Current language: \(localizationManager.currentLanguage)")
        }
        // View will automatically update when language changes
    }
}

// EXAMPLE 8: Complete integration pattern for a view
struct MyCustomView: View {
    // 1. Add observer if you need to react to language changes
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack {
            // 2. Replace all hardcoded strings with L() calls
            Text(L("section_tweaks"))
                .font(.headline)
            
            Text(L("tool_mobile_gestalt_desc"))
                .font(.caption)
            
            // 3. Use in buttons
            Button(L("button_save")) {
                // Save action
            }
            
            // 4. Use in forms
            TextField(L("settings_zpatch_passcode_placeholder"), text: .constant(""))
            
            // 5. Use in pickers
            Picker(L("settings_language"), selection: .constant("en")) {
                Text("English").tag("en")
                Text("Vietnamese").tag("vi")
            }
        }
    }
}

// Note: To integrate localization into the entire app:
// 1. Import LocalizationManager in each view file
// 2. Replace Text("Hardcoded") with Text(L("key_name"))
// 3. Make sure all keys exist in language JSON files
// 4. Test by switching languages in Settings
