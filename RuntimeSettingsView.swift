//
//  RuntimeSettingsView.swift
//  arcadeit
//

import SwiftUI

struct RuntimeSettingsView: View {
    @ObservedObject var store: RuntimeSettingsStore
    @EnvironmentObject var logStore: LogStore
    
    @StateObject private var wineReleases = WineReleases()
    
    @State private var selectedRelease: WineRelease? = nil
    @State private var installing = false
    
    // Download progress
    @State private var downloadProgress: Double = 0.0
    @State private var downloadedBytes: Int64 = 0
    @State private var totalBytes: Int64 = 0
    
    // Status indicators
    @State private var prefixExists = false
    @State private var wineStatus: WineStatus = .unknown
    @State private var repairingWine = false
    
    var body: some View {
        Form {
            
            // ----------------------------------------------------
            // SECTION: Wine Status
            // ----------------------------------------------------
            Section(header: Text("Wine Status")) {
                HStack {
                    WineStatusBadge(status: wineStatus)
                    Spacer()
                    Button("Repair Wine") {
                        repairWine()
                    }
                    .disabled(repairingWine)
                }
            }
            
            // ----------------------------------------------------
            // SECTION: Wine Versions from GitHub
            // ----------------------------------------------------
            Section(header: Text("Wine-GE Versions (from GitHub)")) {
                
                if wineReleases.loading {
                    ProgressView("Loading releases…")
                } else {
                    Picker("Available Wine Builds", selection: $selectedRelease) {
                        
                        Text("Select a Wine version…")
                            .tag(Optional<WineRelease>.none)
                        
                        ForEach(wineReleases.releases) { release in
                            Text(release.name)
                                .tag(Optional(release))
                        }
                    }
                }
                
                Button("Refresh Releases") {
                    wineReleases.fetch()
                }
            }
            
            // ----------------------------------------------------
            // SECTION: Install Selected Version
            // ----------------------------------------------------
            Section(header: Text("Download & Install Wine-GE")) {
                
                Button("Download & Install Selected Version") {
                    startInstall()
                }
                .disabled(selectedRelease == nil || installing)
                .buttonStyle(.borderedProminent)
                
                if installing {
                    VStack(alignment: .leading) {
                        ProgressView(value: downloadProgress)
                            .padding(.bottom, 4)
                        Text("\(formatBytes(downloadedBytes)) / \(formatBytes(totalBytes))")
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // ----------------------------------------------------
            // SECTION: Current Wine path
            // ----------------------------------------------------
            Section(header: Text("Current Wine Binary Path")) {
                TextField("Wine Binary Path", text: $store.settings.wineBinaryPath)
                    .textFieldStyle(.roundedBorder)
            }
            // ----------------------------------------------------
            // SECTION: Winetricks
            // ----------------------------------------------------
            Section(header: Text("Winetricks")) {

                Button("Download / Update Winetricks") {
                    WinetricksInstaller.installOrUpdate(
                        log: logStore
                    ) { success in
                        if success {
                            logStore.append("[WINETRICKS] Ready")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Install corefonts (example)") {
                    WinetricksInstaller.run(
                        verb: "corefonts",
                        wineBinary: store.settings.wineBinaryPath,
                        prefix: store.settings.winePrefixPath,
                        log: logStore
                    )
                }
            }
            
            // ----------------------------------------------------
            // SECTION: Prefix
            // ----------------------------------------------------
            Section(header: Text("WINEPREFIX Settings")) {
                TextField("WINEPREFIX Path", text: $store.settings.winePrefixPath)
                    .textFieldStyle(.roundedBorder)
                
                Button("Setup Default Prefix (~/.wine)") {
                    logStore.append("[INFO] Setting up default prefix…")
                    WineInstaller.setupDefaultPrefix(
                        wineBinaryPath: store.settings.wineBinaryPath,
                        prefix: store.settings.winePrefixPath,
                        log: logStore
                    )
                    refreshStatus()
                }
                
                StatusPill(label: "Prefix Exists", ok: prefixExists)
            }
            
            // ----------------------------------------------------
            // SECTION: Gecko / Mono / Health
            // ----------------------------------------------------
            Section(header: Text("Wine Tools")) {
                
                Button("Install Gecko + Mono") {
                    logStore.append("[INFO] Installing Gecko + Mono…")
                    WineInstaller.installGeckoAndMono(
                        wineBinaryPath: store.settings.wineBinaryPath,
                        prefix: store.settings.winePrefixPath,
                        log: logStore
                    )
                }
                
                Button("Fix My Wine (Health Check)") {
                    logStore.append("[INFO] Running Wine health check…")
                    if let repaired = WineInstaller.verifyAndRepairWine(
                        wineBinaryPath: store.settings.wineBinaryPath,
                        log: logStore
                    ) {
                        store.settings.wineBinaryPath = repaired
                        store.save()
                        wineStatus = .repaired
                    } else {
                        wineStatus = .broken
                    }
                    refreshStatus()
                }
            }
            
            // ----------------------------------------------------
            // Save
            // ----------------------------------------------------
            Button("Save Settings") {
                store.save()
                logStore.append("[INFO] Settings saved.")
            }
        }
        .padding()
        .frame(width: 600)
        .onAppear {
            if store.settings.winePrefixPath.isEmpty {
                store.settings.winePrefixPath = NSHomeDirectory() + "/.wine"
            }
            refreshStatus()
            refreshWineStatus()
            wineReleases.fetch()
        }
    }
    
    // ------------------------------------------------------------
    // MARK: - INSTALL LOGIC
    // ------------------------------------------------------------
    func startInstall() {
        guard let release = selectedRelease else {
            logStore.append("[ERROR] No release selected.")
            return
        }
        
        installing = true
        downloadProgress = 0
        
        logStore.append("[INFO] Installing Wine: \(release.name)")
        
        WineInstaller.installSelectedRelease(
            release: release,
            log: logStore,
            progress: { pct, written, expected in
                DispatchQueue.main.async {
                    self.downloadProgress = pct
                    self.downloadedBytes = written
                    self.totalBytes = expected
                }
            },
            completion: { result in
                DispatchQueue.main.async {
                    installing = false
                    switch result {
                    case .failure(let error):
                        logStore.append("[ERROR] Install failed: \(error.localizedDescription)")
                        wineStatus = .broken
                    case .success(let install):
                        store.settings.wineBinaryPath = install.wineBinaryPath
                        store.save()
                        wineStatus = .valid
                        logStore.append("[SUCCESS] Wine installed at \(install.wineBinaryPath)")
                    }
                    refreshStatus()
                }
            }
        )
    }
    
    // ------------------------------------------------------------
    // MARK: - HELPERS
    // ------------------------------------------------------------
    func refreshStatus() {
        prefixExists = FileManager.default.fileExists(
            atPath: store.settings.winePrefixPath
        )
    }
    
    func refreshWineStatus() {
        wineStatus =
            WineInstaller.verifyAndRepairWine(
                wineBinaryPath: store.settings.wineBinaryPath,
                log: nil
            ) != nil ? .valid : .broken
    }
    
    func repairWine() {
        repairingWine = true
        
        if let repaired = WineInstaller.verifyAndRepairWine(
            wineBinaryPath: store.settings.wineBinaryPath,
            log: logStore
        ) {
            store.settings.wineBinaryPath = repaired
            store.save()
            wineStatus = .repaired
            logStore.append("[INFO] Wine repaired at \(repaired)")
        } else {
            wineStatus = .broken
            logStore.append("[ERROR] Wine repair failed")
        }
        
        repairingWine = false
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        if bytes <= 0 { return "0 MB" }
        let mb = Double(bytes) / 1024.0 / 1024.0
        return String(format: "%.1f MB", mb)
    }
}

// ------------------------------------------------------------
// MARK: - STATUS PILL UI COMPONENTS
// ------------------------------------------------------------

enum WineStatus {
    case valid
    case repaired
    case broken
    case unknown
}

struct WineStatusBadge: View {
    let status: WineStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(text)
                .font(.caption)
                .bold()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
    
    private var color: Color {
        switch status {
        case .valid: return .green
        case .repaired: return .yellow
        case .broken: return .red
        case .unknown: return .gray
        }
    }
    
    private var text: String {
        switch status {
        case .valid: return "Wine OK"
        case .repaired: return "Wine Repaired"
        case .broken: return "Wine Broken"
        case .unknown: return "Unknown"
        }
    }
}

struct StatusPill: View {
    let label: String
    let ok: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ok ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .bold()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.8))
        )
    }
}

#Preview {
    RuntimeSettingsView(store: RuntimeSettingsStore())
        .environmentObject(LogStore())
}
