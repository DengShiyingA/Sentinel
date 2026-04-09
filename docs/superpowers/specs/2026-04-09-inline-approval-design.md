# Inline Approval Design Spec

## Problem

Sentinel's approval flow requires switching between Terminal and Approval tabs on iPhone. When monitoring Claude Code remotely (the primary use case), this context switching breaks the experience — you see what Claude is doing in one tab, then jump to another to approve, then jump back.

## Solution

Merge approval into the terminal timeline. Approval requests appear as interactive cards inline with Claude Code's activity stream. Same-type requests arriving within a short window are auto-grouped. The Approval tab becomes a read-only History tab.

## Core Use Case

User is away from computer. Claude Code is running a long task. User monitors and approves via iPhone — all in one screen.

## Design

### 1. Unified Timeline Data Model

Replace separate `ApprovalStore` + `ActivityFeed` with a single `TimelineStore`.

```swift
enum TimelineEntry: Identifiable {
    case activity(ActivityItem)
    case approval(ApprovalRequest)
    case approvalGroup(ApprovalGroup)
}

struct ApprovalGroup: Identifiable {
    let id: UUID
    let toolName: String
    var requests: [ApprovalRequest]
    var groupDecision: Decision?
}
```

**Grouping rule:** Same tool type, arriving within 3 seconds → merge into `ApprovalGroup`. User can expand the group to see individual items or decide on all at once.

**Ordering:** By timestamp. Approval cards appear at the position in the timeline where the request arrived, preserving context (you see what Claude was doing right before it asked for permission).

### 2. Inline Approval Card UI

**Single approval card:**
- Tool icon + tool name + risk badge (reuse existing `ToolIcon`, `RiskBadge`)
- Parameter summary (file path, first 80 chars of command)
- Diff preview for Edit/Write (collapsed, tap to expand)
- Countdown ring (reuse existing `CountdownRing`)
- Allow / Reject buttons
- After decision: card collapses to single-line status (e.g., "Allowed Edit src/Views/Foo.swift")

**Grouped approval card:**
- Header: "3 file edits pending"
- Collapsed list of file paths
- "Allow All" / "Reject All" buttons
- Expandable to decide individually
- After decision: collapses to "Allowed 3 file edits"

**Scroll behavior:**
- New approval auto-scrolls to bottom (unless user is scrolled up reading history)
- If user is scrolled up: show top banner "1 new approval ↓", tap to jump

**Face ID:** High-risk requests trigger biometric auth after tapping Allow (existing `BiometricService`).

### 3. Tab Structure

Before: `审批 | 终端 | 设置` (3 tabs)

After: `终端 | 历史 | 设置` (3 tabs)

- **终端 (Terminal):** Primary interface. Full timeline + inline approvals. Default tab on launch.
- **历史 (History):** Read-only log of all past decisions. Filterable by tool, decision, date. Replaces the old Approval tab.
- **设置 (Settings):** Unchanged.

### 4. Data Flow

Before:
```
Transport → ApprovalStore → Approval tab UI
Transport → ActivityFeed  → Terminal tab UI
```

After:
```
Transport → TimelineStore → Terminal timeline (both activity + approval cards)
Decision  → TimelineStore → Update card state + write to History
```

`TimelineStore` is the single source of truth. It:
- Receives approval requests and activity events from transport
- Applies grouping logic for same-type requests
- Tracks decision state per card
- Sends decisions back through transport
- Archives completed decisions for the History tab

### 5. What Does NOT Change

- **Transport layer:** TCP/WebSocket/CloudKit protocols unchanged
- **CLI:** Hook handling, rules engine, encryption — all unchanged
- **Push notifications:** Still work; tapping a notification opens Terminal tab (instead of Approval tab)
- **Rules & trust mechanism:** Unchanged
- **Settings page:** Unchanged
- **Encryption:** E2EE unchanged

### 6. Migration

- `ApprovalStore` logic merges into `TimelineStore`
- `ActivityFeed` logic merges into `TimelineStore`
- `ApprovalsView` renamed to `HistoryView`, made read-only
- `TerminalView` updated to render `TimelineEntry` (activity + approval cards)
- Tab bar updated: Terminal becomes first tab, History second
- Existing `ApprovalCardView` adapted for inline use (smaller, collapsible)

## Success Criteria

- Zero tab switches needed for the approve-while-away workflow
- Grouped approvals reduce tap count by ~60% for burst requests
- History tab provides full audit trail
- No changes to CLI or transport protocol
