import SwiftUI

struct NuggetSystemTweaksView: View {
    @ObservedObject var toolStore: ToolStore
    @StateObject private var store = NuggetSystemTweaksStore()
    @State private var showResetConfirmation = false

    var body: some View {
        GlassForm {
            GlassSection(header: Text("Nugget-style tweak catalog")) {
                Toggle(L("system_tweaks_enable"), isOn: $toolStore.systemTweaksEnabled)
                Text(L("system_tweaks_intro"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("\(store.selectedCount) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(NuggetSystemTweakCategory.allCases) { category in
                let definitions = NuggetSystemTweaksStore.definitions(for: category)
                if !definitions.isEmpty {
                    GlassSection(header: Text(category.title)) {
                        ForEach(definitions) { definition in
                            VStack(alignment: .leading, spacing: 5) {
                                Toggle(isOn: Binding(
                                    get: { store.isEnabled(definition.id) },
                                    set: { store.setEnabled($0, for: definition.id) }
                                )) {
                                    Text(definition.title)
                                        .font(.body)
                                }
                                Text(definition.description)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                if let warning = definition.warning {
                                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                                        .font(.footnote)
                                        .foregroundStyle(.orange)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            GlassSection(header: Text(L("section_actions"))) {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label(L("system_tweaks_reset"), systemImage: "arrow.counterclockwise")
                }
            }

            GlassSection(header: Text(L("section_info"))) {
                Text(L("system_tweaks_notice"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .liquidGlassScreenStyle()
        .headerProminence(.increased)
        .navigationTitle(L("tool_system_tweaks"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L("system_tweaks_reset_confirm"), isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button(L("system_tweaks_reset"), role: .destructive) { store.resetAll() }
            Button(L("alert_cancel"), role: .cancel) { }
        }
    }
}
