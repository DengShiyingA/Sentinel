import Foundation

struct WidgetState: Codable {
    let isConnected: Bool
    let pendingCount: Int
    let resolvedCount: Int
    let latestToolName: String?
    let latestPath: String?
    let latestRiskLevel: String?
    let updatedAt: Date

    static let appGroupId = "group.com.sentinel.ios"
    static let userDefaultsKey = "sentinel.widgetState"

    static func read() -> WidgetState? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: userDefaultsKey),
              let state = try? JSONDecoder().decode(WidgetState.self, from: data) else {
            return nil
        }
        return state
    }

    func write() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.userDefaultsKey)
    }
}
