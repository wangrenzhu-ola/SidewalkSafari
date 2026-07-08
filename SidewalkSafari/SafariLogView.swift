import SwiftUI

struct SafariLogView: View {
    @EnvironmentObject private var store: SafariStore
    @State private var questPendingDelete: SidewalkQuest?

    var body: some View {
        ZStack {
            SidewalkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if store.findMoments.isEmpty {
                        EmptySidewalkIllustration()
                        Text("Your Safari Log will show saved find moments after a walk.")
                            .font(.headline)
                            .foregroundStyle(ChalkPalette.ink)
                    }
                    ForEach(store.quests) { quest in
                        ChalkCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(quest.title).font(.title3.bold())
                                        Text("\(store.moments(for: quest.id).count) find moments")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    BadgeStrip(progress: store.progress(for: quest.id))
                                }
                                ForEach(store.moments(for: quest.id)) { moment in
                                    Label("\(moment.moodTag): \(moment.note)", systemImage: "pawprint.circle")
                                        .font(.callout)
                                }
                                Button(role: .destructive) { questPendingDelete = quest } label: {
                                    Label("Delete Quest", systemImage: "trash")
                                }
                                .accessibilityIdentifier("deleteQuestButton")
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
        .navigationTitle("Safari Log")
        .confirmationDialog(
            "Delete this sidewalk safari?",
            isPresented: Binding(get: { questPendingDelete != nil }, set: { if !$0 { questPendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            if let quest = questPendingDelete {
                Button("Delete \(quest.title)", role: .destructive) {
                    store.deleteQuest(quest)
                    questPendingDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { questPendingDelete = nil }
        } message: {
            if let quest = questPendingDelete {
                Text("Delete this sidewalk safari? It has \(quest.clueTiles.filter { $0.status == .found }.count) completed clues.")
            }
        }
    }
}

private struct BadgeStrip: View {
    let progress: BadgeProgress

    var body: some View {
        HStack(spacing: -4) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < max(1, min(progress.completedClues, 3)) ? "seal.fill" : "seal")
                    .foregroundStyle(index < progress.completedClues ? ChalkPalette.berry : ChalkPalette.amber)
            }
        }
        .accessibilityLabel("Safari Log badge strip: \(progress.badgeName)")
    }
}
