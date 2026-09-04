
import Foundation

enum GameImporter {

    static func importGame(from folder: URL) -> ArcadeGameProfile? {

        let fm = FileManager.default
        let files = (try? fm.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        )) ?? []

        let names = Set(files.map {
            $0.lastPathComponent.lowercased()
        })

        let isContra =
            names.contains("amcontra.exe") &&
            names.contains("libacio.dll") &&
            names.contains("libavs-win32.dll")

        if isContra {

            let prefix =
                NSHomeDirectory()
                + "/Library/Application Support/ArcadeLauncher/Prefixes/ContraEvolution"

            return ArcadeGameProfile(
                name: "Contra: Evolution",
                executablePath: folder
                    .appendingPathComponent("AMContra.exe").path,
                workingDirectory: folder.path,
                gameDirectory: folder.path,
                notes: "Auto-detected Contra: Evolution arcade title",
                usePerGamePrefix: true,
                winePrefixPath: prefix,
                disableWineMenuBuilder: true,
                silentWine: true,
                dllOverrides: [
                    "libacio",
                    "libavs-win32",
                    "libavs-win32-ea3"
                ],
                winetricksVerbs: [
                    .vcrun2010,
                    .vcrun2015,
                    .d3dx9
                ],
                inputMapping: .contraDefault,
                detectedGame: .contraEvolution
            )
        }

        let exe = files.first {
            $0.pathExtension.lowercased() == "exe"
        }

        return ArcadeGameProfile(
            name: exe?
                .deletingPathExtension()
                .lastPathComponent
                ?? folder.lastPathComponent,
            executablePath: exe?.path ?? "",
            workingDirectory: exe?
                .deletingLastPathComponent().path
                ?? folder.path,
            gameDirectory: folder.path,
            detectedGame: .unknown
        )
    }
}
