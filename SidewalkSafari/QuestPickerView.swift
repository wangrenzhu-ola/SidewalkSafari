import SwiftUI

struct QuestPickerView: View {
    @EnvironmentObject private var store: SafariStore
    @Binding var selectedQuest: SidewalkQuest?
    @State private var showCreateQuest = false

    var body: some View {
        ZStack {
            SidewalkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Pick a starter quest or make your first sidewalk safari.")
                        .font(.title2.bold())
                        .foregroundStyle(ChalkPalette.ink)
                        .accessibilityIdentifier("questPickerEmptyGuidance")
                    if store.quests.isEmpty {
                        EmptySidewalkIllustration()
                        Button("Restore starter quests", action: store.restoreStarterQuests)
                            .buttonStyle(.bordered)
                    }
                    ForEach(store.quests) { quest in
                        Button { selectedQuest = quest } label: {
                            QuestShelfCard(quest: quest, progress: store.progress(for: quest.id))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("questCard_\(quest.title)")
                    }
                }
                .padding(18)
            }
        }
        .navigationTitle("Quest Picker")
        .toolbar { Button("Create Quest") { showCreateQuest = true }.accessibilityIdentifier("createQuestButton") }
        .sheet(isPresented: $showCreateQuest) { CreateQuestView().environmentObject(store) }
    }
}

private struct QuestShelfCard: View {
    let quest: SidewalkQuest
    let progress: BadgeProgress

    var body: some View {
        ChalkCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(quest.title).font(.title3.bold())
                    Spacer()
                    Text(progress.badgeName).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6).background(ChalkPalette.amber.opacity(0.26), in: Capsule())
                }
                Text(quest.routeHint).font(.callout).foregroundStyle(.secondary)
                ProgressBeads(completed: progress.completedClues, total: quest.clueTiles.count)
                Label("\(quest.clueTiles.count) clues • \(quest.theme.capitalized) theme", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ChalkPalette.moss)
            }
        }
    }
}

struct CreateQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: SafariStore
    @State private var title = "After-School Sidewalk Safari"
    @State private var routeHint = "Use the walk from school to the corner store."
    @State private var clueOne = "Find a window with a reflection."
    @State private var clueTwo = "Spot a tiny plant growing through concrete."
    @State private var clueThree = "Hear a sound before you see what made it."

    var body: some View {
        NavigationStack {
            Form {
                Section("Safari route") {
                    TextField("Quest title", text: $title)
                    TextField("Route hint", text: $routeHint, axis: .vertical)
                }
                Section("Add this clue to the safari?") {
                    TextField("First clue", text: $clueOne)
                    TextField("Second clue", text: $clueTwo)
                    TextField("Third clue", text: $clueThree)
                }
            }
            .navigationTitle("Create Quest")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        _ = store.createQuest(title: title, routeHint: routeHint, theme: "chalk", cluePrompts: [clueOne, clueTwo, clueThree].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
                        dismiss()
                    }
                    .accessibilityIdentifier("saveCustomQuestButton")
                }
            }
        }
    }
}
