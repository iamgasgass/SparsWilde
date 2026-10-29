import Foundation
import SwiftUI

/// Native iOS port of the transferable plist tweaks catalog inspired by Nugget.
/// Only preference payloads with a known target path are included here. Operations
/// that require custom asset bundles, daemon ownership changes, or version-specific
/// restore workflows are intentionally not represented as working toggles.
struct NuggetTweakDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let category: String
    let targetPath: String
    let key: String
    let value: AnyCodableValue
    let isRisky: Bool

    static let all: [NuggetTweakDefinition] = [
        .init(id: "lockscreen_footnote", title: "Lock Screen footnote", detail: "Sets a custom empty lock-screen footnote in the configuration profile preferences.", category: "SpringBoard", targetPath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/SharedDeviceConfiguration.plist", key: "LockScreenFootnote", value: .string(""), isRisky: false),
        .init(id: "airdrop_unlimited", title: "AirDrop: remove Everyone time limit", detail: "Overrides the Everyone-mode time limit. iOS may ignore this private preference.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.sharingd.plist", key: "OverrideTimeLimitEveryoneMode", value: .bool(true), isRisky: false),
        .init(id: "dont_lock_after_crash", title: "Do not lock after SpringBoard crash", detail: "Debug-oriented SpringBoard preference; behavior varies by iOS version.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBDontLockAfterCrash", value: .bool(true), isRisky: true),
        .init(id: "dont_dim_on_power", title: "Do not dim/lock while on power", detail: "Requests that SpringBoard does not dim or lock while connected to power.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBDontDimOrLockOnAC", value: .bool(true), isRisky: false),
        .init(id: "hide_low_power_alerts", title: "Hide low-power alerts", detail: "Suppresses the low-power alert preference where supported.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBHideLowPowerAlerts", value: .bool(true), isRisky: false),
        .init(id: "hide_ac_power", title: "Hide AC power indicator", detail: "Requests hiding the AC-power indicator in system UI.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBHideACPower", value: .bool(true), isRisky: false),
        .init(id: "never_breadcrumb", title: "Disable app breadcrumbs", detail: "Disables the previous-app breadcrumb preference where supported.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBNeverBreadcrumb", value: .bool(true), isRisky: false),
        .init(id: "supervision_text", title: "Show supervision text on Lock Screen", detail: "Enables the system preference for supervision text.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBShowSupervisionTextOnLockScreen", value: .bool(true), isRisky: false),
        .init(id: "airplay_display", title: "Enable AirPlay display override support", detail: "Enables an internal SpringBoard preference; unsupported versions may ignore it.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBExtendedDisplayOverrideSupportForAirPlayAndDontFileRadars", value: .bool(true), isRisky: true),
        .init(id: "show_system_aperture", title: "Always show System Aperture in snapshots", detail: "Enables the internal snapshot preference for Dynamic Island/System Aperture.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBAlwaysShowSystemApertureInSnapshots", value: .bool(true), isRisky: false),
        .init(id: "auth_engineering_ui", title: "Authentication engineering UI", detail: "Internal/debug UI flag. Availability and behavior depend on iOS build.", category: "SpringBoard", targetPath: "/var/Managed Preferences/mobile/com.apple.springboard.plist", key: "SBShowAuthenticationEngineeringUI", value: .bool(true), isRisky: true),
        .init(id: "floating_tab_bar", title: "Use floating tab bar", detail: "Requests the UIKit floating tab bar preference.", category: "UIKit", targetPath: "/var/Managed Preferences/mobile/com.apple.UIKit.plist", key: "UseFloatingTabBar", value: .bool(true), isRisky: false),
        .init(id: "show_build_number", title: "Show build number in status bar", detail: "Enables the internal global preference for displaying the OS build number.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "UIStatusBarShowBuildVersion", value: .bool(true), isRisky: false),
        .init(id: "force_rtl", title: "Force right-to-left layout", detail: "Changes global layout direction. Can make some apps difficult to use.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "NSForceRightToLeftWritingDirection", value: .bool(true), isRisky: true),
        .init(id: "force_ltr", title: "Force left-to-right layout", detail: "Changes global layout direction and may override language conventions.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "NSForceLeftToRightWritingDirection", value: .bool(true), isRisky: true),
        .init(id: "metal_hud", title: "Enable Metal HUD", detail: "Enables an internal graphics diagnostics overlay where supported.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "MetalForceHudEnabled", value: .bool(true), isRisky: true),
        .init(id: "imessage_diagnostics", title: "Enable iMessage diagnostics", detail: "Internal diagnostic preference; may expose debugging information.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "iMessageDiagnosticsEnabled", value: .bool(true), isRisky: true),
        .init(id: "ids_diagnostics", title: "Enable IDS diagnostics", detail: "Internal diagnostic preference for Identity Services.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "IDSDiagnosticsEnabled", value: .bool(true), isRisky: true),
        .init(id: "vc_diagnostics", title: "Enable video calling diagnostics", detail: "Internal diagnostic preference; not guaranteed to be honored.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "VCDiagnosticsEnabled", value: .bool(true), isRisky: true),
        .init(id: "accessory_developer", title: "Accessory developer mode", detail: "Enables an internal accessory development preference.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "AccessoryDeveloperEnabled", value: .bool(true), isRisky: true),
        .init(id: "key_flick", title: "Enable keyboard key-flick gestures", detail: "Enables the internal GesturesEnabled preference.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "GesturesEnabled", value: .bool(true), isRisky: false),
        .init(id: "disable_seconds_hand", title: "Disable clock icon seconds hand", detail: "Changes the global clock icon animation preference.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "SBDisableClockIconSecondsHand", value: .bool(true), isRisky: false),
        .init(id: "button_hints", title: "Always show hardware-button hints", detail: "Enables the internal snapshot preference for button hints.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "SBHardwareButtonHintDropletsAlwaysVisibleInSnapshots", value: .bool(true), isRisky: false),
        .init(id: "app_store_debug", title: "App Store debug gestures", detail: "Internal debug option; may reveal hidden developer controls.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/com.apple.AppStore.plist", key: "debugGestureEnabled", value: .bool(true), isRisky: true),
        .init(id: "notes_debug", title: "Notes debug mode", detail: "Enables an internal Notes debugging preference.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/com.apple.mobilenotes.plist", key: "DebugModeEnabled", value: .bool(true), isRisky: true),
        .init(id: "visualize_touches", title: "Visualize touch input", detail: "Enables BackBoard touch visualization for diagnostics.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/com.apple.backboardd.plist", key: "BKDigitizerVisualizeTouches", value: .bool(true), isRisky: true),
        .init(id: "hide_apple_logo", title: "Hide Apple logo on launch", detail: "Internal BackBoard preference; behavior is build-dependent.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/com.apple.backboardd.plist", key: "BKHideAppleLogoOnLaunch", value: .bool(true), isRisky: true),
        .init(id: "wake_haptic", title: "Enable wake gesture haptic", detail: "Enables an internal CoreMotion wake-gesture haptic preference.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/com.apple.CoreMotion.plist", key: "EnableWakeGestureHaptic", value: .bool(true), isRisky: false),
        .init(id: "sound_on_paste", title: "Play sound on paste", detail: "Enables the pasteboard sound preference.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/com.apple.Pasteboard.plist", key: "PlaySoundOnPaste", value: .bool(true), isRisky: false),
        .init(id: "announce_pastes", title: "Announce all pastes", detail: "Enables an internal pasteboard announcement preference.", category: "Internal", targetPath: "/var/Managed Preferences/mobile/com.apple.Pasteboard.plist", key: "AnnounceAllPastes", value: .bool(true), isRisky: false),
        .init(id: "solarium_fallback", title: "Force Liquid Glass fallback", detail: "Forces the system Liquid Glass fallback path where supported.", category: "Liquid Glass", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "SolariumForceFallback", value: .bool(true), isRisky: false),
        .init(id: "disable_solarium", title: "Disable Solarium", detail: "Internal SwiftUI preference to disable the Solarium renderer.", category: "Liquid Glass", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "com.apple.SwiftUI.DisableSolarium", value: .bool(true), isRisky: true),
        .init(id: "ignore_solarium_check", title: "Ignore Solarium linked-on check", detail: "Internal SwiftUI compatibility preference.", category: "Liquid Glass", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck", value: .bool(true), isRisky: true),
        .init(id: "no_liquid_clock", title: "Disable Liquid Glass clock", detail: "Disables the Liquid Glass clock effect where supported.", category: "Liquid Glass", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "SBDisallowGlassTime", value: .bool(true), isRisky: false),
        .init(id: "no_liquid_dock", title: "Disable Liquid Glass Dock", detail: "Disables the Liquid Glass Dock effect where supported.", category: "Liquid Glass", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "SBDisableGlassDock", value: .bool(true), isRisky: false),
        .init(id: "disable_specular_motion", title: "Disable specular motion", detail: "Disables a system-wide specular motion effect where supported.", category: "Liquid Glass", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "SBDisableSpecularEverywhereUsingLSSAssertion", value: .bool(true), isRisky: false),
        .init(id: "disable_outer_refraction", title: "Disable outer refraction", detail: "Disables Liquid Glass outer refraction where supported.", category: "Liquid Glass", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "SolariumDisableOuterRefraction", value: .bool(true), isRisky: false),
        .init(id: "disable_solarium_hdr", title: "Disable Solarium HDR", detail: "Disables the Solarium HDR preference where supported.", category: "Liquid Glass", targetPath: "/var/Managed Preferences/mobile/.GlobalPreferences.plist", key: "SolariumAllowHDR", value: .bool(false), isRisky: false)
    ]
}

enum AnyCodableValue: Hashable {
    case bool(Bool)
    case string(String)
    var propertyListValue: Any {
        switch self { case .bool(let v): return v; case .string(let v): return v }
    }
}

final class NuggetTweakStore: ObservableObject {
    @AppStorage("NuggetTweakCatalogEnabled") var isEnabled = false
    @AppStorage("NuggetEnabledTweakIDs") private var idsJSON = "[]"
    @AppStorage("NuggetEnableSupervision") var enableSupervision = false
    @AppStorage("NuggetSupervisionOrganizationName") var supervisionOrganizationName = "SparsWilde"
    @Published private(set) var enabledIDs: Set<String> = []

    init() { load() }
    func load() {
        guard let data = idsJSON.data(using: .utf8), let values = try? JSONDecoder().decode([String].self, from: data) else { enabledIDs = []; return }
        enabledIDs = Set(values)
    }
    func isSelected(_ id: String) -> Bool { enabledIDs.contains(id) }
    func setSelected(_ selected: Bool, id: String) {
        if selected { enabledIDs.insert(id) } else { enabledIDs.remove(id) }
        if let data = try? JSONEncoder().encode(enabledIDs.sorted()), let json = String(data: data, encoding: .utf8) { idsJSON = json }
    }
    func reset() {
        enabledIDs.removeAll()
        idsJSON = "[]"
    }
    func selectedDefinitions() -> [NuggetTweakDefinition] {
        NuggetTweakDefinition.all.filter { enabledIDs.contains($0.id) }
    }
}
