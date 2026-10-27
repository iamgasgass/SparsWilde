import SwiftUI

struct NuggetTweaksView: View {
    @ObservedObject var store: NuggetTweakStore
    @State private var showRiskConfirmation = false
    @State private var pendingID: String?

    private let categories = ["SpringBoard", "UIKit", "Internal", "Liquid Glass"]

    var body: some View {
        GlassForm {
            GlassSection {
                Toggle("Enable Nugget-compatible tweaks", isOn: $store.isEnabled)
                Text("Native SparsWilde implementation of transferable plist preferences inspired by Nugget. Private keys may be ignored by iOS and are not guaranteed to work on every build.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("Selected: \(store.enabledIDs.count)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(categories, id: \.self) { category in
                let items = NuggetTweakDefinition.all.filter { $0.category == category }
                if !items.isEmpty {
                    GlassSection(header: Text(category)) {
                        ForEach(items) { item in
                            Toggle(isOn: Binding(
                                get: { store.isSelected(item.id) },
                                set: { newValue in
                                    if newValue && item.isRisky {
                                        pendingID = item.id
                                        showRiskConfirmation = true
                                    } else {
                                        store.setSelected(newValue, id: item.id)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                    Text(item.detail).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            GlassSection(header: Text("Actions")) {
                Button(role: .destructive) { store.reset() } label: {
                    Label("Clear all selections", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .liquidGlassScreenStyle()
        .headerProminence(.increased)
        .navigationTitle("Nugget Tweaks")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Experimental system preference", isPresented: $showRiskConfirmation) {
            Button("Cancel", role: .cancel) { pendingID = nil }
            Button("Enable") {
                if let id = pendingID { store.setSelected(true, id: id) }
                pendingID = nil
            }
        } message: {
            Text("This is an internal or diagnostic preference. It may be ignored or affect system stability. Continue only if you have a current backup.")
        }
    }
}
