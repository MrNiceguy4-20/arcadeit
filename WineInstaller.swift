//
//  WineInstaller.swift
//  arcadeit
//

import Foundation

final class WineInstaller {
    
    // MARK: - Download sources for Gecko / Mono
    
    private struct GeckoMonoConfig {
        static let monoURL =
        URL(string: "https://dl.winehq.org/wine/wine-mono/9.0.0/wine-mono-9.0.0-x86.msi")!
        
        static let gecko32URL =
        URL(string: "https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86.msi")!
        
        static let gecko64URL =
        URL(string: "https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi")!
    }
    
    // Result returned after installing wine
    struct InstallResult {
        let wineBinaryPath: String
    }
    
    // ------------------------------------------------------
    // MARK: - Verify + Auto-Repair
    // ------------------------------------------------------
    
    static func verifyAndRepairWine(
        wineBinaryPath: String,
        log: LogStore?
    ) -> String? {
        
        if validateWineBinary(at: wineBinaryPath, log: log) {
            return wineBinaryPath
        }
        
        log?.append("[REPAIR] Wine invalid — scanning installs…")
        
        let root = WineInstallerPaths.installRoot
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        for case let url as URL in enumerator {
            let name = url.lastPathComponent.lowercased()
            if name == "wine" || name == "wine64" {
                if validateWineBinary(at: url.path, log: log) {
                    log?.append("[REPAIR] Found working Wine at \(url.path)")
                    return url.path
                }
            }
        }
        
        log?.append("[REPAIR] No valid Wine binary found")
        return nil
    }
    
    private static func validateWineBinary(
        at path: String,
        log: LogStore?
    ) -> Bool {

        // 🚫 CRITICAL: Reject macOS Wine.app launcher stub
        if path.contains("/Contents/MacOS/") {
            log?.append("[VERIFY] Rejecting invalid Wine launcher stub: \(path)")
            return false
        }

        guard FileManager.default.isExecutableFile(atPath: path) else {
            log?.append("[VERIFY] Wine binary not executable: \(path)")
            return false
        }

        let process = Process()
        process.launchPath = path
        process.arguments = ["--version"]

        // Run with minimal environment
        process.environment = [
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            "WINEDEBUG": "-all"
        ]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                log?.append("[VERIFY] Wine OK: \(path)")
                return true
            } else {
                log?.append("[VERIFY] Wine exited with status \(process.terminationStatus)")
                return false
            }

        } catch {
            log?.append("[VERIFY] Wine failed to launch: \(error.localizedDescription)")
            return false
        }
    }

    
    // ------------------------------------------------------
    // MARK: - Install Selected Wine Release (FIXED)
    // ------------------------------------------------------
    
    static func installSelectedRelease(
        release: WineRelease,
        log: LogStore?,
        progress: @escaping (Double, Int64, Int64) -> Void,
        completion: @escaping (Result<InstallResult, Error>) -> Void
    ) {
        
        let installDir = WineInstallerPaths.installRoot
        try? FileManager.default.createDirectory(at: installDir, withIntermediateDirectories: true)
        
        log?.append("[INFO] Downloading Wine build: \(release.name)")
        
        WineDownloader.shared.download(from: release.assetURL, progress: progress) { result in
            switch result {
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                
            case .success(let tempURL):
                
                // 🔑 CRITICAL FIX: copy CFNetwork temp file to stable location
                let stableArchiveURL =
                installDir.appendingPathComponent("wine_download.tar.xz")
                
                do {
                    if FileManager.default.fileExists(atPath: stableArchiveURL.path) {
                        try FileManager.default.removeItem(at: stableArchiveURL)
                    }
                    try FileManager.default.copyItem(at: tempURL, to: stableArchiveURL)
                } catch {
                    DispatchQueue.main.async {
                        log?.append("[ERROR] Failed to copy Wine archive: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                    return
                }
                
                log?.append("[INFO] Extracting Wine archive…")
                
                WineInstallerExtraction.extract(
                    archiveURL: stableArchiveURL,
                    destination: installDir,
                    log: log
                ) { extractResult in
                    
                    switch extractResult {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        
                    case .success:
                        guard let winePath =
                                WineInstallerPaths.findWineBinary(in: installDir),
                              validateWineBinary(at: winePath, log: log)
                        else {
                            completion(.failure(
                                NSError(
                                    domain: "WineInstaller",
                                    code: 404,
                                    userInfo: [NSLocalizedDescriptionKey: "Wine binary not found"]
                                )
                            ))
                            return
                        }
                        
                        DispatchQueue.main.async {
                            completion(.success(.init(wineBinaryPath: winePath)))
                        }
                    }
                }
            }
        }
    }
    
    // ------------------------------------------------------
    // MARK: - Setup Default Prefix
    // ------------------------------------------------------
    
    static func setupDefaultPrefix(
        wineBinaryPath: String,
        prefix: String,
        log: LogStore?
    ) {
        
        guard let wine = verifyAndRepairWine(
            wineBinaryPath: wineBinaryPath,
            log: log
        ) else {
            log?.append("[PREFIX] Aborted — Wine invalid")
            return
        }
        
        if FileManager.default.fileExists(atPath: prefix) {
            log?.append("[PREFIX] Prefix already exists — skipping wineboot")
            return
        }
        
        try? FileManager.default.createDirectory(atPath: prefix, withIntermediateDirectories: true)
        
        runProcessAndWait(
            launchPath: wine,
            arguments: ["wineboot", "--init"],
            extraEnv: ["WINEPREFIX": prefix],
            logPrefix: "[PREFIX] ",
            log: log
        )
    }
    
    // ------------------------------------------------------
    // MARK: - Gecko + Mono Install
    // ------------------------------------------------------
    
    static func installGeckoAndMono(
        wineBinaryPath: String,
        prefix: String,
        log: LogStore?
    ) {
        
        guard let wine = verifyAndRepairWine(
            wineBinaryPath: wineBinaryPath,
            log: log
        ) else {
            log?.append("[GECKO] Aborted — Wine invalid")
            return
        }
        
        downloadAndInstallMSI(
            label: "Mono",
            url: GeckoMonoConfig.monoURL,
            winePath: wine,
            winePrefix: prefix,
            logPrefix: "[MONO] ",
            log: log
        )
        
        downloadAndInstallMSI(
            label: "Gecko (x86)",
            url: GeckoMonoConfig.gecko32URL,
            winePath: wine,
            winePrefix: prefix,
            logPrefix: "[GECKO32] ",
            log: log
        )
        
        downloadAndInstallMSI(
            label: "Gecko (x86_64)",
            url: GeckoMonoConfig.gecko64URL,
            winePath: wine,
            winePrefix: prefix,
            logPrefix: "[GECKO64] ",
            log: log
        )
    }
    
    private static func downloadAndInstallMSI(
        label: String,
        url: URL,
        winePath: String,
        winePrefix: String,
        logPrefix: String,
        log: LogStore?
    ) {
        WineDownloader.shared.download(from: url, progress: { pct, _, _ in
            log?.append("\(logPrefix)\(label) \(Int(pct * 100))%")
        }) { result in
            switch result {
            case .failure(let error):
                log?.append("[ERROR] \(label) failed: \(error.localizedDescription)")
            case .success(let tempURL):
                runProcessAndWait(
                    launchPath: winePath,
                    arguments: ["msiexec", "/i", tempURL.path],
                    extraEnv: ["WINEPREFIX": winePrefix],
                    logPrefix: logPrefix,
                    log: log
                )
            }
        }
    }
    
    // ------------------------------------------------------
    // MARK: - Process Runner
    // ------------------------------------------------------
    
    static func runProcessAndWait(
        launchPath: String,
        arguments: [String],
        extraEnv: [String: String]?,
        logPrefix: String,
        log: LogStore?
    ) {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments
        
        var env = ProcessInfo.processInfo.environment
        extraEnv?.forEach { env[$0.key] = $0.value }
        process.environment = env
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        pipe.fileHandleForReading.readabilityHandler = { fh in
            let data = fh.availableData
            guard let text = String(data: data, encoding: .utf8),
                  !text.isEmpty else { return }
            
            DispatchQueue.main.async {
                log?.append("\(logPrefix)\(text.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            log?.append("[ERROR] Failed to run \(launchPath): \(error.localizedDescription)")
        }
        
        pipe.fileHandleForReading.readabilityHandler = nil
    }
}
