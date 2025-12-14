//
//  LogEntry.swift
//  arcadeit
//
//  Created by kevin on 2025-12-11.
//


//
//  LogEntry.swift
//  arcadeit
//

import Foundation

struct LogEntry: Identifiable, Hashable {
    let id = UUID()
    let timestamp: String
    let text: String
    
    init(text: String) {
        self.timestamp = LogEntry.formatTimestamp(Date())
        self.text = text
    }
    
    private static func formatTimestamp(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: date)
    }
}
