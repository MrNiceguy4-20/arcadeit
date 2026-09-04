
import Foundation

enum GameLaunchError: Error {
    case wineNotFound
    case launchFailed(String)
}

final class GameLauncher {
    static let shared = GameLauncher()

    var settingsStore: RuntimeSettingsStore?
    var logStore: LogStore?

    func configure(with settings: RuntimeSettingsStore, logStore: LogStore) {
        self.settingsStore = settings
        self.logStore = logStore
    }

    func launch(game: inout ArcadeGameProfile) throws {

        guard let s = settingsStore?.settings else {
            throw GameLaunchError.launchFailed("Runtime settings not configured")
        }

        let winePath = s.wineBinaryPath

        guard FileManager.default.isExecutableFile(atPath: winePath) else {
            logStore?.append("[ERROR] Wine not found at \(winePath)")
            throw GameLaunchError.wineNotFound
        }

        InputMapper.shared.configure(for: game.inputMapping)

        let winePrefix: String
        if game.usePerGamePrefix {
            winePrefix = PrefixManager.prefixPath(for: game.id)
            PrefixManager.initOrRepairPrefix(for: game, log: logStore)
        } else {
            winePrefix = s.winePrefixPath
        }

        if game.usePerGamePrefix,
           !game.winetricksApplied,
           !game.winetricksVerbs.isEmpty {

            logStore?.append("[WINETRICKS] Applying dependencies for \(game.name)…")

            for verb in game.winetricksVerbs {
                WinetricksInstaller.run(
                    verb: verb.rawValue,
                    wineBinary: winePath,
                    prefix: winePrefix,
                    log: logStore
                )
            }

            game.winetricksApplied = true
        }

        applyPrelaunchPatches(for: game)

        let process = Process()
        process.launchPath = winePath

        var args: [String] = []

        var useVirtualDesktop = s.useVirtualDesktop
        var desktopWidth = s.virtualDesktopWidth
        var desktopHeight = s.virtualDesktopHeight

        if game.overrideResolution {
            desktopWidth = game.resolutionWidth
            desktopHeight = game.resolutionHeight
            useVirtualDesktop = useVirtualDesktop || game.forceWindowed
        }

        if useVirtualDesktop {
            args.append("explorer")
            args.append("/desktop=\(game.name.prefix(10)),\(desktopWidth)x\(desktopHeight)")
        }

        args.append(game.executablePath)
        args.append(contentsOf: game.arguments)

        process.arguments = args
        process.currentDirectoryPath = game.workingDirectory

        var env = ProcessInfo.processInfo.environment
        env["WINEPREFIX"] = winePrefix

        if game.forceFullscreen {
            env["WINE_FULLSCREEN_FSR"] = "1"
        }

        if game.silentWine {
            env["WINEDEBUG"] = "-all"
        }

        var overrides: [String] = []

        if game.disableWineMenuBuilder {
            overrides.append("winemenubuilder.exe=")
        }

        for dll in game.dllOverrides {
            overrides.append("\(dll)=n")
        }

        if !overrides.isEmpty {
            env["WINEDLLOVERRIDES"] = overrides.joined(separator: ",")
            logStore?.append("[INFO] WINEDLLOVERRIDES=\(env["WINEDLLOVERRIDES"]!)")
        }

        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError  = pipe

        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty else { return }
            if let text = String(data: data, encoding: .utf8) {
                text.split(whereSeparator: \.isNewline).forEach { line in
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    self?.logStore?.append(trimmed)
                }
            }
        }

        process.terminationHandler = { [weak self] proc in
            self?.logStore?.append("[INFO] Game exited with status \(proc.terminationStatus)")
        }

        logStore?.append("[INFO] Launching \(game.name)")
        logStore?.append("[INFO] WINEPREFIX=\(winePrefix)")
        logStore?.append("[INFO] \(winePath) \(args.joined(separator: " "))")

        do {
            try process.run()
        } catch {
            logStore?.append("[ERROR] Failed to launch: \(error.localizedDescription)")
            throw GameLaunchError.launchFailed(error.localizedDescription)
        }
    }

    private func applyPrelaunchPatches(for game: ArcadeGameProfile) {
        guard !game.prelaunchPatches.isEmpty else { return }

        logStore?.append("[INFO] Applying \(game.prelaunchPatches.count) pre-launch patches…")

        for patch in game.prelaunchPatches {
            do {
                try patch.apply(log: logStore)
            } catch {
                logStore?.append("[WARN] Failed to apply patch \(patch.id): \(error.localizedDescription)")
            }
        }
    }
}
