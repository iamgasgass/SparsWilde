import SwiftUI

struct DisableSoundView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @AppStorage("DisableDisclosureSoundEnabled") private var enabled: Bool = false

    var body: some View {
        GlassForm {
            GlassSection(header: Text(L("tool_disable_sound"))) {
                Toggle(L("enable_tweak"), isOn: $enabled)
            }
        }
        .liquidGlassScreenStyle()
        .headerProminence(.increased)
        .navigationTitle(L("tool_disable_sound"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
