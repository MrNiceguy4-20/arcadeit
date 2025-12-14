import Foundation

struct PrelaunchPatch: Identifiable, Codable, Hashable {
    
    enum PatchType: String, Codable {
        case replaceTextInFile
    }
    
    let id: UUID
    var description: String
    var type: PatchType
    
    var targetPath: String
    var searchText: String?
    var replacementText: String?
    
    init(
        id: UUID = UUID(),
        description: String,
        type: PatchType,
        targetPath: String,
        searchText: String? = nil,
        replacementText: String? = nil
    ) {
        self.id = id
        self.description = description
        self.type = type
        self.targetPath = targetPath
        self.searchText = searchText
        self.replacementText = replacementText
    }
    
    func apply(log: LogStore?) throws {
        switch type {
        case .replaceTextInFile:
            try applyReplaceTextInFile(log: log)
        }
    }
    
    private func applyReplaceTextInFile(log: LogStore?) throws {
        guard let search = searchText, let replace = replacementText else { return }
        
        let url = URL(fileURLWithPath: targetPath)
        let data = try Data(contentsOf: url)
        guard var contents = String(data: data, encoding: .utf8) else {
            log?.append("[PATCH] File not UTF-8: \(targetPath)")
            return
        }
        
        let original = contents
        contents = contents.replacingOccurrences(of: search, with: replace)
        
        if contents != original {
            try contents.data(using: .utf8)?.write(to: url)
            log?.append("[PATCH] \(description): SUCCESS")
        } else {
            log?.append("[PATCH] \(description): no changes needed")
        }
    }
}
