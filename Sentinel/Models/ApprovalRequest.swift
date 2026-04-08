import Foundation

// MARK: - Risk Level

enum RiskLevel: String, Codable, CaseIterable, Identifiable {
    case requireConfirm = "require_confirm"
    case requireFaceID = "require_faceid"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .requireConfirm: String(localized: "需要确认")
        case .requireFaceID: String(localized: "需要 Face ID")
        }
    }

    var systemImage: String {
        switch self {
        case .requireConfirm: "questionmark.circle.fill"
        case .requireFaceID: "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Decision

enum Decision: String, Codable {
    case allowed
    case blocked
}

// MARK: - Approval Request

struct ApprovalRequest: Identifiable, Codable, Equatable {
    let id: String
    let toolName: String
    let toolInput: [String: AnyCodable]
    let riskLevel: RiskLevel
    let timestamp: Date
    let macDeviceId: String
    let timeoutAt: Date

    var remainingSeconds: TimeInterval {
        max(0, timeoutAt.timeIntervalSinceNow)
    }

    var isExpired: Bool {
        remainingSeconds <= 0
    }

    static func == (lhs: ApprovalRequest, rhs: ApprovalRequest) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AnyCodable (type-erased Codable wrapper)

struct AnyCodable: Codable, Equatable, CustomStringConvertible {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }

    var description: String {
        switch value {
        case is NSNull: "null"
        case let v as CustomStringConvertible: v.description
        default: "\(value)"
        }
    }

    /// Pretty-print JSON representation
    var prettyJSON: String {
        guard let data = try? JSONEncoder.sentinelEncoder.encode(self),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else {
            return description
        }
        return str
    }
}

// MARK: - JSON Encoder/Decoder helpers

extension JSONEncoder {
    static let sentinelEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let sentinelDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
