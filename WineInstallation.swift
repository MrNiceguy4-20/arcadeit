
import Foundation

struct WineInstallation: Identifiable {
    let id = UUID()
    let name: String
    let path: String
}

enum WineDetector {

    static func isAppleSilicon() -> Bool {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machineMirror = Mirror(reflecting: sysinfo.machine)
        let identifier = machineMirror.children.reduce("") { ident, element in
            guard let value = element.value as? Int8, value != 0 else { return ident }
            return ident + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.contains("arm64")
    }

    static func detectCandidates() -> [WineInstallation] {
        var results: [WineInstallation] = []
        let fm = FileManager.default

        let isARM = isAppleSilicon()

        let candidates: [(String, String)] = isARM ? [
            ("Homebrew wine64 (ARM)", "/opt/homebrew/bin/wine64"),
            ("Homebrew wine (ARM)", "/opt/homebrew/bin/wine"),
            ("CrossOver wine", "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine")
        ] : [
            ("Homebrew wine64 (Intel)", "/usr/local/bin/wine64"),
            ("Homebrew wine (Intel)", "/usr/local/bin/wine"),
            ("CrossOver wine", "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine")
        ]

        for (name, path) in candidates {
            if fm.isExecutableFile(atPath: path) {
                results.append(WineInstallation(name: name, path: path))
            }
        }
        return results
    }
}
