import SwiftUI
import UniformTypeIdentifiers

struct ImportWizardView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onImport: ([ArcadeGameProfile]) -> Void
    
    @State private var isImporterPresented = false
    @State private var foundGames: [ArcadeGameProfile] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Arcade Games")
                .font(.title2)
            
            Text("Choose a folder containing Windows arcade game executables (.exe). We'll scan it and create basic profiles.")
                .font(.subheadline)
            
            Button {
                isImporterPresented = true
            } label: {
                Label("Choose Folder…", systemImage: "folder")
            }
            
            if !foundGames.isEmpty {
                Text("Found \(foundGames.count) executables:")
                    .font(.headline)
                    .padding(.top)
                
                List(foundGames) { game in
                    VStack(alignment: .leading) {
                        Text(game.name).bold()
                        Text(game.executablePath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    Button("Import") {
                        onImport(foundGames)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            } else {
                Spacer()
            }
        }
        .padding()
        .frame(width: 600, height: 400)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [UTType.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let folderURL = urls.first {
                    scanFolderForExecutables(folderURL: folderURL)
                }
            case .failure(let error):
                print("File import failed: \(error)")
            }
        }
    }
    
    private func scanFolderForExecutables(folderURL: URL) {
        var profiles: [ArcadeGameProfile] = []
        let fm = FileManager.default
        
        guard let enumerator = fm.enumerator(at: folderURL, includingPropertiesForKeys: nil) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "exe" {
                
                // Known arcade PC titles can be special-cased here
                let exeName = fileURL.lastPathComponent.lowercased()
                
                if exeName == "amcontra.exe" {
                    let contraProfile = ContraGameProfileFactory.makeContraProfile(
                        baseFolder: fileURL.deletingLastPathComponent().path
                    )
                    profiles.append(contraProfile)
                    continue
                }
                
                // Future: other arcade games
                // if exeName == "hod4.exe" { ... }
                
                let name = fileURL.deletingPathExtension().lastPathComponent
                let workingDir = fileURL.deletingLastPathComponent().path
                let windowsStylePath = "Z:" +
                    workingDir.replacingOccurrences(of: "/", with: "\\") +
                    "\\\(fileURL.lastPathComponent)"
                
                let profile = ArcadeGameProfile(
                    name: name,
                    executablePath: windowsStylePath,
                    workingDirectory: workingDir
                )
                profiles.append(profile)
            }
        }
        
        foundGames = profiles
    }
}
