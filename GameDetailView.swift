import SwiftUI

struct GameDetailView: View {
    @Binding var game: ArcadeGameProfile
    var onSave: (ArcadeGameProfile) -> Void

    @EnvironmentObject var logStore: LogStore
    @State private var showPatchManager = false
    @State private var showInputMappingEditor = false

    var body: some View {
        Form {
            Section(header: Text("General")) {
                TextField("Game Name", text: $game.name)
                    .textFieldStyle(.roundedBorder)

                TextField("Executable Path", text: $game.executablePath)
                    .textFieldStyle(.roundedBorder)

                TextField("Working Directory", text: $game.workingDirectory)
                    .textFieldStyle(.roundedBorder)

                TextField(
                    "Arguments",
                    text: Binding(
                        get: { game.arguments.joined(separator: " ") },
                        set: { game.arguments = $0.split(separator: " ").map(String.init) }
                    )
                )
                .textFieldStyle(.roundedBorder)

                TextField(
                    "Notes",
                    text: Binding(
                        get: { game.notes ?? "" },
                        set: { game.notes = $0 }
                    )
                )
                .textFieldStyle(.roundedBorder)
            }

            Section(header: Text("Display")) {
                Toggle("Force Fullscreen", isOn: $game.forceFullscreen)
                Toggle("Force Windowed", isOn: $game.forceWindowed)
                Toggle("Override Resolution", isOn: $game.overrideResolution)

                HStack {
                    Text("Width")
                    TextField("", value: $game.resolutionWidth, formatter: NumberFormatter())
                        .frame(width: 60)
                    Text("Height")
                    TextField("", value: $game.resolutionHeight, formatter: NumberFormatter())
                        .frame(width: 60)
                }
            }

            Section(header: Text("Wine Prefix")) {
                Toggle("Use Per-Game Prefix", isOn: $game.usePerGamePrefix)

                if game.usePerGamePrefix {
                    Button("Create / Repair Prefix") {
                        PrefixManager.initOrRepairPrefix(for: game, log: logStore)
                    }
                }
            }

            Section(header: Text("Artwork")) {
                TextField(
                    "Cover Image Name",
                    text: Binding(
                        get: { game.coverImageName ?? "" },
                        set: { game.coverImageName = $0 }
                    )
                )
            }

            Section(header: Text("Input Mapping")) {
                Button("Edit Input Mapping") {
                    if game.inputMapping == nil {
                        game.inputMapping = InputMapping.contraDefault
                    }
                    showInputMappingEditor = true
                }
            }

            Section(header: Text("Prelaunch Patches")) {
                Button("Manage Patches") {
                    showPatchManager = true
                }
            }

            Button("Save Changes") {
                onSave(game)
            }
        }
        .padding()
        .id(game.id)
        .sheet(isPresented: $showPatchManager) {
            PatchManagerView(patches: $game.prelaunchPatches)
                .environmentObject(logStore)
        }
        .sheet(isPresented: $showInputMappingEditor) {
            InputMappingEditorView(mapping:
                Binding(
                    get: { game.inputMapping ?? InputMapping.contraDefault },
                    set: { game.inputMapping = $0 }
                )
            )
        }
    }
}
