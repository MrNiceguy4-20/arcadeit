
import SwiftUI

struct LogView: View {
    @EnvironmentObject var logStore: LogStore

    @State private var searchText = ""
    @State private var showTimestamps = true
    @State private var selectedLevel: LogLevelFilter = .all

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Picker("Level", selection: $selectedLevel) {
                    ForEach(LogLevelFilter.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)

                TextField("Search logs…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)

                Button {
                    logStore.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Clear all logs")
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            .border(Color.gray.opacity(0.25), width: 1)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredLogs) { entry in
                            LogLineView(entry: entry, showTimestamps: showTimestamps)
                                .id(entry.id)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .background(Color.black.opacity(0.85))
                .onAppear {
                    if let last = logStore.entries.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: logStore.entries) {
                    if let last = logStore.entries.last {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                Toggle("Show timestamps", isOn: $showTimestamps)
                    .toggleStyle(.switch)

                Spacer()

                Text("\(logStore.entries.count) entries")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(6)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 350)
    }

    var filteredLogs: [LogEntry] {
        logStore.entries.filter { entry in

            switch selectedLevel {
            case .all: break
            case .info: if !entry.text.contains("[INFO]") { return false }
            case .warn: if !entry.text.contains("[WARN]") { return false }
            case .error: if !entry.text.contains("[ERROR]") { return false }
            }

            if !searchText.isEmpty &&
                !entry.text.localizedCaseInsensitiveContains(searchText)
            {
                return false
            }

            return true
        }
    }
}

enum LogLevelFilter: String, CaseIterable {
    case all = "All"
    case info = "Info"
    case warn = "Warn"
    case error = "Error"
}

struct LogLineView: View {
    let entry: LogEntry
    let showTimestamps: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if showTimestamps {
                Text(entry.timestamp)
                    .foregroundColor(.gray)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .frame(width: 80, alignment: .leading)
            }

            Text(entry.text)
                .foregroundColor(levelColor(entry.text))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    func levelColor(_ text: String) -> Color {
        if text.contains("[ERROR]") { return .red }
        if text.contains("[WARN]")  { return .orange }
        if text.contains("[INFO]")  { return .cyan }
        return .white
    }
}

#Preview {
    LogView()
        .environmentObject(LogStore())
}
