//
//  AppEnvironmentTests.swift
//  RecitoTests
//
//  The UI-test environment: isolated defaults + temp storage, fixture seeding,
//  and reset semantics. Every test gets its own suite and directory.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct AppEnvironmentTests {
    @MainActor private struct Sandbox {
        let suiteName = "recito.tests.env.\(UUID().uuidString)"
        let dir = TempDir()

        func make(_ config: LaunchConfiguration) -> (TalkStore, DisplaySettings, ReaderDependencies) {
            AppEnvironment.make(config, suiteName: suiteName, storageRoot: dir.url)
        }

        func flush() {
            JSONTalkPersistence(directory: dir.url, filename: AppEnvironment.talksFilename).flush()
        }

        func tearDown() {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
            dir.tearDown()
        }
    }

    private func config(_ args: [String], env: [String: String] = [:]) -> LaunchConfiguration {
        LaunchConfiguration.parse(arguments: ["Recito", "-uitest"] + args, environment: env)
    }

    @Test func seedsTheRequestedFixture() {
        let box = Sandbox(); defer { box.tearDown() }
        let (store, _, _) = box.make(config(["-reset", "-seed", "many"]))
        #expect(store.talks.count == 14)
    }

    @Test func defaultsToSamplesWhenNoSeedIsGiven() {
        let box = Sandbox(); defer { box.tearDown() }
        let (store, _, _) = box.make(config(["-reset"]))
        #expect(store.talks.count == SampleTalks.all.count)
    }

    @Test func emptyFixtureStaysEmptyAndIsMarkedSeeded() {
        let box = Sandbox(); defer { box.tearDown() }
        let (store, _, _) = box.make(config(["-reset", "-seed", "empty"]))
        #expect(store.talks.isEmpty)
        box.flush()
        // A relaunch without reset must not fall back to the sample library.
        let (again, _, _) = box.make(config([]))
        #expect(again.talks.isEmpty)
    }

    @Test func stateSurvivesRelaunchWithoutReset() {
        let box = Sandbox(); defer { box.tearDown() }
        let (first, _, _) = box.make(config(["-reset", "-seed", "empty"]))
        first.add(TalkFactory.talk(title: "Kept"))
        box.flush()
        let (second, _, _) = box.make(config(["-seed", "many"]))
        #expect(second.talks.map(\.title) == ["Kept"])
    }

    @Test func resetWipesTalksAndSettings() {
        let box = Sandbox(); defer { box.tearDown() }
        let (first, firstSettings, _) = box.make(config(["-reset", "-seed", "empty", "-theme", "dark"]))
        first.add(TalkFactory.talk(title: "Gone"))
        box.flush()
        #expect(firstSettings.theme == .dark)

        let (second, secondSettings, _) = box.make(config(["-reset", "-seed", "empty"]))
        #expect(second.talks.isEmpty)
        #expect(secondSettings.theme == .system)
    }

    @Test func themeOverrideIsApplied() {
        let box = Sandbox(); defer { box.tearDown() }
        let (_, settings, _) = box.make(config(["-reset", "-theme", "light"]))
        #expect(settings.theme == .light)
    }

    @Test func neverTouchesStandardDefaults() {
        let box = Sandbox(); defer { box.tearDown() }
        UserDefaults.standard.removeObject(forKey: "settings.theme")
        _ = box.make(config(["-reset", "-theme", "dark"]))
        #expect(UserDefaults.standard.string(forKey: "settings.theme") == nil)
    }

    @Test func chromeHideDelayFlowsIntoReaderDependencies() {
        let box = Sandbox(); defer { box.tearDown() }
        let (_, _, deps) = box.make(config(["-reset", "-chromeHideDelay", "0.25"]))
        #expect(deps.chromeHideDelay == 0.25)
    }

    @Test func fakeSpeechIsAvailableAndAuthorized() async {
        let box = Sandbox(); defer { box.tearDown() }
        let (_, _, deps) = box.make(config(["-reset", "-speech", "fake"]))
        let source = deps.speechSourceFactory()
        #expect(source is FakeSpeechSource)
        #expect(source.isAvailable)
        #expect(await source.requestAuthorization())
    }

    @Test func unavailableSpeechOffersNoVoiceFollow() {
        let box = Sandbox(); defer { box.tearDown() }
        let (_, _, deps) = box.make(config(["-reset", "-speech", "unavailable"]))
        #expect(!deps.speechSourceFactory().isAvailable)
    }

    @Test func fakeSpeechCarriesScriptedWordsFromTheEnvironment() {
        let box = Sandbox(); defer { box.tearDown() }
        let cfg = config(["-reset"], env: ["RECITO_FAKE_SPEECH_WORDS": "a b"])
        let (_, _, deps) = box.make(cfg)
        let source = deps.speechSourceFactory() as? FakeSpeechSource
        #expect(source?.script == ["a", "b"])
    }
}

@MainActor
struct UITestFixturesTests {
    @Test func samplesMirrorTheBuiltInLibraryWithStableIDs() {
        let first = UITestFixture.samples.talks
        let second = UITestFixture.samples.talks
        #expect(first.count == SampleTalks.all.count)
        #expect(first.map(\.id) == second.map(\.id))
        #expect(Set(first.map(\.id)).count == first.count)
    }

    @Test func emptyHasNoTalks() {
        #expect(UITestFixture.empty.talks.isEmpty)
    }

    @Test func longScriptHasSixtyParagraphsThreeHeadingsTwoLinkedCitations() {
        let talk = UITestFixture.longScript.talks[0]
        let parsed = talk.parsed
        #expect(parsed.scriptSections.filter { !$0.isHeading }.count >= 60)
        #expect(parsed.scriptSections.filter(\.isHeading).count == 3)
        #expect(parsed.allCitations.filter { $0.citation.isLinked }.count == 2)
    }

    @Test func outlineHasTwelvePointsTwoLevelsOneCitation() {
        let talk = UITestFixture.outline.talks[0]
        let nodes = talk.parsed.outlineNodes
        #expect(talk.preferredMode == .outline)
        #expect(nodes.count == 12)
        #expect(Set(nodes.map(\.level)) == [0, 1])
        #expect(nodes.flatMap(\.citations).filter(\.isLinked).count == 1)
    }

    @Test func manyHasFourteenUniqueTalks() {
        let talks = UITestFixture.many.talks
        #expect(talks.count == 14)
        #expect(Set(talks.map(\.id)).count == 14)
        #expect(Set(talks.map(\.title)).count == 14)
    }

    @Test func mixedHiddenIsAllVaultTalksWithTwoHidden() {
        let talks = UITestFixture.mixedHidden.talks
        #expect(talks.allSatisfy { $0.source.isVault })
        #expect(talks.filter(\.isHidden).count == 2)
        #expect(talks.filter { !$0.isHidden }.count >= 3)
    }

    @Test func firstTalkIDIsAddressableByOpenTalk() {
        let talks = UITestFixture.longScript.talks
        #expect(talks[0].id == UITestFixture.talkID(1))
        #expect(UITestFixture.talkID(1).uuidString.hasSuffix("000000000001"))
    }
}
