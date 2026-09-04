
import Foundation

enum WineInstallerPaths {

    static let installRoot: URL = {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let dir = base
            .appendingPathComponent("ArcadeLauncher")
            .appendingPathComponent("WineGE")

        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        return dir
    }()

    static func findWineBinary(in root: URL) -> String? {
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        for case let url as URL in enumerator {
            let path = url.path

            if path.hasSuffix("/Contents/Resources/wine/bin/wine"),
               fm.isExecutableFile(atPath: path) {
                return path
            }
        }

        guard let fallbackEnum = fm.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        for case let url as URL in fallbackEnum {
            let path = url.path

            if (path.hasSuffix("/bin/wine") || path.hasSuffix("/bin/wine64")),
               fm.isExecutableFile(atPath: path) {
                return path
            }
        }

        return nil
    }
}
