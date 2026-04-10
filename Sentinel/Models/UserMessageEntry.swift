// Sentinel/Models/UserMessageEntry.swift
import Foundation

enum UserMessageStatus {
    case pending   // Queued, waiting for Claude to stop
    case sent      // Claude resumed with this message
}

struct UserMessageEntry: Identifiable {
    let id: String
    let text: String
    let sentAt: Date
    var status: UserMessageStatus

    init(text: String) {
        self.id = UUID().uuidString
        self.text = text
        self.sentAt = Date()
        self.status = .pending
    }
}
