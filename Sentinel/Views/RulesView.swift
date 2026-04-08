import SwiftUI

// MARK: - Built-in Rule Model (read-only display)

private struct DisplayRule: Identifiable {
    let id = UUID()
    let toolPattern: String?
    let pathPattern: String?
    let risk: RiskLevel
    let description: String
}

struct RulesView: View {
    // Built-in rules grouped by risk level
    private let faceIDRules: [DisplayRule] = [
        DisplayRule(toolPattern: "Bash", pathPattern: nil, risk: .requireFaceID,
                    description: String(localized: "所有终端命令需要 Face ID")),
        DisplayRule(toolPattern: nil, pathPattern: "**/.env*", risk: .requireFaceID,
                    description: String(localized: "环境变量文件操作")),
        DisplayRule(toolPattern: nil, pathPattern: "**/secrets/**", risk: .requireFaceID,
                    description: String(localized: "密钥目录操作")),
    ]

    private let confirmRules: [DisplayRule] = [
        DisplayRule(toolPattern: "Write", pathPattern: nil, risk: .requireConfirm,
                    description: String(localized: "所有文件写入需要确认")),
        DisplayRule(toolPattern: "Edit", pathPattern: nil, risk: .requireConfirm,
                    description: String(localized: "所有文件编辑需要确认")),
        DisplayRule(toolPattern: nil, pathPattern: "**/package.json", risk: .requireConfirm,
                    description: String(localized: "包管理文件修改")),
        DisplayRule(toolPattern: "Glob", pathPattern: nil, risk: .requireConfirm,
                    description: String(localized: "文件搜索操作")),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(faceIDRules) { rule in
                        RuleRow(rule: rule)
                    }
                } header: {
                    Label(String(localized: "需要 Face ID"), systemImage: "faceid")
                        .foregroundStyle(.red)
                } footer: {
                    Text(String(localized: "这些操作被视为高风险，需要生物识别验证"))
                }

                Section {
                    ForEach(confirmRules) { rule in
                        RuleRow(rule: rule)
                    }
                } header: {
                    Label(String(localized: "需要确认"), systemImage: "hand.raised")
                        .foregroundStyle(.orange)
                } footer: {
                    Text(String(localized: "这些操作需要手动审批"))
                }

                Section {
                    Label {
                        Text(String(localized: "自定义规则将在后续版本支持"))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "plus.circle.dashed")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(String(localized: "自定义"))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "规则"))
        }
    }
}

// MARK: - Rule Row

private struct RuleRow: View {
    let rule: DisplayRule

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rule.description)
                .font(.subheadline)

            HStack(spacing: 8) {
                if let tool = rule.toolPattern {
                    tag(text: "Tool: \(tool)", color: .blue)
                }
                if let path = rule.pathPattern {
                    tag(text: path, color: .purple)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func tag(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.monospaced())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(color)
    }
}
