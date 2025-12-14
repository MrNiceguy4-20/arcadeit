import Foundation

struct RuntimeSettings: Codable {
    var wineBinaryPath: String
    var winePrefixPath: String
    var useVirtualDesktop: Bool
    var virtualDesktopWidth: Int
    var virtualDesktopHeight: Int
    
    static var `default`: RuntimeSettings {
        RuntimeSettings(
            wineBinaryPath: "/usr/local/bin/wine",
            winePrefixPath: "\(NSHomeDirectory())/.wine",
            useVirtualDesktop: false,
            virtualDesktopWidth: 1280,
            virtualDesktopHeight: 720
        )
    }
}
