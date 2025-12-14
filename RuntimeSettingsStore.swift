import Foundation
import Combine

final class RuntimeSettingsStore: ObservableObject {
    @Published var settings: RuntimeSettings
    
    private let settingsURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let dir = appSupport.appendingPathComponent("ArcadeLauncher", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        
        settingsURL = dir.appendingPathComponent("runtimeSettings.json")
        
        if let data = try? Data(contentsOf: settingsURL),
           let decoded = try? JSONDecoder().decode(RuntimeSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: settingsURL)
        }
    }
}
