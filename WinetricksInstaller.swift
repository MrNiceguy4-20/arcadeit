
import Foundation

enum WinetricksInstaller {

    static let winetricksURL =
        URL(string: "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks")!

    static let installPath: URL = {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let dir = base
            .appendingPathComponent("ArcadeLauncher")
            .appendingPathComponent("Tools")

        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        return dir.appendingPathComponent("winetricks")
    }()

    static func installOrUpdate(
        log: LogStore?,
        completion: @escaping (Bool) -> Void
    ) {
        log?.append("[WINETRICKS] Downloading winetricks…")

        let task = URLSession.shared.downloadTask(with: winetricksURL) { tempURL, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    log?.append("[ERROR] Winetricks download failed: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }

            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    log?.append("[ERROR] Winetricks download returned no file")
                    completion(false)
                }
                return
            }

            do {
                let fm = FileManager.default

                if fm.fileExists(atPath: installPath.path) {
                    try fm.removeItem(at: installPath)
                }

                try fm.copyItem(at: tempURL, to: installPath)

                try fm.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: installPath.path
                )

                DispatchQueue.main.async {
                    log?.append("[WINETRICKS] Installed at \(installPath.path)")
                    completion(true)
                }

            } catch {
                DispatchQueue.main.async {
                    log?.append("[ERROR] Failed to install winetricks: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }

        task.resume()
    }

    static func run(
        verb: String,
        wineBinary: String,
        prefix: String,
        log: LogStore?
    ) {
        guard FileManager.default.isExecutableFile(atPath: installPath.path) else {
            log?.append("[ERROR] Winetricks not installed")
            return
        }

        let process = Process()
        process.launchPath = installPath.path
        process.arguments = [verb]

        process.environment = [
            "WINE": wineBinary,
            "WINEPREFIX": prefix,
            "WINETRICKS_SUPER_QUIET": "1",
            "WINEDEBUG": "-all"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { fh in
            let data = fh.availableData
            guard let text = String(data: data, encoding: .utf8),
                  !text.isEmpty else { return }

            DispatchQueue.main.async {
                log?.append("[WINETRICKS] \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }

        do {
            try process.run()
        } catch {
            log?.append("[ERROR] Failed to run winetricks: \(error.localizedDescription)")
        }
    }
}
