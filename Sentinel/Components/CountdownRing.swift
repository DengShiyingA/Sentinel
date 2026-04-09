import SwiftUI

struct CountdownRing: View {
    let timeoutAt: Date
    let totalDuration: TimeInterval
    var size: CGFloat = 80
    var lineWidth: CGFloat = 6
    var onTimeout: (() -> Void)?

    @State private var hasTimedOut = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, timeoutAt.timeIntervalSince(context.date))
            let progress = remaining / totalDuration

            ZStack {
                // Background ring
                Circle()
                    .stroke(ringColor(progress).opacity(0.2), lineWidth: lineWidth)

                // Progress ring
                Circle()
                    .trim(from: 0, to: max(0, progress))
                    .stroke(
                        ringColor(progress),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time text
                VStack(spacing: 2) {
                    Text("\(Int(remaining))")
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(String(localized: "秒"))
                        .font(.system(size: size * 0.12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "倒计时"))
            .accessibilityValue(String(localized: "\(Int(remaining)) 秒"))
            .onChange(of: remaining <= 0) { _, isZero in
                if isZero && !hasTimedOut {
                    hasTimedOut = true
                    onTimeout?()
                }
            }
        }
    }

    private func ringColor(_ progress: Double) -> Color {
        if progress > 0.5 {
            return .green
        } else if progress > 0.2 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    CountdownRing(
        timeoutAt: Date().addingTimeInterval(60),
        totalDuration: 120
    )
}
