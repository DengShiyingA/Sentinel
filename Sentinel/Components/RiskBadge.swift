import SwiftUI

struct RiskBadge: View {
    let riskLevel: RiskLevel

    var body: some View {
        Label(riskLevel.label, systemImage: riskLevel.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor, in: Capsule())
    }

    private var foregroundColor: Color {
        switch riskLevel {
        case .requireConfirm: .orange
        case .requireFaceID: .red
        }
    }

    private var backgroundColor: Color {
        foregroundColor.opacity(0.15)
    }
}

#Preview {
    VStack(spacing: 12) {
        RiskBadge(riskLevel: .requireConfirm)
        RiskBadge(riskLevel: .requireFaceID)
    }
}
