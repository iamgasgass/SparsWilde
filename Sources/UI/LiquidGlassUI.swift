import SwiftUI
import UIKit

/// Global styling for SparsWilde. On iOS 26+ this deliberately relies on
/// Apple's real Liquid Glass renderer and system glass button styles. Older
/// supported versions receive a material-based fallback with the same shape,
/// spacing, tint, and hierarchy.
struct AdaptiveLiquidGlassAppStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                LiquidGlassAmbientBackground()
                    .ignoresSafeArea()
            }
            .scrollContentBackground(.hidden)
            .tint(AppTheme.accent)
            .modifier(AdaptiveLiquidGlassDefaultButtonStyle())
    }
}

/// Supplies the default style to ordinary buttons throughout the view tree.
/// Components can still opt into a prominent style or a deliberate plain style.
private struct AdaptiveLiquidGlassDefaultButtonStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

/// iOS 26 renders the system's live, refractive Liquid Glass. Before iOS 26,
/// this soft ambient canvas preserves depth and contrast without depending on
/// unavailable APIs or changing the layout.
struct LiquidGlassAmbientBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .systemGroupedBackground)

                Circle()
                    .fill(AppTheme.accent.opacity(0.16))
                    .frame(width: min(geometry.size.width * 0.95, 430))
                    .blur(radius: 95)
                    .position(
                        x: geometry.size.width * 0.92,
                        y: geometry.size.height * 0.08
                    )

                Circle()
                    .fill(Color.cyan.opacity(0.055))
                    .frame(width: min(geometry.size.width * 0.8, 340))
                    .blur(radius: 100)
                    .position(
                        x: geometry.size.width * 0.02,
                        y: geometry.size.height * 0.76
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Applies a native system glass button style to an individual button.
/// The plain fallback is intentional because labels using this modifier add
/// their own carefully sized material fallback below iOS 26.
struct AdaptiveLiquidGlassButtonStyle: ViewModifier {
    var prominent = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            content.buttonStyle(.plain)
        }
    }
}

/// Supplies a visible label on older systems where the native glass button
/// style isn't available. On iOS 26+, the system glass remains unobstructed.
struct AdaptiveLiquidGlassButtonLabel: ViewModifier {
    var prominent = false
    var cornerRadius: CGFloat = 14

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content
                .foregroundStyle(prominent ? Color.white : Color.primary)
                .background(
                    prominent ? AppTheme.accent : Color(uiColor: .quaternarySystemFill),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        }
    }
}

/// Native custom surface for cards, chips and interactive rows. Native glass
/// is only invoked when the running OS supports it; the fallback respects the
/// user's Reduce Transparency accessibility setting.
struct AdaptiveLiquidGlassSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var cornerRadius: CGFloat = 16
    var interactive = false

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content.glassEffect(.regular.interactive(), in: shape)
            } else {
                content.glassEffect(.regular, in: shape)
            }
        } else {
            content
                .background(
                    reduceTransparency
                        ? AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground))
                        : AnyShapeStyle(.ultraThinMaterial),
                    in: shape
                )
                .overlay {
                    shape.strokeBorder(
                        Color.primary.opacity(reduceTransparency ? 0.13 : 0.075),
                        lineWidth: 0.75
                    )
                }
                .shadow(
                    color: Color.black.opacity(reduceTransparency ? 0.025 : 0.055),
                    radius: 12,
                    x: 0,
                    y: 5
                )
        }
    }
}

/// Groups neighbouring native glass shapes so the system can render and morph
/// them as one coherent material. The fallback simply lays out the same views.
struct AdaptiveLiquidGlassContainer<Content: View>: View {
    private let spacing: CGFloat
    private let content: Content

    init(spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

extension View {
    /// Apply once at the app root to give every screen the same Liquid Glass
    /// canvas, native control styling, and translucent scroll content.
    func liquidGlassAppStyle() -> some View {
        modifier(AdaptiveLiquidGlassAppStyle())
    }

    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        modifier(AdaptiveLiquidGlassButtonStyle(prominent: prominent))
    }

    /// For ordinary text/icon controls that don't draw a custom label background.
    func liquidGlassStandardButtonStyle() -> some View {
        modifier(AdaptiveLiquidGlassDefaultButtonStyle())
    }

    func liquidGlassButtonLabel(prominent: Bool = false, cornerRadius: CGFloat = 14) -> some View {
        modifier(AdaptiveLiquidGlassButtonLabel(prominent: prominent, cornerRadius: cornerRadius))
    }

    func liquidGlassSurface(cornerRadius: CGFloat = 16, interactive: Bool = false) -> some View {
        modifier(AdaptiveLiquidGlassSurface(cornerRadius: cornerRadius, interactive: interactive))
    }
}
