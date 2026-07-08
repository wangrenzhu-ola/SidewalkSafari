import SwiftUI

struct AppView: View {
    @EnvironmentObject private var store: SafariStore
    @State private var selectedQuest: SidewalkQuest?
    @State private var showOnboarding = true

    var body: some View {
        TabView {
            NavigationStack {
                QuestPickerView(selectedQuest: $selectedQuest)
                    .navigationDestination(item: $selectedQuest) { quest in
                        QuestRunView(questID: quest.id)
                    }
            }
            .tabItem { Label("Quests", systemImage: "map") }

            NavigationStack { SafariLogView() }
                .tabItem { Label("Safari Log", systemImage: "book.pages") }

            NavigationStack { PremiumPreviewView() }
                .tabItem { Label("Themes", systemImage: "paintpalette") }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
                .environmentObject(store)
        }
    }
}
