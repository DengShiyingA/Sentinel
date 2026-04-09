import SwiftUI

struct SessionHistoryView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay
    @Environment(\.dismiss) private var dismiss
    @State private var records = SessionRecord.load()

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "暂无历史对话"), systemImage: "clock")
                    } description: {
                        Text(String(localized: "Claude Code 任务完成后会自动记录"))
                    }
                } else {
                    sessionList
                }
            }
            .navigationTitle(String(localized: "历史对话"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "关闭")) { dismiss() }
                }
                if !records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "清空"), role: .destructive) {
                            records.removeAll()
                            SessionRecord.save(records)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }

    private var sessionList: some View {
        List {
            if relay.isConnected {
                Section {
                    Button {
                        store.sendUserMessage("/continue")
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(String(localized: "继续上次对话"))
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
            }

            Section(String(localized: "最近会话")) {
                ForEach(records) { record in
                    Button {
                        store.sendUserMessage("/resume")
                        dismiss()
                    } label: {
                        sessionRow(record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func sessionRow(_ record: SessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: record.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(record.isError ? .red : .green)

                Text(record.summary)
                    .font(.subheadline)
                    .lineLimit(2)

                Spacer()

                Text(record.endedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !record.filesModified.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 9))
                    Text(record.filesModified.prefix(3).joined(separator: ", "))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Label("\(record.approvalCount)", systemImage: "checkmark.shield")
                Text(record.duration)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

extension SessionRecord {
    var duration: String {
        let secs = Int(endedAt.timeIntervalSince(startedAt))
        if secs < 60 { return "\(secs)s" }
        return "\(secs / 60)m \(secs % 60)s"
    }
}
