import XCTest
@testable import SidewalkSafari

@MainActor
final class SidewalkSafariTests: XCTestCase {
    func makeStore() -> SafariStore {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sidewalk-safari-\(UUID().uuidString).json")
        return SafariStore(storeURL: url, seedOnFirstLaunch: false)
    }

    func testCreateEditDeleteQuestAndClue() throws {
        let store = makeStore()
        let quest = store.createQuest(title: "Corner Store Safari", routeHint: "Walk to the corner and back.", theme: "chalk", cluePrompts: ["Find a red door", "Spot a curved number"])
        XCTAssertEqual(store.quests.count, 1)
        XCTAssertEqual(store.quests[0].clueTiles.count, 2)
        store.updateQuest(quest, title: "Corner Store Quest", routeHint: "Use the shady side of the block.", theme: "leaf")
        XCTAssertEqual(store.quests[0].title, "Corner Store Quest")
        let clue = try XCTUnwrap(store.quests[0].clueTiles.first)
        store.updateClue(clue, prompt: "Find a blue mailbox", optionalHint: "Look near the curb")
        XCTAssertEqual(store.quests[0].clueTiles[0].prompt, "Find a blue mailbox")
        store.deleteQuest(store.quests[0])
        XCTAssertTrue(store.quests.isEmpty)
    }

    func testFindMomentPersistsAcrossRelaunch() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sidewalk-safari-persist-\(UUID().uuidString).json")
        let store = SafariStore(storeURL: url, seedOnFirstLaunch: false)
        let quest = store.createQuest(title: "Leaf Safari", routeHint: "Walk under the maple trees.", theme: "leaf", cluePrompts: ["Find three leaf shapes"])
        store.markClue(store.quests[0].clueTiles[0], status: .found)
        _ = try store.saveFindMoment(questID: quest.id, note: "We found a tiny yellow leaf.", moodTag: "Curious")
        let relaunched = SafariStore(storeURL: url, seedOnFirstLaunch: false)
        XCTAssertEqual(relaunched.quests.first?.title, "Leaf Safari")
        XCTAssertEqual(relaunched.findMoments.first?.note, "We found a tiny yellow leaf.")
        XCTAssertEqual(relaunched.progress(for: quest.id).completedClues, 1)
    }

    func testEditAndDeleteFindMoment() throws {
        let store = makeStore()
        let quest = store.createQuest(title: "Tiny Signs", routeHint: "Walk to the bus stop.", theme: "pebble", cluePrompts: ["Find a curved number"])
        let moment = try store.saveFindMoment(questID: quest.id, note: "We saw the number 8.", moodTag: "Curious", optionalPhotoLocalIdentifier: "local-photo-placeholder")
        store.updateFindMoment(moment, note: "We saw the number 8 on a door.", moodTag: "Proud", optionalPhotoLocalIdentifier: nil)
        XCTAssertEqual(store.findMoments.first?.note, "We saw the number 8 on a door.")
        XCTAssertNil(store.findMoments.first?.optionalPhotoLocalIdentifier)
        store.deleteFindMoment(try XCTUnwrap(store.findMoments.first))
        XCTAssertTrue(store.findMoments.isEmpty)
    }

    func testRequiredStarterQuestNames() {
        let names = StarterQuestFactory.quests().map(\.title)
        XCTAssertEqual(names, ["Color Hunt", "Sound Steps", "Tiny Signs"])
    }

    func testSaveFailureKeepsRecoveryCopyAndRetryPath() throws {
        let store = makeStore()
        let quest = store.createQuest(title: "Door Safari", routeHint: "One block", theme: "chalk", cluePrompts: ["Find a red door"])
        store.simulateNextSaveFailure = true
        XCTAssertThrowsError(try store.saveFindMoment(questID: quest.id, note: "Keep this note", moodTag: "Proud"))
        XCTAssertEqual(store.lastErrorMessage, "Couldn’t save this find moment. Try again.")
        _ = try store.saveFindMoment(questID: quest.id, note: "Keep this note", moodTag: "Proud")
        XCTAssertEqual(store.lastSuccessMessage, "Find moment saved to Safari Log.")
        XCTAssertEqual(store.findMoments.first?.note, "Keep this note")
    }

    func testPrivacyAndPremiumFallbackCopyAreEnUSAndLocalFirst() {
        let store = makeStore()
        XCTAssertTrue(store.privacyBoundaryCopy.contains("stay on this device"))
        XCTAssertTrue(store.privacyBoundaryCopy.contains("does not upload"))
        XCTAssertTrue(store.storeKitUnavailableCopy.contains("StoreKit is unavailable"))
        XCTAssertTrue(store.storeKitUnavailableCopy.contains("Starter quests"))
    }
}
