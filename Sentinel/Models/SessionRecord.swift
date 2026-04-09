import Foundation

struct SessionRecord: Identifiable, Codable {
    let id: String
    let startedAt: Date
    let endedAt: Date
    let summary: String
    let filesModified: [String]
    let approvalCount: Int
    let isError: Bool

    static let storageKey = "sentinel.sessionRecords"
    static let maxRecords = 50

    static func load() -> [SessionRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let records = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
            return []
        }
        return records
    }

    static func save(_ records: [SessionRecord]) {
        let trimmed = Array(records.prefix(maxRecords))
        guard let data = try? JSONEncoder().encode(trimmed) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func append(_ record: SessionRecord) {
        var records = load()
        records.insert(record, at: 0)
        save(records)
    }
}
