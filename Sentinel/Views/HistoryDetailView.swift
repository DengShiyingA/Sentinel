import SwiftUI

/// Detail view for a single DecisionRecord. Shows the full tool input (no
/// truncation), diff if present, context summary, decision outcome, and
/// action shortcuts (copy command, create rule from this record).
struct HistoryDetailView: View {
    let record: DecisionRecord
    @Environment(ApprovalStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var copiedField: String?
    @State private var ruleCreated = false

    var body: some View {
        List {
            decisionSection
            riskSection
            argsSection
            if let diff = record.request.diff, !diff.isEmpty {
                diffSection(diff)
            }
            if let ctx = record.request.contextSummary, !ctx.isEmpty {
                contextSection(ctx)
            }
            actionsSection
            metaSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(record.request.toolName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var decisionSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: record.decision == .allowed
                      ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(record.decision == .allowed ? .green : .red)
                    .font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.decision == .allowed
                         ? String(localized: "已允许")
                         : String(localized: "已拒绝"))
                        .font(.headline)
                        .foregroundStyle(record.decision == .allowed ? .green : .red)
                    Text(record.decidedAt, format: .dateTime.month().day().hour().minute().second())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        } header: {
            Text(String(localized: "决策"))
        }
    }

    private var riskSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: record.request.riskLevel.systemImage)
                    .foregroundStyle(riskColor)
                Text(record.request.riskLevel.label)
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
            .padding(.vertical, 2)
        } header: {
            Text(String(localized: "风险等级"))
        }
    }

    private var argsSection: some View {
        Section {
            ForEach(sortedInputKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(key)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let copyTarget = stringValue(for: key) {
                            Button {
                                UIPasteboard.general.string = copyTarget
                                copiedField = key
                                Task {
                                    try? await Task.sleep(for: .seconds(1.5))
                                    if copiedField == key { copiedField = nil }
                                }
                            } label: {
                                Image(systemName: copiedField == key
                                      ? "checkmark"
                                      : "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text(displayValue(for: key))
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(6)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text(String(localized: "参数"))
        }
    }

    private func diffSection(_ diff: String) -> some View {
        Section {
            DiffView(diff: diff)
                .padding(.vertical, 4)
        } header: {
            Text(String(localized: "差异"))
        }
    }

    private func contextSection(_ summary: String) -> some View {
        Section {
            Text(summary)
                .font(.callout)
                .padding(.vertical, 2)
        } header: {
            Text(String(localized: "上下文"))
        }
    }

    private var actionsSection: some View {
        Section {
            if !ruleCreated {
                Button {
                    createRule()
                } label: {
                    Label(String(localized: "为此类请求创建自动允许规则"),
                          systemImage: "plus.circle.fill")
                }
                .disabled(record.request.riskLevel == .requireFaceID)
            } else {
                Label(String(localized: "规则已创建"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            if record.request.riskLevel == .requireFaceID && !ruleCreated {
                Text(String(localized: "高风险操作不能自动允许，请手动添加信任"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "操作"))
        }
    }

    private var metaSection: some View {
        Section {
            LabeledContent(String(localized: "请求 ID"), value: record.id.prefix(12) + "...")
                .font(.caption.monospaced())
            LabeledContent(String(localized: "会话 ID"), value: record.sessionId.prefix(8) + "...")
                .font(.caption.monospaced())
        } header: {
            Text(String(localized: "元数据"))
        }
    }

    // MARK: - Helpers

    private var sortedInputKeys: [String] {
        // Put the most important fields first (command/path), then the rest.
        let priority = ["command", "file_path", "path", "old_string", "new_string", "content", "pattern"]
        var seen = Set<String>()
        var result: [String] = []
        for key in priority where record.request.toolInput[key] != nil {
            result.append(key)
            seen.insert(key)
        }
        for (key, _) in record.request.toolInput.sorted(by: { $0.key < $1.key })
            where !seen.contains(key) {
            result.append(key)
        }
        return result
    }

    private func displayValue(for key: String) -> String {
        guard let value = record.request.toolInput[key] else { return "" }
        // Primitive string gets shown directly; everything else via pretty JSON
        // so nested objects/arrays stay readable.
        if let s = value.value as? String { return s }
        return value.prettyJSON
    }

    private func stringValue(for key: String) -> String? {
        guard let value = record.request.toolInput[key] else { return nil }
        if let s = value.value as? String { return s }
        return value.prettyJSON
    }

    private var riskColor: Color {
        switch record.request.riskLevel {
        case .requireFaceID: .red
        case .requireConfirm: .orange
        }
    }

    private func createRule() {
        let path = ApprovalHelper.extractPath(from: record.request)
        let suggestion = RuleSuggestion(
            id: UUID().uuidString,
            toolName: record.request.toolName,
            pathPattern: path,
            matchCount: 1,
            timestamp: Date()
        )
        store.createRuleFromSuggestion(suggestion)
        ruleCreated = true
    }
}
