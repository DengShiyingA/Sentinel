import WidgetKit
import SwiftUI

@main
struct SentinelWidgetBundle: WidgetBundle {
    var body: some Widget {
        SentinelWidget()
        ApprovalLiveActivityWidget()
    }
}
