import SwiftUI
import AppKit

struct ArcadeFrontendView: View {
    @ObservedObject var store: GameLibraryStore
    @EnvironmentObject var logStore: LogStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIndex: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Arcade Mode")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)

                Spacer()

                if store.games.isEmpty {
                    Text("No games available")
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    var game = store.games[selectedIndex]

                    VStack(spacing: 16) {
                        coverImage(for: game)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 260)
                            .shadow(radius: 10)

                        Text(game.name)
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        if let notes = game.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            launch(game: &game)
                        } label: {
                            Text("PLAY")
                                .font(.title3.bold())
                                .padding(.horizontal, 50)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                }

                Spacer()

                HStack {
                    Button("⟵ Previous") { moveSelection(-1) }
                    Button("Next ⟶") { moveSelection(1) }
                }
                .foregroundColor(.white)

                Button("Exit Arcade Mode") {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                    dismiss()
                }
                .padding(.bottom, 30)
            }
        }
        .transaction { tx in tx.disablesAnimations = true }
    }

    private func moveSelection(_ delta: Int) {
        guard !store.games.isEmpty else { return }
        let count = store.games.count
        selectedIndex = (selectedIndex + delta + count) % count
    }

    private func coverImage(for game: ArcadeGameProfile) -> Image {
        if let name = game.coverImageName,
           let img = NSImage(named: name) {
            return Image(nsImage: img)
        }
        return Image(systemName: "rectangle.on.rectangle")
    }

    private func launch(game: inout ArcadeGameProfile) {
        do {
            try GameLauncher.shared.launch(game: &game)
            store.save()
        } catch {
            logStore.append("[ERROR] Failed to launch: \(error)")
        }
    }

}
