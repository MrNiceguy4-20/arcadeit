//
//  GameLibraryStore.swift
//  arcadeit
//

import Foundation
import Combine

final class GameLibraryStore: ObservableObject {

    @Published var games: [ArcadeGameProfile] = []

    private let saveURL: URL = {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        .appendingPathComponent("ArcadeLauncher")
        .appendingPathComponent("games.json")
    }()

    init() {
        load()
    }

    func addGame(_ game: ArcadeGameProfile) {
        games.append(game)
        save()
    }

    func save() {
        try? FileManager.default.createDirectory(
            at: saveURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if let data = try? JSONEncoder().encode(games) {
            try? data.write(to: saveURL)
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode(
                [ArcadeGameProfile].self,
                from: data
              )
        else { return }

        games = decoded
    }
}
