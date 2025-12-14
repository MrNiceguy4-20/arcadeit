//
//  ContentView.swift
//  arcadeit
//

import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var settingsStore: RuntimeSettingsStore
    @EnvironmentObject var logStore: LogStore
    @StateObject private var store = GameLibraryStore()
    
    @State private var selectedGameID: UUID?
    @State private var showArcadeFrontend = false
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPane
        }
        .transaction { tx in
            tx.disablesAnimations = true   // Prevent TextInput tearing
        }
        .sheet(isPresented: $showArcadeFrontend) {
            ArcadeFrontendWrapper(store: store)
                .environmentObject(logStore)
        }
    }
    
    // ---------------------------------------------------------
    // SIDEBAR: Game List
    // ---------------------------------------------------------
    var sidebar: some View {
        List(selection: $selectedGameID) {
            ForEach(store.games) { game in
                Text(game.name).tag(game.id as UUID?)
            }
            .onDelete { offsets in
                store.games.remove(atOffsets: offsets)
                store.save()
            }
        }
        .frame(minWidth: 220)
        .toolbar {
            ToolbarItemGroup {
                
                Button(action: addGame) {
                    Label("Add Game", systemImage: "plus")
                }
                
                Button(action: importGameFromFolder) {
                    Label("Import Game", systemImage: "folder.badge.plus")
                }
                
                Button(action: { store.save() }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                
                Button(action: { showArcadeFrontend = true }) {
                    Label("Arcade Mode", systemImage: "rectangle.expand.vertical")
                }
            }
        }
    }
    
    // ---------------------------------------------------------
    // DETAIL: Game Editor Pane
    // ---------------------------------------------------------
    var detailPane: some View {
        VStack {
            if let selectedID = selectedGameID,
               let index = store.games.firstIndex(where: { $0.id == selectedID }) {
                
                let gameBinding = Binding<ArcadeGameProfile>(
                    get: { store.games[index] },
                    set: { newValue in
                        store.games[index] = newValue
                        store.save()
                    }
                )
                
                GameDetailView(
                    game: gameBinding,
                    onSave: { _ in
                        store.save()
                        logStore.append("[INFO] Saved game changes.")
                    }
                )
                .id(store.games[index].id)
                
            } else {
                Text("Select a game or add one.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .padding()
    }
    
    // ---------------------------------------------------------
    // ADD NEW EMPTY GAME
    // ---------------------------------------------------------
    func addGame() {
        let new = ArcadeGameProfile(
            name: "New Game",
            executablePath: "",
            workingDirectory: ""
        )
        store.games.append(new)
        store.save()
        selectedGameID = new.id
        logStore.append("[INFO] Created new empty game profile.")
    }
    
    // ---------------------------------------------------------
    // IMPORT GAME FROM FOLDER (AUTODETECT .EXE)
    // ---------------------------------------------------------
    func importGameFromFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Game Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        
        if panel.runModal() == .OK, let folderURL = panel.url {
            let fm = FileManager.default
            let folderPath = folderURL.path
            
            var foundExeURL: URL? = nil
            
            if let enumerator = fm.enumerator(at: folderURL, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension.lowercased() == "exe" {
                        foundExeURL = fileURL
                        break
                    }
                }
            }
            
            let gameName: String
            let executablePath: String
            let workingDir: String
            
            if let exeURL = foundExeURL {
                gameName = exeURL.deletingPathExtension().lastPathComponent
                executablePath = exeURL.path
                workingDir = exeURL.deletingLastPathComponent().path
                logStore.append("[INFO] Detected executable: \(executablePath)")
            } else {
                // Fallback: no exe found, use folder as base
                gameName = folderURL.lastPathComponent
                executablePath = ""
                workingDir = folderPath
                logStore.append("[WARN] No .exe found in \(folderPath). Created shell profile.")
            }
            
            let newGame = ArcadeGameProfile(
                name: gameName,
                executablePath: executablePath,
                workingDirectory: workingDir
            )
            
            store.games.append(newGame)
            store.save()
            selectedGameID = newGame.id
            
            logStore.append("[INFO] Imported game '\(gameName)' from \(folderPath)")
        }
    }
}

// -------------------------------------------------------------
// FULLSCREEN ARCADE MODE WRAPPER (macOS-safe)
// -------------------------------------------------------------
struct ArcadeFrontendWrapper: View {
    @ObservedObject var store: GameLibraryStore
    @EnvironmentObject var logStore: LogStore
    
    var body: some View {
        ArcadeFrontendView(store: store)
            .environmentObject(logStore)
            .onAppear {
                DispatchQueue.main.async {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                }
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(RuntimeSettingsStore())
        .environmentObject(LogStore())
}
