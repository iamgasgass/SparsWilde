import Foundation

/// ApplyLogger: Records all file operations during Apply process
/// Logs are saved to Documents/Logs/{timestamp}.txt
class ApplyLogger {
    static let shared = ApplyLogger()
    
    private var currentLog: [String] = []
    private var sessionStartTime: Date?
    
    private init() {}
    
    /// Start a new logging session
    func startSession() {
        sessionStartTime = Date()
        currentLog = []
        log("=== Apply Session Started ===")
        log("Date: \(formatDate(Date()))")
    }
    
    /// Log a file operation
    /// - Parameters:
    ///   - fileName: Name of the file being processed
    ///   - sourcePath: Source path of the file
    ///   - targetPath: Target path on device
    ///   - success: Whether the operation succeeded
    ///   - error: Error message if failed
    func logFileOperation(fileName: String, sourcePath: String, targetPath: String, success: Bool, error: String? = nil) {
        let status = success ? "✓ SUCCESS" : "✗ FAILED"
        log("[\(status)] \(fileName)")
        log("  Source: \(sourcePath)")
        log("  Target: \(targetPath)")
        if let error = error {
            log("  Error: \(error)")
        }
        log("")
    }
    
    /// Log a general message
    func log(_ message: String) {
        let timestamp = formatTime(Date())
        let entry = "[\(timestamp)] \(message)"
        currentLog.append(entry)
        print("[ApplyLogger] \(entry)")
    }
    
    /// End session and save log to file
    func endSession() {
        log("=== Apply Session Ended ===")
        if let startTime = sessionStartTime {
            let duration = Date().timeIntervalSince(startTime)
            log("Duration: \(String(format: "%.2f", duration)) seconds")
        }
        
        saveLogToFile()
        currentLog = []
        sessionStartTime = nil
    }
    
    /// Save current log to Documents/Logs folder
    private func saveLogToFile() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[ApplyLogger] Failed to get Documents directory")
            return
        }
        
        let logsFolder = documentsPath.appendingPathComponent("Logs")
        
        // Create Logs folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: logsFolder.path) {
            do {
                try FileManager.default.createDirectory(at: logsFolder, withIntermediateDirectories: true)
            } catch {
                print("[ApplyLogger] Failed to create Logs folder: \(error.localizedDescription)")
                return
            }
        }
        
        // Generate filename with timestamp
        let timestamp = formatFileName(Date())
        let fileName = "apply_\(timestamp).txt"
        let filePath = logsFolder.appendingPathComponent(fileName)
        
        // Write log content
        let content = currentLog.joined(separator: "\n")
        do {
            try content.write(to: filePath, atomically: true, encoding: .utf8)
            print("[ApplyLogger] Log saved to: \(filePath.path)")
        } catch {
            print("[ApplyLogger] Failed to save log: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Date Formatting
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatFileName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }
}
