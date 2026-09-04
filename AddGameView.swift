import SwiftUI

struct AddGameView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var exePath = ""
    @State private var workingDir = ""
    @State private var args = ""

    let onSave: (ArcadeGameProfile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Arcade Game")
                .font(.title2)

            TextField("Name", text: $name)
            TextField("Executable path (Wine Z: path)", text: $exePath)
            TextField("Working directory (macOS path)", text: $workingDir)
            TextField("Arguments (space-separated)", text: $args)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    let game = ArcadeGameProfile(
                        name: name,
                        executablePath: exePath,
                        workingDirectory: workingDir,
                        arguments: args.split(separator: " ").map(String.init)
                    )
                    onSave(game)
                    dismiss()
                }
                .disabled(name.isEmpty || exePath.isEmpty || workingDir.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
