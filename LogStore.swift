
import Foundation
import Combine

final class LogStore: ObservableObject {
    @Published var entries: [LogEntry] = []

    func append(_ text: String) {
        DispatchQueue.main.async {
            self.entries.append(LogEntry(text: text))
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.entries.removeAll()
        }
    }
}
