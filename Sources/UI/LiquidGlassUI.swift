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

/// Shared styling for every independently scrolling screen and sheet. Native
/// navigation bars, tab bars, alerts, menus, pickers, toggles and form controls
/// are intentionally left to SwiftUI so the newest SDK can render its complete
/// system Liquid Glass treatment rather than a hand-drawn imitation.
struct AdaptiveLiquidGlassScreenStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
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
        // Xcode 16.x ships an SDK that does not declare the iOS 26 glass styles.
        // A runtime #available check alone cannot make unknown SDK symbols compile.
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
        #else
        content.buttonStyle(.bordered)
        #endif
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
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            content.buttonStyle(.plain)
        }
        #else
        // Xcode 16.x / iOS 18 SDK fallback. Native glass remains enabled
        // when built with Xcode 26 or newer and run on iOS 26 or newer.
        content.buttonStyle(.plain)
        #endif
    }
}

/// Supplies a visible label on older systems where the native glass button
/// style isn't available. On iOS 26+, the system glass remains unobstructed.
struct AdaptiveLiquidGlassButtonLabel: ViewModifier {
    var prominent = false
    var cornerRadius: CGFloat = 14

    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
        } else {
            fallbackLabel(for: content)
        }
        #else
        // When built with an older SDK, the native glass button style cannot
        // be named at compile time. Always retain a visible fallback label,
        // even if the app happens to run on iOS 26 or newer.
        fallbackLabel(for: content)
        #endif
    }

    private func fallbackLabel(for content: Content) -> some View {
        content
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(
                prominent ? AppTheme.accent : Color(uiColor: .quaternarySystemFill),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
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
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            if interactive {
                content.glassEffect(.regular.interactive(), in: shape)
            } else {
                content.glassEffect(.regular, in: shape)
            }
        } else {
            fallbackSurface(for: content)
        }
        #else
        // These APIs are not present in the iOS 18 SDK shipped with Xcode 16.4.
        fallbackSurface(for: content)
        #endif
    }

    private func fallbackSurface(for content: Content) -> some View {
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
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
        #else
        // Keep the same layout on older SDKs, without referencing an unknown type.
        content
        #endif
    }
}

extension View {
    /// Apply once at the app root to give every screen the same Liquid Glass
    /// canvas, native control styling, and translucent scroll content.
    func liquidGlassAppStyle() -> some View {
        modifier(AdaptiveLiquidGlassAppStyle())
    }

    /// Apply to Form, List and ScrollView roots so individually presented
    /// screens inherit the same glass-aware scroll and control styling.
    func liquidGlassScreenStyle() -> some View {
        modifier(AdaptiveLiquidGlassScreenStyle())
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

// MARK: - Liquid Glass Layout System
//
// Every screen in SparsWilde is composed from the primitives below instead of
// `Form` / `List`. Grouped table cells cannot carry a single, continuous native
// glass surface, so each section is rendered as one real Liquid Glass card
// (`glassEffect` on iOS 26+, material fallback before) floating over the
// ambient canvas, with the rows laid out and separated inside it.

enum LiquidGlassMetrics {
    static let cardCornerRadius: CGFloat = 28
    static let tileCornerRadius: CGFloat = 26
    static let rowHorizontalPadding: CGFloat = 18
    static let rowVerticalPadding: CGFloat = 12
    static let screenHorizontalPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 26
    static let iconBadgeSize: CGFloat = 34
}

extension View {
    /// Paints the shared ambient canvas behind a screen so its glass surfaces
    /// always have depth to refract.
    func liquidGlassBackground() -> some View {
        background {
            LiquidGlassAmbientBackground()
                .ignoresSafeArea()
        }
    }

    /// Subtle inner surface for elements that sit *inside* a glass card
    /// (icon badges, chips, fields). Glass is never stacked on glass.
    func liquidGlassInset(cornerRadius: CGFloat = 14) -> some View {
        modifier(LiquidGlassInset(cornerRadius: cornerRadius))
    }

    /// Capsule input field matching the Liquid Glass cards.
    func liquidGlassField() -> some View {
        modifier(LiquidGlassField())
    }
}

struct LiquidGlassInset: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(Color.primary.opacity(0.07), in: shape)
            .overlay {
                shape.strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.75)
            }
    }
}

struct LiquidGlassField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 46)
            .liquidGlassInset(cornerRadius: 23)
    }
}

// MARK: - Glass Form (replaces Form / List)

struct GlassForm<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LiquidGlassMetrics.sectionSpacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LiquidGlassMetrics.screenHorizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .liquidGlassBackground()
        .liquidGlassScreenStyle()
    }
}

// MARK: - Glass Section (replaces Section)

struct GlassSection<Header: View, Footer: View, Content: View>: View {
    private let header: Header
    private let footer: Footer
    private let showsHeader: Bool
    private let showsFooter: Bool
    private let content: Content

    fileprivate init(header: Header, footer: Footer, showsHeader: Bool, showsFooter: Bool, content: Content) {
        self.header = header
        self.footer = footer
        self.showsHeader = showsHeader
        self.showsFooter = showsFooter
        self.content = content
    }

    init(header: Header, footer: Footer, @ViewBuilder content: () -> Content) {
        self.init(header: header, footer: footer, showsHeader: true, showsFooter: true, content: content())
    }

    var body: some View {
        Group(subviews: content) { rows in
            if !rows.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    if showsHeader {
                        header
                            .modifier(LiquidGlassSectionHeaderStyle())
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(rows) { row in
                            if row.id != rows.first?.id {
                                LiquidGlassRowDivider()
                            }
                            row
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, LiquidGlassMetrics.rowHorizontalPadding)
                                .padding(.vertical, LiquidGlassMetrics.rowVerticalPadding)
                        }
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlassSurface(cornerRadius: LiquidGlassMetrics.cardCornerRadius)

                    if showsFooter {
                        footer
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                    }
                }
                .buttonStyle(GlassRowButtonStyle())
                .labelStyle(GlassRowLabelStyle())
            }
        }
    }
}

extension GlassSection where Header == EmptyView, Footer == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(header: EmptyView(), footer: EmptyView(), showsHeader: false, showsFooter: false, content: content())
    }
}

extension GlassSection where Footer == EmptyView {
    init(header: Header, @ViewBuilder content: () -> Content) {
        self.init(header: header, footer: EmptyView(), showsHeader: true, showsFooter: false, content: content())
    }
}

extension GlassSection where Header == Text, Footer == EmptyView {
    init<S: StringProtocol>(_ title: S, @ViewBuilder content: () -> Content) {
        self.init(header: Text(title), footer: EmptyView(), showsHeader: true, showsFooter: false, content: content())
    }
}

// MARK: - Glass Card Group (each child is its own glass tile)

struct GlassCardGroup<Header: View, Content: View>: View {
    private let header: Header
    private let content: Content

    init(header: Header, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
                .modifier(LiquidGlassSectionHeaderStyle())

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .buttonStyle(GlassCardButtonStyle())
            .labelStyle(GlassRowLabelStyle())
        }
    }
}

// MARK: - Section header / divider

struct LiquidGlassSectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.bold))
            .tracking(1.8)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct LiquidGlassRowDivider: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.09))
            .frame(height: 1 / max(displayScale, 1))
            .padding(.horizontal, LiquidGlassMetrics.rowHorizontalPadding)
            .accessibilityHidden(true)
    }
}

// MARK: - Row button style (buttons & navigation links inside a glass card)

private struct GlassRowDestructiveKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var glassRowDestructive: Bool {
        get { self[GlassRowDestructiveKey.self] }
        set { self[GlassRowDestructiveKey.self] = newValue }
    }
}

struct GlassRowButtonStyle: ButtonStyle {
    /// Plain-text actions are tinted (like grouped-list buttons); navigation
    /// rows keep primary text.
    var tinted: Bool = true
    var showsDisclosure: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        LiquidGlassRowButtonBody(
            configuration: configuration,
            tinted: tinted,
            showsDisclosure: showsDisclosure
        )
    }
}

extension ButtonStyle where Self == GlassRowButtonStyle {
    /// Row inside a glass card that pushes another screen.
    static var glassNavigationRow: GlassRowButtonStyle {
        GlassRowButtonStyle(tinted: false, showsDisclosure: true)
    }
}

private struct LiquidGlassRowButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let tinted: Bool
    let showsDisclosure: Bool
    @Environment(\.isEnabled) private var isEnabled

    private var isDestructive: Bool {
        configuration.role == .destructive
    }

    private var foreground: AnyShapeStyle {
        if isDestructive { return AnyShapeStyle(Color.red) }
        return tinted ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary)
    }

    var body: some View {
        HStack(spacing: 10) {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)

            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(foreground)
        .environment(\.glassRowDestructive, isDestructive)
        .contentShape(Rectangle().inset(by: -LiquidGlassMetrics.rowVerticalPadding))
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(configuration.isPressed ? 0.09 : 0))
                .padding(.horizontal, -10)
                .padding(.vertical, -7)
        }
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Card button style (each control is a full glass tile)

struct GlassCardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = LiquidGlassMetrics.tileCornerRadius

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .padding(.horizontal, LiquidGlassMetrics.rowHorizontalPadding)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .liquidGlassSurface(cornerRadius: cornerRadius, interactive: true)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - Label style (icon in a round inset badge, like the reference cards)

struct GlassRowLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        LiquidGlassRowLabel(configuration: configuration)
    }
}

private struct LiquidGlassRowLabel: View {
    let configuration: LabelStyleConfiguration
    @Environment(\.glassRowDestructive) private var destructive

    var body: some View {
        HStack(spacing: 14) {
            configuration.icon
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(destructive ? AnyShapeStyle(Color.red) : AnyShapeStyle(.tint))
                .frame(width: LiquidGlassMetrics.iconBadgeSize, height: LiquidGlassMetrics.iconBadgeSize)
                .liquidGlassInset(cornerRadius: LiquidGlassMetrics.iconBadgeSize / 2)

            configuration.title
                .multilineTextAlignment(.leading)
        }
    }
}

/// Round inset badge for a bare SF Symbol (used where a row is not a `Label`).
struct GlassIconBadge: View {
    let systemName: String
    var size: CGFloat = LiquidGlassMetrics.iconBadgeSize
    var tint: Color? = nil

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(tint.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.tint))
            .frame(width: size, height: size)
            .liquidGlassInset(cornerRadius: size / 2)
            .accessibilityHidden(true)
    }
}

// MARK: - Menu picker row (Form-style "title … value" inside a glass card)

struct GlassMenuPicker<SelectionValue: Hashable, Content: View>: View {
    private let title: String
    @Binding private var selection: SelectionValue
    private let content: Content

    init(_ title: String, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._selection = selection
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            Picker(title, selection: $selection) {
                content
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .liquidGlassStandardButtonStyle()
        }
    }
}
