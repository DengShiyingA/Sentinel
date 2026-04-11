import SwiftUI

struct TerminalListView: View {
    @Environment(RelayService.self) private var relay
    @Environment(ApprovalStore.self) private var store
    @State private var profiles: [TerminalProfile] = TerminalProfile.load()
    @State private var showAddSheet = false
    @State private var editingProfile: TerminalProfile?

    var body: some View {
        NavigationStack {
            Group {
                if profiles.isEmpty {
                    emptyState
                } else {
                    profileList
                }
            }
            .navigationTitle(String(localized: "终端"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTerminalSheet { profile in
                    profiles.append(profile)
                    TerminalProfile.save(profiles)
                }
            }
            .sheet(item: $editingProfile) { profile in
                AddTerminalSheet(
                    existing: profile,
                    onSave: { updated in
                        if let idx = profiles.firstIndex(where: { $0.id == updated.id }) {
                            profiles[idx] = updated
                            TerminalProfile.save(profiles)
                        }
                    },
                    onDelete: { toDelete in
                        profiles.removeAll { $0.id == toDelete.id }
                        TerminalProfile.save(profiles)
                    }
                )
            }
        }
    }

    // MARK: - Profile List

    private var sortedProfiles: [TerminalProfile] {
        profiles.sorted { a, b in
            switch (a.lastUsedAt, b.lastUsedAt) {
            case (let la?, let lb?): return la > lb
            case (nil, _?): return false
            case (_?, nil): return true
            case (nil, nil): return a.createdAt > b.createdAt
            }
        }
    }

    private var profileList: some View {
        List {
            ForEach(sortedProfiles) { profile in
                NavigationLink {
                    TerminalView()
                        .onAppear { connectToProfile(profile) }
                        .onDisappear { saveAndDisconnect(profile) }
                } label: {
                    profileRow(profile)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        editingProfile = profile
                    } label: {
                        Label(String(localized: "编辑"), systemImage: "pencil")
                    }
                    .tint(.blue)
                    Button(role: .destructive) {
                        profiles.removeAll { $0.id == profile.id }
                        TerminalProfile.save(profiles)
                    } label: {
                        Label(String(localized: "删除"), systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        editingProfile = profile
                    } label: {
                        Label(String(localized: "编辑"), systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        profiles.removeAll { $0.id == profile.id }
                        TerminalProfile.save(profiles)
                    } label: {
                        Label(String(localized: "删除"), systemImage: "trash")
                    }
                }
            }
            .onDelete { indexSet in
                let ids = indexSet.map { sortedProfiles[$0].id }
                profiles.removeAll { ids.contains($0.id) }
                TerminalProfile.save(profiles)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func profileRow(_ profile: TerminalProfile) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "terminal.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.teal)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.headline)
                    if profile.hasRemote {
                        Image(systemName: "globe")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                if let path = profile.lastPath {
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                } else {
                    Text(subtitle(for: profile))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let used = profile.lastUsedAt {
                Text(used, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func subtitle(for profile: TerminalProfile) -> String {
        if profile.useBonjour {
            return String(localized: "自动发现 · 端口 \(profile.port)")
        }
        if !profile.host.isEmpty {
            return "\(profile.host):\(profile.port)"
        }
        if profile.hasRemote {
            return String(localized: "远程")
        }
        return String(localized: "未配置")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "暂无终端"), systemImage: "terminal")
        } description: {
            Text(String(localized: "点击右上角 + 添加终端"))
        } actions: {
            Button(String(localized: "添加终端")) { showAddSheet = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Lifecycle

    private func connectToProfile(_ profile: TerminalProfile) {
        relay.connectHybrid(profile: profile)
    }

    private func saveAndDisconnect(_ profile: TerminalProfile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            if let path = store.workspacePath {
                profiles[idx].lastPath = path
            }
            profiles[idx].lastUsedAt = Date()
            TerminalProfile.save(profiles)
        }
        relay.disconnect()
        store.resetForNewTerminal()
    }
}
