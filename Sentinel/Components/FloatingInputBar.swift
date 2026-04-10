// Sentinel/Components/FloatingInputBar.swift
import SwiftUI

struct FloatingInputBar: View {
    let onSend: (String) -> Void
    let onInterrupt: () -> Void

    @State private var isExpanded = false
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    private let textShortcuts: [(label: String, message: String)] = [
        ("继续", "continue"),
        ("换个方案", "stop and try a different approach"),
    ]

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if isExpanded {
                expandedPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Floating icon button
            Button {
                withAnimation(Theme.springAnimation) {
                    isExpanded.toggle()
                    if isExpanded { isFocused = true }
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "arrow.up.message.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue, in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 8)
    }

    private var expandedPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Shortcut buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 停止 button — sends SIGINT via onInterrupt
                    Button {
                        onInterrupt()
                        withAnimation(Theme.springAnimation) { isExpanded = false }
                        isFocused = false
                    } label: {
                        Text("停止")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1), in: Capsule())
                    }

                    ForEach(textShortcuts, id: \.label) { shortcut in
                        Button {
                            send(shortcut.message)
                        } label: {
                            Text(shortcut.label)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Text input row
            HStack(spacing: 8) {
                TextField(String(localized: "发送指令给 Claude…"), text: $inputText, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit { send(inputText) }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button { send(inputText) } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
        .frame(maxWidth: 320)
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend(trimmed)
        inputText = ""
        withAnimation(Theme.springAnimation) { isExpanded = false }
        isFocused = false
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        FloatingInputBar(
            onSend: { text in print("Send: \(text)") },
            onInterrupt: { print("Interrupt!") }
        )
    }
}
