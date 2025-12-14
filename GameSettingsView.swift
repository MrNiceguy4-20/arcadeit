//
//  GameSettingsView.swift
//  arcadeit
//

import SwiftUI

struct GameSettingsView: View {

    @Binding var game: ArcadeGameProfile

    var body: some View {
        Form {

            // ----------------------------------
            // Game Info
            // ----------------------------------
            Section(header: Text("Game")) {
                TextField("Name", text: $game.name)

                if game.detectedGame != .unknown {
                    Text("Detected: \(game.detectedGame.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextEditor(text: Binding(
                    get: { game.notes ?? "" },
                    set: { game.notes = $0 }
                ))
                .frame(height: 80)
            }

            // ----------------------------------
            // Launch Settings
            // ----------------------------------
            Section(header: Text("Launch")) {
                TextField("Executable Path", text: $game.executablePath)
                TextField("Working Directory", text: $game.workingDirectory)
            }

            // ----------------------------------
            // Wine (Per-Game)
            // ----------------------------------
            Section(header: Text("Wine")) {
                Toggle("Use Per-Game Prefix", isOn: $game.usePerGamePrefix)

                if game.usePerGamePrefix {
                    TextField(
                        "Wine Prefix Path",
                        text: Binding(
                            get: { game.winePrefixPath ?? "" },
                            set: { game.winePrefixPath = $0 }
                        )
                    )
                }

                Toggle("Disable winemenubuilder", isOn: $game.disableWineMenuBuilder)
                Toggle("Silent Wine (WINEDEBUG=-all)", isOn: $game.silentWine)
            }

            // ----------------------------------
            // Winetricks (Per Game)
            // ----------------------------------
            Section(header: Text("Winetricks")) {

                let grouped = Dictionary(
                    grouping: WinetricksVerb.allCases,
                    by: { $0.category }
                )

                ForEach(grouped.keys.sorted(), id: \.self) { category in
                    DisclosureGroup(category) {
                        ForEach(grouped[category]!) { verb in
                            Toggle(
                                verb.displayName,
                                isOn: Binding(
                                    get: {
                                        game.winetricksVerbs.contains(verb)
                                    },
                                    set: { enabled in
                                        if enabled {
                                            game.winetricksVerbs.insert(verb)
                                        } else {
                                            game.winetricksVerbs.remove(verb)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }

            // ----------------------------------
            // Input Mapping
            // ----------------------------------
            if let mapping = game.inputMapping {
                Section(header: Text("Input Mapping")) {
                    Text("Start: \(mapping.startKeyCode)")
                    Text("Coin: \(mapping.coinKeyCode)")
                }
            }
        }
        .padding()
        .frame(minWidth: 520)
    }
}
