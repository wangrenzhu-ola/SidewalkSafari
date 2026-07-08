import SwiftUI

struct QuestRunView: View {
    @EnvironmentObject private var store: SafariStore
    let questID: UUID
    @State private var editingClue: ClueTile?
    @State private var showFindMoment = false

    private var quest: SidewalkQuest? { store.quests.first { $0.id == questID } }

    var body: some View {
        ZStack {
            SidewalkBackground()
            if let quest {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ChalkCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(quest.title).font(.largeTitle.bold())
                                Text(quest.routeHint).font(.headline).foregroundStyle(.secondary)
                                ProgressBeads(completed: store.progress(for: quest.id).completedClues, total: quest.clueTiles.count)
                            }
                        }
                        Text("Review your sidewalk clues before the walk.")
                            .font(.headline)
                            .foregroundStyle(ChalkPalette.ink)
                        ForEach(quest.clueTiles.sorted { $0.order < $1.order }) { clue in
                            ClueRunCard(clue: clue, onFound: { store.markClue(clue, status: .found) }, onSkip: { store.markClue(clue, status: .skipped) }, onEdit: { editingClue = clue })
                        }
                        Button("Save a Find Moment") { showFindMoment = true }
                            .buttonStyle(.borderedProminent)
                            .tint(ChalkPalette.berry)
                            .accessibilityIdentifier("saveFindMomentEntry")
                    }
                    .padding(18)
                }
            } else {
                ContentUnavailableView("Safari not found", systemImage: "map", description: Text("This sidewalk safari may have been deleted from Safari Log."))
            }
        }
        .navigationTitle("Quest Run")
        .sheet(item: $editingClue) { clue in EditClueView(clue: clue).environmentObject(store) }
        .sheet(isPresented: $showFindMoment) { FindMomentView(questID: questID).environmentObject(store) }
    }
}

private struct ClueRunCard: View {
    let clue: ClueTile
    let onFound: () -> Void
    let onSkip: () -> Void
    let onEdit: () -> Void

    var body: some View {
        ChalkCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Clue \(clue.order + 1)").font(.caption.bold()).foregroundStyle(ChalkPalette.moss)
                    Spacer()
                    Text(clue.status.label).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 5).background(statusColor.opacity(0.22), in: Capsule())
                }
                Text(clue.prompt).font(.title3.weight(.semibold)).foregroundStyle(ChalkPalette.ink)
                if let hint = clue.optionalHint, !hint.isEmpty { Label(hint, systemImage: "lightbulb").font(.callout) }
                HStack {
                    Button("Found", action: onFound).buttonStyle(.borderedProminent).tint(ChalkPalette.moss)
                    Button("Skip", action: onSkip).buttonStyle(.bordered)
                    Spacer()
                    Button("Edit", action: onEdit).accessibilityIdentifier("editClueButton")
                }
            }
        }
    }

    private var statusColor: Color {
        switch clue.status {
        case .waiting: ChalkPalette.amber
        case .found: ChalkPalette.moss
        case .skipped: .gray
        }
    }
}

struct EditClueView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: SafariStore
    let clue: ClueTile
    @State private var prompt: String
    @State private var hint: String

    init(clue: ClueTile) {
        self.clue = clue
        _prompt = State(initialValue: clue.prompt)
        _hint = State(initialValue: clue.optionalHint ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Add this clue to the safari?") {
                    TextField("Clue prompt", text: $prompt, axis: .vertical)
                    TextField("Optional hint", text: $hint, axis: .vertical)
                }
            }
            .navigationTitle("Edit Clue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updateClue(clue, prompt: prompt, optionalHint: hint.isEmpty ? nil : hint)
                        dismiss()
                    }
                    .accessibilityIdentifier("saveEditedClueButton")
                }
            }
        }
    }
}

struct FindMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: SafariStore
    let questID: UUID
    @State private var note = "We found a tiny sidewalk surprise."
    @State private var moodTag = "Proud"
    @State private var includePhotoPlaceholder = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy notice") {
                    Text(store.privacyBoundaryCopy)
                        .accessibilityIdentifier("findMomentPrivacyCopy")
                }
                Section("Safari Log note") {
                    TextField("Find moment note", text: $note, axis: .vertical)
                    Picker("Mood", selection: $moodTag) {
                        Text("Proud").tag("Proud")
                        Text("Curious").tag("Curious")
                        Text("Silly").tag("Silly")
                    }
                }
                Section("Optional local photo placeholder") {
                    Toggle("Mark that your family saved a local photo outside the app", isOn: $includePhotoPlaceholder)
                    Text("Sidewalk Safari stores only this local placeholder ID and does not upload photos.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let error = store.lastErrorMessage {
                    Section { Text(error).foregroundStyle(.red).accessibilityIdentifier("findMomentSaveError") }
                }
                if let success = store.lastSuccessMessage {
                    Section { Text(success).foregroundStyle(ChalkPalette.moss).accessibilityIdentifier("findMomentSaveSuccess") }
                }
            }
            .navigationTitle("Find Moment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.accessibilityIdentifier("saveFindMomentButton") }
            }
        }
    }

    private func save() {
        do {
            _ = try store.saveFindMoment(questID: questID, note: note, moodTag: moodTag, optionalPhotoLocalIdentifier: includePhotoPlaceholder ? "local-photo-placeholder" : nil)
            dismiss()
        } catch {
            // The store keeps the note intact and exposes the retry copy.
        }
    }
}
