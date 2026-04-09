# Inline Approval Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge the approval flow into the terminal timeline so users can monitor and approve in one screen.

**Architecture:** Extend `FeedItem` with `.approval` and `.approvalGroup` kinds. Build inline approval card components. Refactor `ApprovalStore` to drive a unified timeline. Convert Approval tab to read-only History tab. Update tab structure.

**Tech Stack:** Swift 5.9, SwiftUI, iOS 17+, Observation framework

---

### Task 1: Extend FeedItem with approval kinds

**Files:**
- Modify: `Sentinel/Views/TerminalView.swift:201-211` (FeedItem struct)

The `FeedItem` struct is private to TerminalView.swift. We need to extract it to its own file and add approval kinds, since it will be shared by multiple views.

- [ ] **Step 1: Create TimelineEntry model file**

Create `Sentinel/Models/TimelineEntry.swift`:

```swift
import Foundation

struct TimelineEntry: Identifiable {
    let id: String
    let time: Date
    let kind: Kind

    enum Kind {
        case terminal(String)
        case user(String)
        case claude(String)
        case approval(ApprovalRequest)
        case approvalGroup(ApprovalGroup)
    }
}

struct ApprovalGroup: Identifiable {
    let id: String
    let toolName: String
    var requests: [ApprovalRequest]
    var displayLabel: String {
        "\(requests.count) \(toolNameLabel) \(String(localized: "待审批"))"
    }

    private var toolNameLabel: String {
        let name = toolName.lowercased()
        if name.contains("write") || name.contains("edit") {
            return String(localized: "个文件编辑")
        } else if name.contains("bash") || name.contains("exec") {
            return String(localized: "个命令执行")
        } else if name.contains("read") {
            return String(localized: "个文件读取")
        } else {
            return String(localized: "个操作")
        }
    }
}
```

- [ ] **Step 2: Build the project to verify compilation**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sentinel/Models/TimelineEntry.swift
git commit -m "feat: add TimelineEntry model with approval and group kinds"
```

---

### Task 2: Build InlineApprovalCard component

**Files:**
- Create: `Sentinel/Components/InlineApprovalCard.swift`

This card renders a single approval request inline in the terminal timeline. It shows the tool info, risk level, countdown, diff preview, and Allow/Reject buttons. After a decision, it collapses to a single-line status.

- [ ] **Step 1: Create InlineApprovalCard**

Create `Sentinel/Components/InlineApprovalCard.swift`:

```swift
import SwiftUI

struct InlineApprovalCard: View {
    let request: ApprovalRequest
    let onDecision: (Decision) -> Void

    @State private var isExpanded = false
    @State private var decided: Decision?
    @State private var isAuthenticating = false
    @State private var authError: String?

    var body: some View {
        if let decided {
            decidedView(decided)
        } else {
            pendingView
        }
    }

    // MARK: - Decided (collapsed)

    private func decidedView(_ decision: Decision) -> some View {
        HStack(spacing: 8) {
            Image(systemName: decision == .allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(decision == .allowed ? .green : .red)
            Text(decision == .allowed ? String(localized: "已允许") : String(localized: "已拒绝"))
                .font(.caption.weight(.medium))
                .foregroundStyle(decision == .allowed ? .green : .red)
            Text(request.toolName)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            if let path = extractPath {
                Text(path)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Pending (interactive)

    private var pendingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: tool info + risk + countdown
            HStack(spacing: 10) {
                ToolIcon(toolName: request.toolName, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.toolName)
                        .font(.subheadline.weight(.semibold))
                    if let path = extractPath {
                        Text(path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer()
                RiskBadge(riskLevel: request.riskLevel)
                CountdownText(timeoutAt: request.timeoutAt)
            }

            // Diff preview (collapsed by default)
            if let diff = request.diff, !diff.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                        Text(String(localized: "查看 Diff"))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    DiffView(diff: diff)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    decided = .blocked
                    onDecision(.blocked)
                } label: {
                    Label(String(localized: "拒绝"), systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    handleAllow()
                } label: {
                    Group {
                        if isAuthenticating {
                            ProgressView()
                        } else if request.riskLevel == .requireFaceID {
                            Label(String(localized: "允许"), systemImage: "faceid")
                        } else {
                            Label(String(localized: "允许"), systemImage: "checkmark.circle.fill")
                        }
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .alert(String(localized: "认证失败"), isPresented: .init(
            get: { authError != nil },
            set: { if !$0 { authError = nil } }
        )) {
            Button(String(localized: "确定")) { authError = nil }
        } message: {
            Text(authError ?? "")
        }
    }

    // MARK: - Allow Logic

    private func handleAllow() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if request.riskLevel == .requireFaceID {
            isAuthenticating = true
            Task {
                do {
                    try await BiometricService.authenticate(
                        reason: String(localized: "验证身份以允许高风险操作")
                    )
                    decided = .allowed
                    onDecision(.allowed)
                } catch {
                    authError = error.localizedDescription
                }
                isAuthenticating = false
            }
        } else {
            decided = .allowed
            onDecision(.allowed)
        }
    }

    // MARK: - Helpers

    private var extractPath: String? {
        request.toolInput["file_path"]?.description
            ?? request.toolInput["path"]?.description
            ?? request.toolInput["command"]?.description
    }

    private var cardBackground: Color {
        switch request.riskLevel {
        case .requireFaceID: Color.red.opacity(0.06)
        case .requireConfirm: Color.orange.opacity(0.06)
        }
    }

    private var borderColor: Color {
        switch request.riskLevel {
        case .requireFaceID: .red.opacity(0.3)
        case .requireConfirm: .orange.opacity(0.3)
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sentinel/Components/InlineApprovalCard.swift
git commit -m "feat: add InlineApprovalCard component for terminal timeline"
```

---

### Task 3: Build InlineApprovalGroupCard component

**Files:**
- Create: `Sentinel/Components/InlineApprovalGroupCard.swift`

Renders a group of same-type approval requests as a single card with "Allow All" / "Reject All" + expand to see individual items.

- [ ] **Step 1: Create InlineApprovalGroupCard**

Create `Sentinel/Components/InlineApprovalGroupCard.swift`:

```swift
import SwiftUI

struct InlineApprovalGroupCard: View {
    let group: ApprovalGroup
    let onDecision: (String, Decision) -> Void
    let onGroupDecision: (Decision) -> Void

    @State private var isExpanded = false
    @State private var groupDecided: Decision?

    var body: some View {
        if let groupDecided {
            decidedView(groupDecided)
        } else {
            pendingView
        }
    }

    // MARK: - Decided (collapsed)

    private func decidedView(_ decision: Decision) -> some View {
        HStack(spacing: 8) {
            Image(systemName: decision == .allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(decision == .allowed ? .green : .red)
            Text(decision == .allowed ? String(localized: "已允许") : String(localized: "已拒绝"))
                .font(.caption.weight(.medium))
                .foregroundStyle(decision == .allowed ? .green : .red)
            Text("\(group.requests.count) \(group.toolName)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Pending (interactive)

    private var pendingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                ToolIcon(toolName: group.toolName, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.displayLabel)
                        .font(.subheadline.weight(.semibold))
                    Text(group.toolName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Expanded: individual items
            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(group.requests) { request in
                        InlineApprovalCard(request: request) { decision in
                            onDecision(request.id, decision)
                        }
                    }
                }
            }

            // Group action buttons (only when not expanded)
            if !isExpanded {
                HStack(spacing: 10) {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        groupDecided = .blocked
                        onGroupDecision(.blocked)
                    } label: {
                        Label(
                            String(localized: "全部拒绝 (\(group.requests.count))"),
                            systemImage: "xmark.circle.fill"
                        )
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        groupDecided = .allowed
                        onGroupDecision(.allowed)
                    } label: {
                        Label(
                            String(localized: "全部允许 (\(group.requests.count))"),
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sentinel/Components/InlineApprovalGroupCard.swift
git commit -m "feat: add InlineApprovalGroupCard component for grouped approvals"
```

---

### Task 4: Add grouping logic to ApprovalStore

**Files:**
- Modify: `Sentinel/Network/ApprovalStore.swift`

Add a computed property that groups pending requests by tool name when they arrive within 3 seconds of each other. Add a `timeline` computed property that merges activity + terminal + approvals into sorted `[TimelineEntry]`.

- [ ] **Step 1: Add timeline computed property and grouping to ApprovalStore**

In `Sentinel/Network/ApprovalStore.swift`, add after the `syncToast` property (around line 26):

```swift
    /// Unified timeline entries for the terminal view.
    /// Merges terminal lines, activity feed, and pending approvals (with grouping).
    var timeline: [TimelineEntry] {
        var entries: [TimelineEntry] = []

        // Terminal lines
        for line in terminalLines {
            entries.append(TimelineEntry(
                id: line.id, time: line.timestamp, kind: .terminal(line.text)))
        }

        // Activity feed
        for item in activityFeed {
            switch item.type {
            case .userMessage:
                entries.append(TimelineEntry(
                    id: "u-\(item.id)", time: item.timestamp, kind: .user(item.summary)))
            case .claudeResponse:
                entries.append(TimelineEntry(
                    id: "c-\(item.id)", time: item.timestamp, kind: .claude(item.summary)))
            case .notification:
                entries.append(TimelineEntry(
                    id: "n-\(item.id)", time: item.timestamp,
                    kind: .terminal("📢 \(item.summary)")))
            case .stop:
                let prefix = item.isError ? "❌" : "✅"
                entries.append(TimelineEntry(
                    id: "s-\(item.id)", time: item.timestamp,
                    kind: .terminal("\(prefix) \(item.summary)")))
            default:
                break
            }
        }

        // Pending approvals (grouped)
        let groups = groupedApprovals()
        for group in groups {
            if group.requests.count == 1 {
                let req = group.requests[0]
                entries.append(TimelineEntry(
                    id: "a-\(req.id)", time: req.timestamp, kind: .approval(req)))
            } else {
                let earliest = group.requests.map(\.timestamp).min() ?? Date()
                entries.append(TimelineEntry(
                    id: "ag-\(group.id)", time: earliest, kind: .approvalGroup(group)))
            }
        }

        entries.sort { $0.time < $1.time }
        return entries
    }

    /// Group pending requests by tool name when they arrive within 3 seconds of each other.
    private func groupedApprovals() -> [ApprovalGroup] {
        guard !pendingRequests.isEmpty else { return [] }

        // Sort by timestamp ascending
        let sorted = pendingRequests.sorted { $0.timestamp < $1.timestamp }
        var groups: [ApprovalGroup] = []
        var current = ApprovalGroup(
            id: sorted[0].id,
            toolName: sorted[0].toolName,
            requests: [sorted[0]]
        )

        for i in 1..<sorted.count {
            let req = sorted[i]
            let lastInGroup = current.requests.last!
            let gap = req.timestamp.timeIntervalSince(lastInGroup.timestamp)

            if req.toolName == current.toolName && gap <= 3.0 {
                current.requests.append(req)
            } else {
                groups.append(current)
                current = ApprovalGroup(
                    id: req.id,
                    toolName: req.toolName,
                    requests: [req]
                )
            }
        }
        groups.append(current)
        return groups
    }
```

- [ ] **Step 2: Add sendGroupDecision method**

Add after the existing `sendDecision` method:

```swift
    func sendGroupDecision(group: ApprovalGroup, decision: Decision) {
        for request in group.requests {
            sendDecision(requestId: request.id, decision: decision)
        }
    }
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Sentinel/Network/ApprovalStore.swift
git commit -m "feat: add timeline computation and approval grouping to ApprovalStore"
```

---

### Task 5: Rewrite TerminalView to use unified timeline

**Files:**
- Modify: `Sentinel/Views/TerminalView.swift`

Replace the private `FeedItem`-based approach with `store.timeline`. Add rendering for `.approval` and `.approvalGroup` kinds using the new inline card components. Add "new approval" banner when user is scrolled up.

- [ ] **Step 1: Rewrite TerminalView**

Replace the entire content of `Sentinel/Views/TerminalView.swift` with:

```swift
import SwiftUI

struct TerminalView: View {
    @Environment(ApprovalStore.self) private var store
    @Environment(RelayService.self) private var relay
    @State private var messageText = ""
    @State private var isScrolledToBottom = true
    @State private var pendingApprovalCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.timeline.isEmpty {
                    emptyState
                } else {
                    ZStack(alignment: .top) {
                        feedList
                        if !isScrolledToBottom && pendingApprovalCount > 0 {
                            newApprovalBanner
                        }
                    }
                }
                Divider()
                inputBar
            }
            .navigationTitle(String(localized: "终端"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(relay.isConnected ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(relay.isConnected
                             ? String(localized: "运行中")
                             : String(localized: "等待中"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.timeline.isEmpty {
                        Button {
                            store.terminalLines.removeAll()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                    }
                }
            }
            .onChange(of: store.pendingRequests.count) { _, newCount in
                pendingApprovalCount = newCount
            }
        }
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(store.timeline) { entry in
                        entryRow(entry).id(entry.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: store.timeline.count) { _, _ in
                if isScrolledToBottom, let last = store.timeline.last {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Entry Row

    @ViewBuilder
    private func entryRow(_ entry: TimelineEntry) -> some View {
        switch entry.kind {
        case .terminal(let text):
            HStack(alignment: .top, spacing: 6) {
                Text(entry.time, format: .dateTime.hour().minute().second())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 55, alignment: .leading)
                Text(text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(lineColor(text))
                    .textSelection(.enabled)
            }

        case .user(let text):
            HStack {
                Spacer()
                Text(text)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 2)

        case .claude(let text):
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Claude")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.purple)
                    Text(text)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
                Spacer()
            }
            .padding(.vertical, 2)

        case .approval(let request):
            InlineApprovalCard(request: request) { decision in
                store.sendDecision(requestId: request.id, decision: decision)
            }
            .padding(.vertical, 4)

        case .approvalGroup(let group):
            InlineApprovalGroupCard(
                group: group,
                onDecision: { requestId, decision in
                    store.sendDecision(requestId: requestId, decision: decision)
                },
                onGroupDecision: { decision in
                    store.sendGroupDecision(group: group, decision: decision)
                }
            )
            .padding(.vertical, 4)
        }
    }

    // MARK: - New Approval Banner

    private var newApprovalBanner: some View {
        Button {
            isScrolledToBottom = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                Text(String(localized: "\(pendingApprovalCount) 个新审批"))
                    .font(.caption.weight(.medium))
                Image(systemName: "arrow.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack {
                TextField(
                    relay.isConnected
                        ? String(localized: "发送消息给 Claude Code...")
                        : String(localized: "未连接"),
                    text: $messageText
                )
                .disabled(!relay.isConnected)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

                if !messageText.isEmpty {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "等待输出"), systemImage: "terminal")
        } description: {
            Text(String(localized: "Claude Code 的实时输出和对话会显示在这里"))
        }
    }

    // MARK: - Helpers

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.sendUserMessage(text)
        messageText = ""
    }

    private func lineColor(_ text: String) -> Color {
        if text.hasPrefix("✅") { return .green }
        if text.hasPrefix("❌") { return .red }
        if text.hasPrefix("📢") { return .orange }
        if text.hasPrefix(">") { return .blue }
        if text.hasPrefix("[") { return .teal }
        return .primary
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sentinel/Views/TerminalView.swift
git commit -m "feat: rewrite TerminalView to use unified timeline with inline approvals"
```

---

### Task 6: Convert ApprovalListView to HistoryView

**Files:**
- Modify: `Sentinel/Views/ApprovalListView.swift` (rename to HistoryView)
- Modify: `Sentinel/Network/ApprovalStore.swift` (add history tracking)

Convert the approval list into a read-only history of past decisions.

- [ ] **Step 1: Add history tracking to ApprovalStore**

In `Sentinel/Network/ApprovalStore.swift`, add a new property after `resolvedCount`:

```swift
    /// History of resolved approval requests with their decisions.
    var decisionHistory: [DecisionRecord] = []
```

Add the `DecisionRecord` struct to `Sentinel/Models/TimelineEntry.swift` (bottom of file):

```swift
struct DecisionRecord: Identifiable {
    let id: String
    let request: ApprovalRequest
    let decision: Decision
    let decidedAt: Date
}
```

In `ApprovalStore.sendDecision`, add before `self.removeRequest(id: requestId)`:

```swift
            if let req = self.pendingRequests.first(where: { $0.id == requestId }) {
                self.decisionHistory.insert(
                    DecisionRecord(id: requestId, request: req, decision: decision, decidedAt: Date()),
                    at: 0
                )
            }
```

- [ ] **Step 2: Rewrite ApprovalListView.swift as HistoryView**

Replace the entire content of `Sentinel/Views/ApprovalListView.swift` with:

```swift
import SwiftUI

struct HistoryView: View {
    @Environment(ApprovalStore.self) private var store
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if filteredHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle(String(localized: "历史"))
            .searchable(text: $searchText, prompt: String(localized: "搜索工具名或路径"))
        }
    }

    private var filteredHistory: [DecisionRecord] {
        if searchText.isEmpty { return store.decisionHistory }
        let query = searchText.lowercased()
        return store.decisionHistory.filter { record in
            record.request.toolName.lowercased().contains(query)
            || (record.request.toolInput["file_path"]?.description ?? "").lowercased().contains(query)
            || (record.request.toolInput["command"]?.description ?? "").lowercased().contains(query)
        }
    }

    private var historyList: some View {
        List(filteredHistory) { record in
            HStack(spacing: 12) {
                Image(systemName: record.decision == .allowed
                      ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(record.decision == .allowed ? .green : .red)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.request.toolName)
                        .font(.headline)
                    if let path = record.request.toolInput["file_path"]?.description
                        ?? record.request.toolInput["command"]?.description {
                        Text(path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    RiskBadge(riskLevel: record.request.riskLevel)
                    Text(record.decidedAt, format: .dateTime.hour().minute().second())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "暂无历史记录"), systemImage: "clock")
        } description: {
            Text(String(localized: "审批决策记录会显示在这里"))
        }
    }
}
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Sentinel/Views/ApprovalListView.swift Sentinel/Network/ApprovalStore.swift Sentinel/Models/TimelineEntry.swift
git commit -m "feat: convert ApprovalListView to read-only HistoryView with search"
```

---

### Task 7: Update tab structure in ContentView

**Files:**
- Modify: `Sentinel/Views/ContentView.swift`

Change tab order: Terminal (default) | History | Settings. Update badge to show pending approvals on Terminal tab instead of old Approval tab.

- [ ] **Step 1: Update MainTabView**

Replace `MainTabView` in `Sentinel/Views/ContentView.swift` with:

```swift
struct MainTabView: View {
    @Environment(ApprovalStore.self) private var store
    private let errorBus = ErrorBus.shared

    var body: some View {
        TabView {
            TerminalView()
                .tabItem {
                    Label(String(localized: "终端"), systemImage: "terminal")
                }
                .badge(store.pendingRequests.count)

            HistoryView()
                .tabItem {
                    Label(String(localized: "历史"), systemImage: "clock")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "设置"), systemImage: "gearshape")
                }
        }
        .alert(
            String(localized: "错误"),
            isPresented: .init(
                get: { errorBus.currentError != nil },
                set: { if !$0 { errorBus.dismiss() } }
            )
        ) {
            Button(String(localized: "确定")) { errorBus.dismiss() }
        } message: {
            if let error = errorBus.currentError {
                Text(error.message + (error.recovery.map { "\n\n" + $0 } ?? ""))
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sentinel/Views/ContentView.swift
git commit -m "feat: update tab structure — Terminal (default) | History | Settings"
```

---

### Task 8: Update push notification tap target

**Files:**
- Modify: `Sentinel/Services/NotificationService.swift` (if needed)
- Modify: `Sentinel/SentinelApp.swift` (or wherever notification tap routing lives)

Tapping an approval push notification should open the Terminal tab (tab 0) instead of the old Approval tab. The notification action callbacks (Allow/Block from lock screen) should still work via `ApprovalStore.sendDecision`.

- [ ] **Step 1: Check current notification routing**

Read `Sentinel/SentinelApp.swift` to see how notification taps are routed. The `NotificationService.onNotificationAction` callback already goes through `ApprovalStore.sendDecision`, which still works. We just need to ensure tapping the notification body opens the Terminal tab.

If `SentinelApp.swift` has tab selection state, update the default/notification-tap tab to index 0 (Terminal). If there is no explicit tab routing (SwiftUI TabView defaults to first tab), no change is needed since Terminal is now the first tab.

- [ ] **Step 2: Build and verify end-to-end**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit (if changes were needed)**

```bash
git add -A
git commit -m "fix: route notification taps to Terminal tab"
```

---

### Task 9: Clean up dead code

**Files:**
- Modify: `Sentinel/Network/ApprovalStore.swift` — remove `newActivityCount` and `clearNewActivityCount` (no longer needed, terminal tab is always visible)
- Modify: `Sentinel/Views/ApprovalDetailView.swift` — keep this file for now; it can still be used as a navigation destination from HistoryView in a future iteration. No changes needed.
- Remove: The old `FeedItem` struct at the bottom of `TerminalView.swift` was already removed in Task 5.

- [ ] **Step 1: Remove newActivityCount from ApprovalStore**

In `Sentinel/Network/ApprovalStore.swift`:

Remove the property:
```swift
    var newActivityCount: Int = 0
```

Remove the method:
```swift
    func clearNewActivityCount() {
        newActivityCount = 0
    }
```

Remove `self.newActivityCount += 1` from `handleActivity`.

- [ ] **Step 2: Search for any remaining references**

Run: `grep -r "newActivityCount\|clearNewActivityCount" Sentinel/` to verify no other files reference these.

Expected: No matches (or only the lines we're about to remove).

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Sentinel/Network/ApprovalStore.swift
git commit -m "cleanup: remove unused newActivityCount tracking"
```

---

### Task 10: Final verification

- [ ] **Step 1: Full clean build**

Run: `xcodebuild clean build -project Sentinel.xcodeproj -scheme Sentinel -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED with 0 warnings related to our changes

- [ ] **Step 2: Verify file structure**

Confirm these files exist and are correct:
- `Sentinel/Models/TimelineEntry.swift` (new)
- `Sentinel/Components/InlineApprovalCard.swift` (new)
- `Sentinel/Components/InlineApprovalGroupCard.swift` (new)
- `Sentinel/Views/TerminalView.swift` (rewritten)
- `Sentinel/Views/ApprovalListView.swift` (now HistoryView)
- `Sentinel/Views/ContentView.swift` (updated tabs)
- `Sentinel/Network/ApprovalStore.swift` (timeline + grouping + history)

- [ ] **Step 3: Commit final state**

```bash
git add -A
git commit -m "feat: inline approval — complete implementation"
```
