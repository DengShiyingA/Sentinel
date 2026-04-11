import SwiftUI

struct ContentView: View {
    @State private var onboarded = UserDefaults.standard.bool(forKey: "sentinel.onboarded")

    var body: some View {
        if !onboarded {
            OnboardingView(isComplete: $onboarded)
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @Environment(ApprovalStore.self) private var store
    private let errorBus = ErrorBus.shared

    var body: some View {
        TabView {
            TerminalListView()
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
