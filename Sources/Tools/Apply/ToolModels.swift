import Foundation

enum ToolID: String, CaseIterable {
    case disableSound
    case replaceMobileGestalt
    case toolA
    case toolB
}

enum ToolRunState: Equatable {
    case idle
    case running(toolName: String)
    case success
    case failed(message: String)
}

struct ToolRunLogLine: Identifiable, Equatable {
    let id = UUID()
    let date = Date()
    let text: String
}
