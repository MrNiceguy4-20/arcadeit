import Foundation

struct ContraGameProfileFactory {

    static func makeContraProfile(baseFolder: String) -> ArcadeGameProfile {
        let workingDir = baseFolder

        let windowsBase = baseFolder.replacingOccurrences(of: "/", with: "\\")
        let exePath = "Z:" + windowsBase + "\\AMContra.exe"

        let configPath = baseFolder + "/data/config.ini"

        let windowedPatch = PrelaunchPatch(
            description: "Set Contra fullscreen=0 (force windowed mode)",
            type: .replaceTextInFile,
            targetPath: configPath,
            searchText: "fullscreen=1",
            replacementText: "fullscreen=0"
        )

        return ArcadeGameProfile(
            name: "Contra: Evolution (Arcade)",
            executablePath: exePath,
            workingDirectory: workingDir,
            arguments: [],
            notes: "Konami PC-based arcade build. Requires DirectX9 and windowed mode.",
            coverImageName: "contra_cover",
            coverImageURL: nil,
            forceFullscreen: false,
            forceWindowed: true,
            overrideResolution: true,
            resolutionWidth: 1280,
            resolutionHeight: 720,
            usePerGamePrefix: true,
            prelaunchPatches: [windowedPatch],
            inputMapping: .contraDefault
        )
    }
}
