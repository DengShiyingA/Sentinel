import SwiftUI

// MARK: - Custom Rule Model (editable, synced to CLI)

struct CustomRule: Identifiable, Codable, Equatable {
    let id: String
    let toolPattern: String?
    let pathPattern: String?
    let risk: String         // auto_allow | require_confirm | require_faceid
    let description: String
}

// MARK: - Built-in Rule (read-only)

private struct BuiltinRule: Identifiable {
    let id = UUID()
    let toolPattern: String?
    let pathPattern: String?
    let risk: String
    let description: String
    let systemImage: String
}

// MARK: - Rules View

struct RulesView: View {
    @Environment(RelayService.self) private var relay
    @Environment(LocalDiscoveryService.self) private var local

    @State private var customRules: [CustomRule] = RulesView.loadCustomRules()
    @State private var showAddSheet = false
    @State private var editingRule: CustomRule?

    var body: some View {
        NavigationStack {
            List {
                // Built-in rules (read-only)
                Section {
                    ForEach(builtinRules) { rule in
                        BuiltinRuleRow(rule: rule)
                    }
                } header: {
                    Label(String(localized: "内置规则"), systemImage: "lock.shield")
                } footer: {
                    Text(String(localized: "内置规则不可修改，由 CLI 端管理"))
                }

                // Custom rules (editable)
                Section {
                    if customRules.isEmpty {
                        Label {
                            Text(String(localized: "暂无自定义规则"))
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "plus.circle.dashed")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(customRules) { rule in
                            CustomRuleRow(rule: rule)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingRule = rule
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteRule(rule)
                                    } label: {
                                        Label(String(localized: "删除"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                } header: {
                    Label(String(localized: "自定义规则"), systemImage: "slider.horizontal.3")
                } footer: {
                    Text(String(localized: "自定义规则会同步到 Mac 端，优先级高于内置规则"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "规则"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                RuleEditView { newRule in
                    customRules.append(newRule)
                    saveAndSync()
                }
            }
            .sheet(item: $editingRule) { rule in
                RuleEditView(rule: rule) { updated in
                    if let idx = customRules.firstIndex(where: { $0.id == updated.id }) {
                        customRules[idx] = updated
                    }
                    saveAndSync()
                }
            }
        }
    }

    // MARK: - CRUD

    private func deleteRule(_ rule: CustomRule) {
        customRules.removeAll { $0.id == rule.id }
        saveAndSync()
    }

    private func saveAndSync() {
        RulesView.saveCustomRules(customRules)
        syncToMac()
    }

    /// Send rules_update event to CLI via the active transport (works in all modes)
    private func syncToMac() {
        let rulesData = customRules.map { rule -> [String: Any] in
            var dict: [String: Any] = [
                "id": rule.id,
                "risk": rule.risk,
                "priority": 0,
                "description": rule.description,
            ]
            if let tool = rule.toolPattern { dict["toolPattern"] = tool }
            if let path = rule.pathPattern { dict["pathPattern"] = path }
            return dict
        }

        relay.sendRulesUpdate(rules: rulesData)
    }

    // MARK: - Persistence (UserDefaults)

    private static let storageKey = "sentinel.customRules"

    private static let validRiskValues: Set<String> = ["auto_allow", "require_confirm", "require_faceid"]

    static func loadCustomRules() -> [CustomRule] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let rules = try? JSONDecoder.sentinelDecoder.decode([CustomRule].self, from: data) else {
            return []
        }
        // Filter out rules with invalid risk values (could happen after schema change)
        return rules.filter { validRiskValues.contains($0.risk) }
    }

    static func saveCustomRules(_ rules: [CustomRule]) {
        guard let data = try? JSONEncoder.sentinelEncoder.encode(rules) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - Built-in Rules Data

    private let builtinRules: [BuiltinRule] = [
        BuiltinRule(toolPattern: nil, pathPattern: "**/.env*", risk: "require_faceid",
                    description: String(localized: "环境变量文件"), systemImage: "exclamationmark.lock"),
        BuiltinRule(toolPattern: "Bash", pathPattern: nil, risk: "require_faceid",
                    description: String(localized: "终端命令"), systemImage: "terminal"),
        BuiltinRule(toolPattern: nil, pathPattern: "**/secrets/**", risk: "require_faceid",
                    description: String(localized: "密钥目录"), systemImage: "key"),
        BuiltinRule(toolPattern: "Write", pathPattern: nil, risk: "require_confirm",
                    description: String(localized: "文件写入"), systemImage: "doc.badge.plus"),
        BuiltinRule(toolPattern: "Edit", pathPattern: nil, risk: "require_confirm",
                    description: String(localized: "文件编辑"), systemImage: "pencil.line"),
        BuiltinRule(toolPattern: "Read", pathPattern: nil, risk: "auto_allow",
                    description: String(localized: "文件读取"), systemImage: "doc.text"),
        BuiltinRule(toolPattern: "Glob", pathPattern: nil, risk: "auto_allow",
                    description: String(localized: "文件搜索"), systemImage: "magnifyingglass"),
        BuiltinRule(toolPattern: "Grep", pathPattern: nil, risk: "auto_allow",
                    description: String(localized: "内容搜索"), systemImage: "magnifyingglass"),
    ]
}

// MARK: - Built-in Rule Row

private struct BuiltinRuleRow: View {
    let rule: BuiltinRule

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: rule.systemImage)
                .font(.body)
                .foregroundStyle(riskColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.description)
                    .font(.subheadline)

                HStack(spacing: 6) {
                    if let tool = rule.toolPattern {
                        ruleTag("Tool: \(tool)", .blue)
                    }
                    if let path = rule.pathPattern {
                        ruleTag(path, .purple)
                    }
                    ruleTag(riskLabel, riskColor)
                }
            }
        }
        .padding(.vertical, 2)
        .foregroundStyle(.secondary)
    }

    private var riskColor: Color {
        switch rule.risk {
        case "require_faceid": .red
        case "require_confirm": .orange
        default: .green
        }
    }

    private var riskLabel: String {
        switch rule.risk {
        case "require_faceid": "Face ID"
        case "require_confirm": String(localized: "确认")
        default: String(localized: "允许")
        }
    }

    private func ruleTag(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.monospaced())
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(color)
    }
}

// MARK: - Custom Rule Row

private struct CustomRuleRow: View {
    let rule: CustomRule

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toolIcon)
                .font(.body)
                .foregroundStyle(riskColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.description)
                    .font(.subheadline)

                HStack(spacing: 6) {
                    if let tool = rule.toolPattern {
                        ruleTag("Tool: \(tool)", .blue)
                    }
                    if let path = rule.pathPattern {
                        ruleTag(path, .purple)
                    }
                    ruleTag(riskLabel, riskColor)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 2)
    }

    private var toolIcon: String {
        switch rule.toolPattern {
        case "Read": "doc.text"
        case "Write": "doc.badge.plus"
        case "Edit": "pencil.line"
        case "Bash": "terminal"
        case "Grep": "magnifyingglass"
        case "Glob": "folder.badge.magnifyingglass"
        default: "gearshape"
        }
    }

    private var riskColor: Color {
        switch rule.risk {
        case "require_faceid": .red
        case "require_confirm": .orange
        default: .green
        }
    }

    private var riskLabel: String {
        switch rule.risk {
        case "require_faceid": "Face ID"
        case "require_confirm": String(localized: "确认")
        default: String(localized: "允许")
        }
    }

    private func ruleTag(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.monospaced())
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(color)
    }
}
