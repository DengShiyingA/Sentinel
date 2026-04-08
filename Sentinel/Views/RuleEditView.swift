import SwiftUI

struct RuleEditView: View {
    @Environment(\.dismiss) private var dismiss

    let existingRule: CustomRule?
    let onSave: (CustomRule) -> Void

    @State private var toolType: ToolType
    @State private var pathPattern: String
    @State private var riskLevel: RiskOption
    @State private var description: String

    init(rule: CustomRule? = nil, onSave: @escaping (CustomRule) -> Void) {
        self.existingRule = rule
        self.onSave = onSave
        _toolType = State(initialValue: rule.map { ToolType.from($0.toolPattern) } ?? .all)
        _pathPattern = State(initialValue: rule?.pathPattern ?? "")
        _riskLevel = State(initialValue: rule.map { RiskOption.from($0.risk) } ?? .confirm)
        _description = State(initialValue: rule?.description ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "工具类型")) {
                    Picker(String(localized: "工具"), selection: $toolType) {
                        ForEach(ToolType.allCases) { type in
                            Label(type.label, systemImage: type.systemImage).tag(type)
                        }
                    }
                }

                Section(String(localized: "路径匹配")) {
                    TextField(String(localized: "如 *.env, /secrets/*（可选）"), text: $pathPattern)
                        .font(.body.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } footer: {
                    Text(String(localized: "留空表示匹配所有路径，支持 * 和 ** 通配符"))
                }

                Section(String(localized: "风险等级")) {
                    Picker(String(localized: "操作"), selection: $riskLevel) {
                        ForEach(RiskOption.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section(String(localized: "描述")) {
                    TextField(String(localized: "规则用途说明"), text: $description)
                }
            }
            .navigationTitle(existingRule == nil ? String(localized: "新建规则") : String(localized: "编辑规则"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "取消")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "保存")) {
                        let rule = CustomRule(
                            id: existingRule?.id ?? UUID().uuidString,
                            toolPattern: toolType.pattern,
                            pathPattern: pathPattern.isEmpty ? nil : pathPattern,
                            risk: riskLevel.riskString,
                            description: description.isEmpty ? toolType.label : description
                        )
                        onSave(rule)
                        dismiss()
                    }
                    .disabled(description.isEmpty && toolType == .all && pathPattern.isEmpty)
                }
            }
        }
    }
}

// MARK: - Tool Type Picker Options

enum ToolType: String, CaseIterable, Identifiable {
    case read = "Read"
    case write = "Write"
    case edit = "Edit"
    case bash = "Bash"
    case grep = "Grep"
    case glob = "Glob"
    case all = "*"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .read:  String(localized: "Read（文件读取）")
        case .write: String(localized: "Write（文件写入）")
        case .edit:  String(localized: "Edit（文件编辑）")
        case .bash:  String(localized: "Bash（终端命令）")
        case .grep:  String(localized: "Grep（内容搜索）")
        case .glob:  String(localized: "Glob（文件搜索）")
        case .all:   String(localized: "全部工具")
        }
    }

    var systemImage: String {
        switch self {
        case .read:  "doc.text"
        case .write: "doc.badge.plus"
        case .edit:  "pencil.line"
        case .bash:  "terminal"
        case .grep:  "magnifyingglass"
        case .glob:  "folder.badge.magnifyingglass"
        case .all:   "gearshape"
        }
    }

    var pattern: String? {
        self == .all ? nil : rawValue
    }

    static func from(_ pattern: String?) -> ToolType {
        guard let pattern else { return .all }
        return ToolType(rawValue: pattern) ?? .all
    }
}

// MARK: - Risk Level Picker Options

enum RiskOption: String, CaseIterable, Identifiable {
    case allow = "auto_allow"
    case confirm = "require_confirm"
    case faceid = "require_faceid"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allow:   String(localized: "自动允许")
        case .confirm: String(localized: "需要确认")
        case .faceid:  String(localized: "需要 Face ID")
        }
    }

    var riskString: String { rawValue }

    static func from(_ risk: String) -> RiskOption {
        RiskOption(rawValue: risk) ?? .confirm
    }
}
