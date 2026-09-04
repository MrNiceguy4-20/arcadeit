
import Foundation

final class PrefixManager {

    static func prefixPath(for gameID: UUID) -> String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let dir = appSupport
            .appendingPathComponent("ArcadeLauncher", isDirectory: true)
            .appendingPathComponent("Prefixes", isDirectory: true)
            .appendingPathComponent(gameID.uuidString, isDirectory: true)

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }

    static func initOrRepairPrefix(for game: ArcadeGameProfile, log: LogStore?) {
        let path = prefixPath(for: game.id)

        let script = """
        export WINEPREFIX="\(path)"

        echo "----------------------------------------"
        echo "[PREFIX] Initializing / repairing prefix at $WINEPREFIX"
        echo "----------------------------------------"

        wineboot --init

        echo "----------------------------------------"
        echo "[PREFIX] Installing DX9 + VC++ for this game..."
        echo "----------------------------------------"

        winetricks -q d3dx9 vcrun2010

        echo "----------------------------------------"
        echo "[PREFIX] Per-game prefix ready."
        echo "----------------------------------------"
        """

        runShellScript(script, log: log)
    }

    private static func runShellScript(_ script: String, log: LogStore?) {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("prefix_task_\(UUID().uuidString).sh")

        do {
            try script.write(to: tmp, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tmp.path)
        } catch {
            log?.append("[ERROR] Failed to write prefix script: \(error.localizedDescription)")
            return
        }

        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = [tmp.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError  = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
            DispatchQueue.main.async {
                log?.append(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        do {
            try process.run()
            log?.append("[INFO] Started per-game prefix task…")
        } catch {
            log?.append("[ERROR] Failed to run prefix script: \(error.localizedDescription)")
        }
    }
}
