//
//  TalkStoreTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct TalkStoreTests {
    private func store(
        _ initial: [Talk] = []
    ) -> (TalkStore, InMemoryPersistence, IsolatedDefaults) {
        let persistence = InMemoryPersistence(initial)
        let iso = IsolatedDefaults()
        return (TalkStore(persistence: persistence, vault: VaultFolder(defaults: iso.defaults)), persistence, iso)
    }

    @Test func loadsInitialTalksFromPersistence() {
        let (s, _, iso) = store([TalkFactory.talk(title: "A")]); defer { iso.tearDown() }
        #expect(s.talks.map(\.title) == ["A"])
    }

    @Test func addInsertsAtFrontAndPersists() {
        let (s, p, iso) = store([TalkFactory.talk(title: "Old")]); defer { iso.tearDown() }
        s.add(TalkFactory.talk(title: "New"))
        #expect(s.talks.map(\.title) == ["New", "Old"])
        #expect(p.stored.map(\.title) == ["New", "Old"])
    }

    @Test func updateReplacesMatchingTalk() {
        var talk = TalkFactory.talk(title: "Before")
        let (s, p, iso) = store([talk]); defer { iso.tearDown() }
        talk.title = "After"
        s.update(talk)
        #expect(s.talks.first?.title == "After")
        #expect(p.stored.first?.title == "After")
    }

    @Test func updateOfUnknownTalkIsANoOp() {
        let (s, p, iso) = store(); defer { iso.tearDown() }
        s.update(TalkFactory.talk())
        #expect(s.talks.isEmpty)
        #expect(p.saveCount == 0)
    }

    @Test func deleteRemovesAndPersists() {
        let talk = TalkFactory.talk()
        let (s, p, iso) = store([talk]); defer { iso.tearDown() }
        s.delete(talk)
        #expect(s.talks.isEmpty)
        #expect(p.stored.isEmpty)
    }

    @Test func markOpenedBumpsLastOpened() {
        let talk = TalkFactory.talk()
        let (s, _, iso) = store([talk]); defer { iso.tearDown() }
        s.markOpened(talk.id)
        #expect(s.talks[0].lastOpenedAt > talk.lastOpenedAt)
    }

    @Test func markOpenedUnknownIDDoesNotPersist() {
        let (s, p, iso) = store(); defer { iso.tearDown() }
        s.markOpened(UUID())
        #expect(p.saveCount == 0)
    }

    @Test func setHiddenTogglesVisibility() {
        let talk = TalkFactory.talk()
        let (s, p, iso) = store([talk]); defer { iso.tearDown() }
        s.setHidden(true, for: talk.id)
        #expect(s.talks[0].isHidden)
        #expect(p.stored[0].isHidden)
        s.setHidden(false, for: talk.id)
        #expect(!s.talks[0].isHidden)
    }

    @Test func talkLookupByID() {
        let talk = TalkFactory.talk()
        let (s, _, iso) = store([talk]); defer { iso.tearDown() }
        #expect(s.talk(with: talk.id) == talk)
        #expect(s.talk(with: UUID()) == nil)
    }

    @Test func seedReplacesTheLibrary() {
        let (s, p, iso) = store([TalkFactory.talk(title: "Old")]); defer { iso.tearDown() }
        s.seed([TalkFactory.talk(title: "Seeded")])
        #expect(s.talks.map(\.title) == ["Seeded"])
        #expect(p.stored.map(\.title) == ["Seeded"])
    }

    @Test func applyVaultMergeAdoptsMergedList() {
        let (s, p, iso) = store(); defer { iso.tearDown() }
        let merged = [TalkFactory.talk(title: "From vault", source: .vault(relativePath: "a.md"))]
        s.applyVaultMerge(merged)
        #expect(s.talks == merged)
        #expect(p.stored == merged)
    }

    // MARK: First-run seeding

    @Test func firstRunSeedsSamplesAndMarksDefaults() {
        let (s, _, iso) = store(); defer { iso.tearDown() }
        s.seedSamplesIfFirstRun(defaults: iso.defaults)
        #expect(s.talks.count == SampleTalks.all.count)
        #expect(iso.defaults.bool(forKey: TalkStore.didSeedKey))
    }

    @Test func secondRunDoesNotReseedAfterUserDeletesEverything() {
        let (s, _, iso) = store(); defer { iso.tearDown() }
        s.seedSamplesIfFirstRun(defaults: iso.defaults)
        s.seed([])
        s.seedSamplesIfFirstRun(defaults: iso.defaults)
        #expect(s.talks.isEmpty)
    }

    @Test func firstRunKeepsExistingTalksButStillMarksSeeded() {
        let (s, _, iso) = store([TalkFactory.talk(title: "Mine")]); defer { iso.tearDown() }
        s.seedSamplesIfFirstRun(defaults: iso.defaults)
        #expect(s.talks.map(\.title) == ["Mine"])
        #expect(iso.defaults.bool(forKey: TalkStore.didSeedKey))
    }

    @Test func seedingUsesTheGivenDefaultsNotStandard() {
        let (s, _, iso) = store(); defer { iso.tearDown() }
        let before = UserDefaults.standard.bool(forKey: TalkStore.didSeedKey)
        s.seedSamplesIfFirstRun(defaults: iso.defaults)
        #expect(UserDefaults.standard.bool(forKey: TalkStore.didSeedKey) == before)
    }
}
