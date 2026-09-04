
import Foundation

enum WineInstallerExtraction {

    static func extract(
        archiveURL: URL,
        destination: URL,
        log: LogStore?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        log?.append("[EXTRACT] Attempting tar extraction (content-based)")

        extractTar(archiveURL, destination, ["-xJf"], log) { result in
            if case .success = result {
                completion(.success(()))
                return
            }

            extractTar(archiveURL, destination, ["-xzf"], log) { result in
                if case .success = result {
                    completion(.success(()))
                    return
                }

                extractZip(archiveURL, destination, log) { result in
                    if case .success = result {
                        completion(.success(()))
                    } else {
                        completion(.failure(
                            NSError(
                                domain: "WineInstallerExtraction",
                                code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Unsupported or corrupted Wine archive"
                                ]
                            )
                        ))
                    }
                }
            }
        }
    }

    private static func extractTar(
        _ archive: URL,
        _ dest: URL,
        _ flags: [String],
        _ log: LogStore?,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        log?.append("[EXTRACT] Using tar \(flags.joined(separator: " "))")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = flags + [archive.path, "-C", dest.path]

        pipeAndRun(process, log, completion)
    }

    private static func extractZip(
        _ archive: URL,
        _ dest: URL,
        _ log: LogStore?,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        log?.append("[EXTRACT] Using unzip")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", archive.path, "-d", dest.path]

        pipeAndRun(process, log, completion)
    }

    private static func pipeAndRun(
        _ process: Process,
        _ log: LogStore?,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { fh in
            let data = fh.availableData
            guard
                !data.isEmpty,
                let text = String(data: data, encoding: .utf8)
            else { return }

            DispatchQueue.main.async {
                log?.append("[EXTRACT] \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }

        func succeed() {
            completion(.success(()))
        }

        func fail(_ error: Error) {
            completion(.failure(error))
        }

        process.terminationHandler = { (_: Process) in
            let status = process.terminationStatus
            DispatchQueue.main.async {
                if status == 0 {
                    succeed()
                } else {
                    fail(
                        NSError(
                            domain: "WineInstallerExtraction",
                            code: Int(status),
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                "Extraction failed (exit \(status))"
                            ]
                        )
                    )
                }
            }
        }

        do {
            try process.run()
        } catch {
            DispatchQueue.main.async {
                fail(error)
            }
        }
    }
}
