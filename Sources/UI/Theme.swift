import SwiftUI
import UIKit

// MARK: - Color Extension

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
    
    /// Initialize Color from a hex string like "#ef9f76" or "ef9f76"
    init(hex string: String) {
        let hex = string.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            // Fallback to default peach color (#ef9f76)
            r = 0xef / 255.0; g = 0x9f / 255.0; b = 0x76 / 255.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
    
    static func disabled() -> Color {
        return Color.secondary
    }
}

// MARK: - App Theme (Feather-style system colors)

struct AppTheme {
    static let bg = Color(.systemGroupedBackground)
    static let row = Color(.secondarySystemGroupedBackground)
    static let textSecondary = Color.secondary
    
    /// Dynamic accent color from user preference
    static var accent: Color {
        let hex = UserDefaults.standard.string(forKey: "SparsWilde.userTintColor") ?? "#ef9f76"
        return Color(hex: hex)
    }
    
    /// System font helper - uses default iOS font
    static func font(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        return .system(style, weight: weight)
    }
}

// MARK: - Primary Action Button (Liquid Glass prominent)

struct WalletStyleButton: View {
    let title: String
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(.headline.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .liquidGlassButtonLabel(prominent: true, cornerRadius: 25)
        }
        .liquidGlassButtonStyle(prominent: true)
        .tint(AppTheme.accent)
        .opacity(disabled ? 0.55 : 1.0)
        .disabled(disabled)
    }
}

// MARK: - Secondary Button

struct SecondaryActionButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .liquidGlassButtonLabel(cornerRadius: 25)
        }
        .liquidGlassButtonStyle()
        .opacity(disabled ? 0.35 : 1.0)
        .disabled(disabled)
    }
}

// MARK: - App Title Header (not used in Feather-style, kept for compatibility)

struct AppTitleHeader: View {
    private let title = "SparsWilde"
    private let subtitle = "itunesstored & bookassetd sbx escape"

    var body: some View {
        EmptyView()
    }
}

// MARK: - Section Header (Feather uses standard Form sections)

struct AppSectionHeader: View {
    let title: String
    var body: some View {
        EmptyView()
    }
}

// MARK: - Card Row (row inside a Liquid Glass card)

struct CardRow: View {
    let title: String
    let subtitle: String?
    let ok: Bool?
    let showChevron: Bool
    let trailing: AnyView?

    var body: some View {
        HStack(spacing: 14) {
            if let ok {
                GlassIconBadge(
                    systemName: ok ? "checkmark.seal.fill" : "xmark.seal.fill",
                    tint: ok ? .green : .red
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ok == true ? .green : (ok == false ? .red : .secondary))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            if let trailing { trailing }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Custom Corner Radius

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
