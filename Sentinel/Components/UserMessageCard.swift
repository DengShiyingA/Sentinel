// Sentinel/Components/UserMessageCard.swift
import SwiftUI

struct UserMessageCard: View {
    let entry: UserMessageEntry

    var body: some View {
        HStack(spacing: 10) {
            // Blue left accent bar (matches design: blue = user message)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: entry.status == .pending ? "clock" : "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(entry.status == .pending ? Color.secondary : Color.blue)

                    Text(entry.status == .pending
                         ? String(localized: "排队中")
                         : String(localized: "已发送"))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(entry.status == .pending ? Color.secondary : Color.blue)

                    Spacer()

                    Text(entry.sentAt, format: .dateTime.hour().minute().second())
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }

                Text(entry.text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(entry.status == .pending ? Color.primary.opacity(0.6) : Color.primary)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.2), value: entry.status == .pending)
    }
}

#Preview {
    VStack(spacing: 12) {
        let pending = UserMessageEntry(text: "重新检查 auth 逻辑")
        UserMessageCard(entry: pending)

        let sent = UserMessageEntry(text: "stop and summarize what you've done")
        UserMessageCard(entry: { var e = sent; e.status = .sent; return e }())
    }
    .padding()
}
