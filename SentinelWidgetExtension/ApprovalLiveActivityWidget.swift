import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

/// Live Activity widget for Sentinel approval requests.
/// Presents the pending approval on the lock screen and Dynamic Island
/// with inline Allow/Deny buttons wired to LiveActivityIntents.
struct ApprovalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ApprovalActivityAttributes.self) { context in
            LockScreenApprovalView(
                attributes: context.attributes,
                state: context.state
            )
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded (long-press or on approval arrival)
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.toolName)
                            .font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: context.attributes.isHighRisk ? "lock.shield.fill" : "shield")
                            .foregroundStyle(context.attributes.isHighRisk ? .red : .yellow)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdownView(timeoutAt: context.attributes.timeoutAt, phase: context.state.phase)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.phase == .pending {
                        HStack(spacing: 10) {
                            Button(intent: DenyApprovalIntent(requestId: context.attributes.requestId)) {
                                Label("拒绝", systemImage: "xmark")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .tint(.red)
                            .buttonStyle(.borderedProminent)

                            allowButton(for: context.attributes)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 4)
                    } else {
                        finalPhaseLabel(context.state.phase)
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.isHighRisk ? "lock.shield.fill" : "shield")
                    .foregroundStyle(context.attributes.isHighRisk ? .red : .yellow)
            } compactTrailing: {
                countdownView(timeoutAt: context.attributes.timeoutAt, phase: context.state.phase)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 40)
            } minimal: {
                Image(systemName: "shield")
                    .foregroundStyle(context.attributes.isHighRisk ? .red : .yellow)
            }
        }
    }

    /// High-risk requests open the app (for Face ID) while normal requests
    /// approve inline via the queue.
    @ViewBuilder
    private func allowButton(for attrs: ApprovalActivityAttributes) -> some View {
        if attrs.isHighRisk {
            Button(intent: AllowHighRiskApprovalIntent(requestId: attrs.requestId)) {
                Label("允许 (Face ID)", systemImage: "faceid")
            }
            .tint(.green)
            .buttonStyle(.borderedProminent)
        } else {
            Button(intent: AllowApprovalIntent(requestId: attrs.requestId)) {
                Label("允许", systemImage: "checkmark")
            }
            .tint(.green)
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func countdownView(timeoutAt: Date, phase: ApprovalActivityAttributes.ContentState.Phase) -> some View {
        if phase == .pending, timeoutAt > Date() {
            Text(timerInterval: Date()...timeoutAt, countsDown: true, showsHours: false)
        } else {
            Text(phaseLabel(phase))
        }
    }

    private func phaseLabel(_ phase: ApprovalActivityAttributes.ContentState.Phase) -> String {
        switch phase {
        case .pending: return "待审批"
        case .approved: return "已允许"
        case .denied: return "已拒绝"
        case .timeout: return "已超时"
        }
    }

    @ViewBuilder
    private func finalPhaseLabel(_ phase: ApprovalActivityAttributes.ContentState.Phase) -> some View {
        HStack(spacing: 6) {
            Image(systemName: phaseIcon(phase))
                .foregroundStyle(phaseColor(phase))
            Text(phaseLabel(phase))
                .font(.caption.weight(.semibold))
                .foregroundStyle(phaseColor(phase))
        }
        .frame(maxWidth: .infinity)
    }

    private func phaseIcon(_ phase: ApprovalActivityAttributes.ContentState.Phase) -> String {
        switch phase {
        case .pending: return "hourglass"
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .timeout: return "clock.badge.exclamationmark"
        }
    }

    private func phaseColor(_ phase: ApprovalActivityAttributes.ContentState.Phase) -> Color {
        switch phase {
        case .pending: return .secondary
        case .approved: return .green
        case .denied: return .red
        case .timeout: return .orange
        }
    }
}

// MARK: - Lock screen (full card)

private struct LockScreenApprovalView: View {
    let attributes: ApprovalActivityAttributes
    let state: ApprovalActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: attributes.isHighRisk ? "lock.shield.fill" : "shield")
                    .foregroundStyle(attributes.isHighRisk ? .red : .yellow)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 1) {
                    Text(attributes.toolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(attributes.riskLabel)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                if state.phase == .pending, attributes.timeoutAt > Date() {
                    Text(timerInterval: Date()...attributes.timeoutAt, countsDown: true, showsHours: false)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(minWidth: 40, alignment: .trailing)
                }
            }

            Text(attributes.summary)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .truncationMode(.middle)

            if state.phase == .pending {
                HStack(spacing: 8) {
                    Button(intent: DenyApprovalIntent(requestId: attributes.requestId)) {
                        Label("拒绝", systemImage: "xmark")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)

                    // High-risk requests use a variant that opens the app
                    // so the in-app Face ID prompt gates the decision.
                    if attributes.isHighRisk {
                        Button(intent: AllowHighRiskApprovalIntent(requestId: attributes.requestId)) {
                            Label("允许 (Face ID)", systemImage: "faceid")
                                .font(.footnote.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.green)
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button(intent: AllowApprovalIntent(requestId: attributes.requestId)) {
                            Label("允许", systemImage: "checkmark")
                                .font(.footnote.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.green)
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: phaseIcon(state.phase))
                        .foregroundStyle(phaseColor(state.phase))
                    Text(phaseLabel(state.phase))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(phaseColor(state.phase))
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func phaseLabel(_ phase: ApprovalActivityAttributes.ContentState.Phase) -> String {
        switch phase {
        case .pending: return "待审批"
        case .approved: return "已允许"
        case .denied: return "已拒绝"
        case .timeout: return "已超时"
        }
    }

    private func phaseIcon(_ phase: ApprovalActivityAttributes.ContentState.Phase) -> String {
        switch phase {
        case .pending: return "hourglass"
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .timeout: return "clock.badge.exclamationmark"
        }
    }

    private func phaseColor(_ phase: ApprovalActivityAttributes.ContentState.Phase) -> Color {
        switch phase {
        case .pending: return .secondary
        case .approved: return .green
        case .denied: return .red
        case .timeout: return .orange
        }
    }
}
