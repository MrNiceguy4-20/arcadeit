
import Foundation
import Combine

final class WineReleases: ObservableObject {

    @Published var releases: [WineRelease] = []
    @Published var loading = false

    private let apiURL =
        URL(string: "https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases")!

    func fetch() {
        loading = true
        releases.removeAll()

        let task = URLSession.shared.dataTask(with: apiURL) { data, _, error in
            DispatchQueue.main.async {
                self.loading = false
            }

            if let error = error {
                print("Wine release fetch failed:", error)
                return
            }

            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode([GitHubRelease].self, from: data)

                let mapped: [WineRelease] = decoded.compactMap { (release) -> WineRelease? in

                    guard let asset = release.assets.first(where: {
                        $0.name.lowercased().hasSuffix(".tar.xz")
                    }) else {
                        return nil
                    }

                    return WineRelease(
                        id: UUID(),
                        name: release.name ?? release.tag_name,
                        tag: release.tag_name,
                        assetURL: asset.browser_download_url
                    )
                }

                DispatchQueue.main.async {
                    self.releases = mapped
                }

            } catch {
                print("Wine release JSON decode failed:", error)
            }
        }

        task.resume()
    }
}

private struct GitHubRelease: Decodable {
    let id: Int
    let tag_name: String
    let name: String?
    let assets: [GitHubAsset]
}

private struct GitHubAsset: Decodable {
    let name: String
    let browser_download_url: URL
}
