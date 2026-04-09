import SwiftUI

struct CountdownText: View {
    let timeoutAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = Int(max(0, timeoutAt.timeIntervalSince(context.date)))
            Text("\(remaining)s")
                .font(.caption.monospacedDigit())
                .foregroundStyle(remaining < 30 ? .red : .secondary)
        }
    }
}
