import SwiftUI

struct SafariLogView: View {
    @EnvironmentObject private var store: SafariStore
    @State private var questPendingDelete: SidewalkQuest?
    @State private var questPendingEdit: SidewalkQuest?
    @State private var findMomentPendingEdit: FindMoment?

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
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("\(moment.moodTag): \(moment.note)", systemImage: "pawprint.circle")
                                            .font(.callout)
                                        if moment.optionalPhotoLocalIdentifier != nil {
                                            Label("Local photo placeholder saved on this device.", systemImage: "photo")
                                                .font(.caption)
                                                .foregroundStyle(ChalkPalette.moss)
                                        }
                                        HStack {
                                            Button("Edit Moment") { findMomentPendingEdit = moment }
                                                .accessibilityIdentifier("editFindMomentButton")
                                            Button(role: .destructive) {
                                                store.deleteFindMoment(moment)
                                            } label: {
                                                Text("Delete Moment")
                                            }
                                            .accessibilityIdentifier("deleteFindMomentButton")
                                        }
                                        .font(.caption.weight(.semibold))
                                    }
                                }
                                Button("Edit Quest") { questPendingEdit = quest }
                                    .accessibilityIdentifier("editQuestButton")
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
        .sheet(item: $questPendingEdit) { quest in
            EditQuestView(quest: quest)
                .environmentObject(store)
        }
        .sheet(item: $findMomentPendingEdit) { moment in
            EditFindMomentView(moment: moment)
                .environmentObject(store)
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

private struct EditQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: SafariStore
    let quest: SidewalkQuest
    @State private var title: String
    @State private var routeHint: String
    @State private var theme: String

    init(quest: SidewalkQuest) {
        self.quest = quest
        _title = State(initialValue: quest.title)
        _routeHint = State(initialValue: quest.routeHint)
        _theme = State(initialValue: quest.theme)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Review your sidewalk clues before the walk.") {
                    TextField("Quest title", text: $title)
                    TextField("Route hint", text: $routeHint, axis: .vertical)
                    TextField("Theme", text: $theme)
                }
            }
            .navigationTitle("Edit Quest")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateQuest(quest, title: title, routeHint: routeHint, theme: theme)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct EditFindMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: SafariStore
    let moment: FindMoment
    @State private var note: String
    @State private var moodTag: String
    @State private var includePhotoPlaceholder: Bool

    init(moment: FindMoment) {
        self.moment = moment
        _note = State(initialValue: moment.note)
        _moodTag = State(initialValue: moment.moodTag)
        _includePhotoPlaceholder = State(initialValue: moment.optionalPhotoLocalIdentifier != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Find moment") {
                    TextField("Find moment note", text: $note, axis: .vertical)
                    Picker("Mood", selection: $moodTag) {
                        Text("Proud").tag("Proud")
                        Text("Curious").tag("Curious")
                        Text("Silly").tag("Silly")
                    }
                    Toggle("Keep local photo placeholder", isOn: $includePhotoPlaceholder)
                }
                Section("Privacy notice") {
                    Text(store.privacyBoundaryCopy)
                }
            }
            .navigationTitle("Edit Moment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateFindMoment(
                            moment,
                            note: note,
                            moodTag: moodTag,
                            optionalPhotoLocalIdentifier: includePhotoPlaceholder ? "local-photo-placeholder" : nil
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
