# Phase 1 Design Spec: Smart Rules, Session Summary, iOS Widget

## Overview

Three independent features that enhance Sentinel's remote monitoring experience. Each feature is self-contained — no cross-dependencies.

## Feature 1: Smart Rule Suggestions

### Problem

Users repeatedly approve the same patterns (e.g., Edit on files in the same directory). They should be prompted to create auto-approval rules to reduce manual work.

### Design

**Trigger:** After each `sendDecision(.allowed)`, `SuggestionEngine` scans the last N entries in `decisionHistory` for repeating patterns. When the same toolName + similar path pattern appears 5+ times consecutively (all allowed), a suggestion is generated.

**Path pattern inference:** Extract common prefix and extension from consecutive paths:
- `src/Views/Foo.swift`, `src/Views/Bar.swift`, `src/Views/Baz.swift` → `src/Views/*.swift`
- `src/Models/User.swift`, `src/Views/Home.swift` → no pattern (different directories)
- If no path (e.g., Bash commands), group by toolName only

**Deduplication:** Each generated pattern is tracked in a `Set<String>` of dismissed/created patterns. Same pattern is never suggested twice.

**UI — InlineSuggestionCard in terminal timeline:**
- Light blue background, suggestion icon
- Text: "连续允许了 5 次 Edit src/Views/*.swift，要自动允许吗？"
- 「创建规则」button → calls existing rules mechanism, card collapses to "✓ 已创建规则"
- 「忽略」button → card collapses to dismissed state, pattern added to ignore set

**New timeline entry kind:** `TimelineEntry.Kind.suggestion(RuleSuggestion)`

**New types:**
- `RuleSuggestion` struct — `id`, `toolName`, `pathPattern`, `matchCount`, `timestamp`
- `SuggestionEngine` — stateless analysis, `func analyze(history: [DecisionRecord]) -> RuleSuggestion?`
- `InlineSuggestionCard` — SwiftUI component

**Integration point:** `ApprovalStore.sendDecision()` calls `SuggestionEngine.analyze()` after recording the decision. If a suggestion is returned and not already dismissed, it's added to `pendingSuggestions: [RuleSuggestion]` which feeds into `rebuildTimeline()`.

### What Does NOT Change

- CLI rules engine — suggestions create rules through the existing iOS rules mechanism
- Transport layer
- Existing approval flow

---

## Feature 2: Session Summary

### Problem

When Claude Code finishes a task (success or failure), the user has to scroll through terminal output to understand what happened. A concise summary at the end saves time.

### Design

**Trigger:** When an `ActivityItem` with type `.stop` arrives, `SessionSummaryBuilder` generates a summary from timeline entries since the last `.stop` (or app launch).

**Summary data:**
- `filesModified: [String]` — extracted from Edit/Write approval decisions (from `decisionHistory`)
- `commandsRun: Int` — count of Bash approvals
- `approvalsAllowed: Int` — count of allowed decisions in this session segment
- `approvalsBlocked: Int` — count of blocked decisions
- `isError: Bool` — from the `.stop` event's `stopReason`
- `duration: TimeInterval` — time between previous `.stop` and this one

**Push notification:**
- Title: "✅ Claude Code 任务完成" or "❌ Claude Code 任务失败"
- Body: "修改 {N} 个文件，执行 {M} 个命令" (replaces current simple notification)

**Terminal timeline — InlineSummaryCard:**
- Inserted after the `.stop` entry as `TimelineEntry.Kind.summary(SessionSummary)`
- Collapsed: one-line summary "✅ 完成：修改 3 个文件，5 个命令"
- Expandable: file list, command count, approval stats, duration

**New types:**
- `SessionSummary` struct — all summary fields above
- `SessionSummaryBuilder` — `func build(timeline: [TimelineEntry], history: [DecisionRecord], stopItem: ActivityItem) -> SessionSummary`
- `InlineSummaryCard` — SwiftUI component

**Integration point:** `ApprovalStore.handleActivity()` — when `.stop` is received, build summary, add to timeline. Replace current simple notification with summary notification.

**Tracking session boundaries:** Store timestamp of last `.stop` event as `lastStopTimestamp: Date?` in ApprovalStore. Summary covers entries between `lastStopTimestamp` and current `.stop`.

### What Does NOT Change

- CLI — no changes needed, `.stop` events already sent
- Transport layer
- Existing terminal rendering (summary is additive)

---

## Feature 3: iOS Widget (Medium)

### Problem

User has to open the app to check if Claude Code needs attention. A home screen widget provides at-a-glance status.

### Design

**Architecture:**
```
Main App ──writes──→ App Group UserDefaults ←──reads── Widget Extension
                     "group.com.sentinel.ios"
```

**Shared data (written by main app):**
```swift
struct WidgetState: Codable {
    let isConnected: Bool
    let pendingCount: Int
    let resolvedCount: Int
    let latestToolName: String?    // most recent pending request
    let latestPath: String?        // its file_path/command
    let latestRiskLevel: String?   // "requireConfirm" or "requireFaceID"
    let updatedAt: Date
}
```

**Write triggers:** `rebuildTimeline()` and `RelayService.isConnected` changes. Write `WidgetState` as JSON to App Group UserDefaults, then call `WidgetCenter.shared.reloadAllTimelines()`.

**Widget UI (systemMedium):**

```
┌─────────────────────────────────────┐
│ 🟢 已连接          3 待审批         │
│                                     │
│ Edit  src/Views/TerminalView.swift  │
│ ───────────────────────────────────│
│         已处理 47 个请求            │
└─────────────────────────────────────┘
```

- **No pending:** Shows "一切正常" with resolved count
- **Disconnected:** Red dot + "未连接", grayed out
- **Tap:** Opens main app (deep link to terminal tab)

**Timeline refresh:** `TimelineReloadPolicy.after(Date().addingTimeInterval(300))` — refresh every 5 minutes as fallback. Primary updates come from `reloadAllTimelines()` calls.

**New files:**

Widget Extension target `SentinelWidget/`:
- `SentinelWidget.swift` — `@main Widget`, `TimelineProvider`
- `SentinelWidgetEntryView.swift` — SwiftUI view
- `WidgetState.swift` — shared Codable struct (also used by main app)

Main App:
- `Sentinel/Helpers/SharedStateWriter.swift` — writes WidgetState to App Group

**Xcode setup:**
- New Widget Extension target
- App Group capability on both targets
- Shared `WidgetState.swift` in both targets (or a shared framework)

### What Does NOT Change

- CLI, transport, existing views
- No new dependencies

---

## Success Criteria

1. **Smart rules:** After 5 consecutive allows of same pattern, suggestion card appears in timeline. Creating a rule from suggestion actually prevents future manual approvals.
2. **Session summary:** Every `.stop` event produces a summary card in timeline and an informative push notification.
3. **Widget:** Medium widget shows live connection status and pending count, updates within seconds of state change.

## Implementation Order

1. Feature 1 (Smart Rules) — smallest scope, extends existing timeline
2. Feature 2 (Session Summary) — similar pattern to Feature 1
3. Feature 3 (Widget) — new target, independent of 1 and 2
