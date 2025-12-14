import Foundation

struct WineRelease: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var tag: String
    var assetURL: URL
    
    // Hashable requirement:
    static func == (lhs: WineRelease, rhs: WineRelease) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
