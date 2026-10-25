import Foundation

struct zPatchItem: Identifiable, Codable {
    var id: UUID
    var sourcePath: String
    var destinationPath: String
    var isEnabled: Bool
    var createdDate: Date
    
    init(id: UUID = UUID(), sourcePath: String, destinationPath: String, isEnabled: Bool = false) {
        self.id = id
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.isEnabled = isEnabled
        self.createdDate = Date()
    }
}

class zPatchStore: ObservableObject {
    @Published var patches: [zPatchItem] = []
    
    private let storageKey = "zPatchCustomItems"
    
    init() {
        loadPatches()
    }
    
    func loadPatches() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([zPatchItem].self, from: data) {
            patches = decoded
        }
    }
    
    func savePatches() {
        if let encoded = try? JSONEncoder().encode(patches) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func addPatch(_ patch: zPatchItem) {
        patches.append(patch)
        savePatches()
    }
    
    func removePatch(_ patch: zPatchItem) {
        patches.removeAll { $0.id == patch.id }
        savePatches()
    }
    
    func updatePatch(_ patch: zPatchItem) {
        if let index = patches.firstIndex(where: { $0.id == patch.id }) {
            patches[index] = patch
            savePatches()
        }
    }
    
    func togglePatch(_ patch: zPatchItem) {
        if let index = patches.firstIndex(where: { $0.id == patch.id }) {
            patches[index].isEnabled.toggle()
            savePatches()
        }
    }
}
