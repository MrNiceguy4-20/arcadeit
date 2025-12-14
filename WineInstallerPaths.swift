//
//  WineInstallerPaths.swift
//  arcadeit
//

import Foundation

enum WineInstallerPaths {

    /// Root directory where Wine builds are installed
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

    // ------------------------------------------------------
    // MARK: - Wine Binary Discovery (FIXED)
    // ------------------------------------------------------

    static func findWineBinary(in root: URL) -> String? {
        let fm = FileManager.default

        // First pass: ONLY accept correct macOS Wine.app runtime
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        for case let url as URL in enumerator {
            let path = url.path

            // ✅ CORRECT runtime binary for Gcenx builds
            if path.hasSuffix("/Contents/Resources/wine/bin/wine"),
               fm.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Second pass: CLI-style Wine installs (fallback)
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
