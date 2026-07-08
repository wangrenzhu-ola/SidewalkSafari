import Foundation
import Combine

enum ClueStatus: String, Codable, CaseIterable, Equatable, Hashable {
    case waiting
    case found
    case skipped

    var label: String {
        switch self {
        case .waiting: "Waiting"
        case .found: "Found"
        case .skipped: "Skipped"
        }
    }
}

struct ClueTile: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var questId: UUID
    var prompt: String
    var status: ClueStatus
    var order: Int
    var optionalHint: String?

    init(id: UUID = UUID(), questId: UUID, prompt: String, status: ClueStatus = .waiting, order: Int, optionalHint: String? = nil) {
        self.id = id
        self.questId = questId
        self.prompt = prompt
        self.status = status
        self.order = order
        self.optionalHint = optionalHint
    }
}

struct SidewalkQuest: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var routeHint: String
    var theme: String
    var clueTiles: [ClueTile]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, routeHint: String, theme: String, clueTiles: [ClueTile] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.routeHint = routeHint
        self.theme = theme
        self.clueTiles = clueTiles.sorted { $0.order < $1.order }
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct FindMoment: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var questId: UUID
    var note: String
    var optionalPhotoLocalIdentifier: String?
    var moodTag: String
    var savedAt: Date

    init(id: UUID = UUID(), questId: UUID, note: String, optionalPhotoLocalIdentifier: String? = nil, moodTag: String, savedAt: Date = Date()) {
        self.id = id
        self.questId = questId
        self.note = note
        self.optionalPhotoLocalIdentifier = optionalPhotoLocalIdentifier
        self.moodTag = moodTag
        self.savedAt = savedAt
    }
}

struct BadgeProgress: Identifiable, Codable, Equatable, Hashable {
    var id: UUID { questId }
    var questId: UUID
    var completedClues: Int
    var badgeName: String
    var replayCount: Int
}

struct PremiumEntitlementCache: Codable, Equatable, Hashable {
    var themePackId: String
    var entitlementState: EntitlementState
    var lastCheckedAt: Date

    enum EntitlementState: String, Codable, Equatable {
        case unknown
        case unavailable
        case previewOnly
        case verifiedPurchased
    }
}

struct PersistedSafariData: Codable, Equatable {
    var quests: [SidewalkQuest]
    var findMoments: [FindMoment]
    var badgeProgress: [BadgeProgress]
    var premiumCache: PremiumEntitlementCache
}

enum SafariStoreError: LocalizedError, Equatable {
    case simulatedPersistenceFailure
    case questMissing

    var errorDescription: String? {
        switch self {
        case .simulatedPersistenceFailure: "Couldn’t save this find moment. Try again."
        case .questMissing: "This sidewalk safari is no longer available."
        }
    }
}

enum StarterQuestFactory {
    static func quests(now: Date = Date()) -> [SidewalkQuest] {
        let colorHunt = UUID()
        let soundSteps = UUID()
        let tinySigns = UUID()
        return [
            SidewalkQuest(
                id: colorHunt,
                title: "Color Hunt",
                routeHint: "Walk one calm block and collect cheerful colors from doors, signs, flowers, and chalk marks.",
                theme: "chalk",
                clueTiles: [
                    ClueTile(questId: colorHunt, prompt: "Find a red door or a bright welcome mat.", order: 0, optionalHint: "Look at porches and apartment entries."),
                    ClueTile(questId: colorHunt, prompt: "Spot something sky blue above the sidewalk.", order: 1, optionalHint: "Try signs, bikes, shutters, or painted trim."),
                    ClueTile(questId: colorHunt, prompt: "Choose the friendliest green plant by the curb.", order: 2, optionalHint: "A tiny weed can count if your explorer likes it.")
                ],
                createdAt: now,
                updatedAt: now
            ),
            SidewalkQuest(
                id: soundSteps,
                title: "Sound Steps",
                routeHint: "Use the next errand walk to notice sounds before you name what made them.",
                theme: "sky",
                clueTiles: [
                    ClueTile(questId: soundSteps, prompt: "Hear three street sounds and tap a bead for each favorite.", order: 0),
                    ClueTile(questId: soundSteps, prompt: "Find a quiet spot and whisper what changed.", order: 1),
                    ClueTile(questId: soundSteps, prompt: "Guess a sound source before turning the corner.", order: 2)
                ],
                createdAt: now,
                updatedAt: now
            ),
            SidewalkQuest(
                id: tinySigns,
                title: "Tiny Signs",
                routeHint: "Look close at numbers, arrows, cracks, stickers, shadows, and little sidewalk surprises.",
                theme: "pebble",
                clueTiles: [
                    ClueTile(questId: tinySigns, prompt: "Find a crack shaped like a river.", order: 0),
                    ClueTile(questId: tinySigns, prompt: "Spot a number with a curved digit.", order: 1, optionalHint: "Try 2, 3, 6, 8, or 9."),
                    ClueTile(questId: tinySigns, prompt: "Point to a tiny sign that tells walkers what to do.", order: 2)
                ],
                createdAt: now,
                updatedAt: now
            )
        ]
    }
}

@MainActor
final class SafariStore: ObservableObject {
    @Published private(set) var quests: [SidewalkQuest]
    @Published private(set) var findMoments: [FindMoment]
    @Published private(set) var badgeProgress: [BadgeProgress]
    @Published private(set) var premiumCache: PremiumEntitlementCache
    @Published var lastErrorMessage: String?
    @Published var lastSuccessMessage: String?
    @Published var simulateNextSaveFailure = false

    let storeURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(storeURL: URL? = nil, seedOnFirstLaunch: Bool = true) {
        self.storeURL = storeURL ?? Self.defaultStoreURL()
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        let fallbackCache = PremiumEntitlementCache(themePackId: "sidewalk.chalk.themepack", entitlementState: .unavailable, lastCheckedAt: Date())
        if let data = try? Data(contentsOf: self.storeURL), let decoded = try? decoder.decode(PersistedSafariData.self, from: data) {
            quests = decoded.quests
            findMoments = decoded.findMoments
            badgeProgress = decoded.badgeProgress
            premiumCache = decoded.premiumCache
        } else {
            let initialQuests = seedOnFirstLaunch ? StarterQuestFactory.quests() : []
            quests = initialQuests
            findMoments = []
            badgeProgress = initialQuests.map { BadgeProgress(questId: $0.id, completedClues: 0, badgeName: "Ready Explorer", replayCount: 0) }
            premiumCache = fallbackCache
            persistIgnoringErrors()
        }
    }

    static func defaultStoreURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("sidewalk-safari-store.json")
    }

    func createQuest(title: String, routeHint: String, theme: String, cluePrompts: [String]) -> SidewalkQuest {
        let questID = UUID()
        let now = Date()
        let clues = cluePrompts.enumerated().map { index, prompt in
            ClueTile(questId: questID, prompt: prompt, order: index)
        }
        let quest = SidewalkQuest(id: questID, title: title, routeHint: routeHint, theme: theme, clueTiles: clues, createdAt: now, updatedAt: now)
        quests.insert(quest, at: 0)
        badgeProgress.append(BadgeProgress(questId: quest.id, completedClues: 0, badgeName: "Ready Explorer", replayCount: 0))
        persistIgnoringErrors()
        return quest
    }

    func updateQuest(_ quest: SidewalkQuest, title: String, routeHint: String, theme: String) {
        guard let index = quests.firstIndex(where: { $0.id == quest.id }) else { return }
        quests[index].title = title
        quests[index].routeHint = routeHint
        quests[index].theme = theme
        quests[index].updatedAt = Date()
        persistIgnoringErrors()
    }

    func addClue(to questID: UUID, prompt: String, optionalHint: String? = nil) {
        guard let index = quests.firstIndex(where: { $0.id == questID }) else { return }
        let nextOrder = (quests[index].clueTiles.map(\.order).max() ?? -1) + 1
        quests[index].clueTiles.append(ClueTile(questId: questID, prompt: prompt, order: nextOrder, optionalHint: optionalHint))
        quests[index].updatedAt = Date()
        persistIgnoringErrors()
    }

    func updateClue(_ clue: ClueTile, prompt: String, optionalHint: String?) {
        guard let questIndex = quests.firstIndex(where: { $0.id == clue.questId }), let clueIndex = quests[questIndex].clueTiles.firstIndex(where: { $0.id == clue.id }) else { return }
        quests[questIndex].clueTiles[clueIndex].prompt = prompt
        quests[questIndex].clueTiles[clueIndex].optionalHint = optionalHint
        quests[questIndex].updatedAt = Date()
        persistIgnoringErrors()
    }

    func markClue(_ clue: ClueTile, status: ClueStatus) {
        guard let questIndex = quests.firstIndex(where: { $0.id == clue.questId }), let clueIndex = quests[questIndex].clueTiles.firstIndex(where: { $0.id == clue.id }) else { return }
        quests[questIndex].clueTiles[clueIndex].status = status
        quests[questIndex].updatedAt = Date()
        updateBadge(for: clue.questId)
        persistIgnoringErrors()
    }

    func saveFindMoment(questID: UUID, note: String, moodTag: String, optionalPhotoLocalIdentifier: String? = nil) throws -> FindMoment {
        guard quests.contains(where: { $0.id == questID }) else { throw SafariStoreError.questMissing }
        if simulateNextSaveFailure {
            simulateNextSaveFailure = false
            lastErrorMessage = SafariStoreError.simulatedPersistenceFailure.errorDescription
            throw SafariStoreError.simulatedPersistenceFailure
        }
        let moment = FindMoment(questId: questID, note: note, optionalPhotoLocalIdentifier: optionalPhotoLocalIdentifier, moodTag: moodTag)
        findMoments.insert(moment, at: 0)
        incrementReplay(for: questID)
        try persist()
        lastErrorMessage = nil
        lastSuccessMessage = "Find moment saved to Safari Log."
        return moment
    }

    func deleteQuest(_ quest: SidewalkQuest) {
        quests.removeAll { $0.id == quest.id }
        findMoments.removeAll { $0.questId == quest.id }
        badgeProgress.removeAll { $0.questId == quest.id }
        persistIgnoringErrors()
    }

    func updateFindMoment(_ moment: FindMoment, note: String, moodTag: String, optionalPhotoLocalIdentifier: String? = nil) {
        guard let index = findMoments.firstIndex(where: { $0.id == moment.id }) else { return }
        findMoments[index].note = note
        findMoments[index].moodTag = moodTag
        findMoments[index].optionalPhotoLocalIdentifier = optionalPhotoLocalIdentifier
        findMoments[index].savedAt = Date()
        persistIgnoringErrors()
    }

    func deleteFindMoment(_ moment: FindMoment) {
        findMoments.removeAll { $0.id == moment.id }
        persistIgnoringErrors()
    }

    func resetToEmptyShelf() {
        quests = []
        findMoments = []
        badgeProgress = []
        persistIgnoringErrors()
    }

    func restoreStarterQuests() {
        quests = StarterQuestFactory.quests()
        findMoments = []
        badgeProgress = quests.map { BadgeProgress(questId: $0.id, completedClues: 0, badgeName: "Ready Explorer", replayCount: 0) }
        persistIgnoringErrors()
    }

    func progress(for questID: UUID) -> BadgeProgress {
        badgeProgress.first(where: { $0.questId == questID }) ?? BadgeProgress(questId: questID, completedClues: 0, badgeName: "Ready Explorer", replayCount: 0)
    }

    func moments(for questID: UUID) -> [FindMoment] {
        findMoments.filter { $0.questId == questID }
    }

    var privacyBoundaryCopy: String {
        "Your child’s clues, notes, and optional photo placeholders stay on this device. Sidewalk Safari does not upload location, child data, photos, or prompts."
    }

    var storeKitUnavailableCopy: String {
        "Theme packs are in preview because StoreKit is unavailable right now. Starter quests, custom clues, and Safari Log stay usable."
    }

    private func updateBadge(for questID: UUID) {
        let completed = quests.first(where: { $0.id == questID })?.clueTiles.filter { $0.status == .found }.count ?? 0
        if let index = badgeProgress.firstIndex(where: { $0.questId == questID }) {
            badgeProgress[index].completedClues = completed
            badgeProgress[index].badgeName = completed >= 3 ? "Block Explorer" : completed > 0 ? "Clue Finder" : "Ready Explorer"
        } else {
            badgeProgress.append(BadgeProgress(questId: questID, completedClues: completed, badgeName: "Clue Finder", replayCount: 0))
        }
    }

    private func incrementReplay(for questID: UUID) {
        if let index = badgeProgress.firstIndex(where: { $0.questId == questID }) {
            badgeProgress[index].replayCount += 1
        } else {
            badgeProgress.append(BadgeProgress(questId: questID, completedClues: 0, badgeName: "Safari Logger", replayCount: 1))
        }
    }

    private func persistIgnoringErrors() {
        do { try persist() } catch { lastErrorMessage = error.localizedDescription }
    }

    private func persist() throws {
        let data = PersistedSafariData(quests: quests, findMoments: findMoments, badgeProgress: badgeProgress, premiumCache: premiumCache)
        let encoded = try encoder.encode(data)
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: storeURL, options: [.atomic])
    }
}
