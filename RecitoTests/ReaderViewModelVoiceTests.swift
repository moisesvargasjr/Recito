//
//  ReaderViewModelVoiceTests.swift
//  RecitoTests
//
//  Voice-follow orchestration: permission, start/stop, recognition feeding the
//  predictor, and the stall freeze — via SpySpeechSource + ManualTicker.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelVoiceTests {
    private func harness(
        _ text: String = TalkFactory.voiceScript,
        mode: DocumentMode = .script
    ) -> ReaderHarness {
        ReaderHarness(talk: TalkFactory.talk(text: text, mode: mode))
    }

    private func started(_ h: ReaderHarness) async -> ReaderHarness {
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        return h
    }

    // MARK: Start / permission

    @Test func startRequestsPermissionThenListens() async {
        let h = await started(harness())
        #expect(h.speech.authorizationRequests == 1)
        #expect(h.speech.startCount == 1)
        #expect(h.speech.lastLocale == "en-US")
        #expect(h.vm.voiceFollowActive)
        #expect(h.vm.voiceStatus == "Starting…")
        #expect(h.ticker.isRunning)
        #expect(!h.vm.isPlaying)
    }

    @Test func deniedPermissionDoesNotStart() async {
        let h = harness()
        h.speech.authorizationResult = false
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(!h.vm.voiceFollowActive)
        #expect(h.speech.startCount == 0)
        #expect(h.vm.voiceStatus.contains("denied"))
    }

    @Test func outlineModeCannotStartVoice() async {
        let h = harness(TalkFactory.outline, mode: .outline)
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(h.speech.authorizationRequests == 0)
        #expect(h.vm.voiceStatus == "Voice-follow needs script mode on a supported device.")
    }

    @Test func unavailableDeviceCannotStartVoice() async {
        let h = harness()
        h.speech.isAvailable = false
        let vm = ReaderViewModel(talk: TalkFactory.talk(text: TalkFactory.voiceScript), speechSource: h.speech)
        await vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(!vm.voiceAvailable)
        #expect(!vm.voiceFollowActive)
        #expect(h.speech.authorizationRequests == 0)
    }

    @Test func startFailureRollsBack() async {
        let h = harness()
        h.speech.startError = SpyStartFailure()
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(!h.vm.voiceFollowActive)
        #expect(h.vm.voiceStatus == "Couldn't start: mic busy")
        #expect(h.speech.stopCount == 1)
    }

    @Test func startFailureStopsThePacingClock() async {
        let h = harness()
        h.speech.startError = SpyStartFailure()
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(!h.ticker.isRunning)
        h.ticker.fire(30)
        #expect(h.vm.elapsed == 0)
    }

    @Test func overlappingStartsListenOnce() async {
        let h = harness()
        async let first: Void = h.vm.startVoiceFollow(localeIdentifier: "en-US")
        async let second: Void = h.vm.startVoiceFollow(localeIdentifier: "en-US")
        _ = await (first, second)
        #expect(h.speech.startCount == 1)
        #expect(h.vm.voiceFollowActive)
    }

    @Test func startingVoiceStopsAutoScroll() async {
        let h = harness()
        h.vm.play()
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(!h.vm.isPlaying)
        #expect(h.vm.voiceFollowActive)
    }

    @Test func toggleStartsThenStops() async {
        let h = harness()
        await h.vm.toggleVoiceFollow(localeIdentifier: "en-US")
        #expect(h.vm.voiceFollowActive)
        await h.vm.toggleVoiceFollow(localeIdentifier: "en-US")
        #expect(!h.vm.voiceFollowActive)
    }

    // MARK: Callbacks

    @Test func levelStatusAndErrorCallbacksPublish() async {
        let h = await started(harness())
        h.speech.emitLevel(0.6)
        #expect(h.vm.audioLevel == 0.6)
        h.speech.emitStatus("Listening…")
        #expect(h.vm.voiceStatus == "Listening…")
        h.speech.emitError("boom")
        #expect(h.vm.voiceStatus == "Error: boom")
    }

    @Test func recognizedTextKeepsTheLastTwelveWords() async {
        let h = await started(harness())
        h.speech.say("one two three four five six seven eight nine ten eleven twelve thirteen fourteen")
        let words = h.vm.recognizedText.split(separator: " ")
        #expect(words.count == 12)
        #expect(words.first == "three")
        #expect(words.last == "fourteen")
    }

    // MARK: Glide

    @Test func recognizedWordsMoveTheAnchorOnTheNextTick() async {
        let h = await started(harness())
        h.speech.say("alpha bravo charlie delta echo")
        // Words alone never move the rendered position.
        #expect(h.vm.voicePosition == nil)
        h.ticker.fire()
        #expect(h.vm.voiceRecognizedIndex == 4)
        #expect(h.vm.voicePosition != nil)
        #expect(h.vm.voiceLeadWords < 0)
    }

    @Test func glideAdvancesWithoutRecognitionUntilStalled() async {
        let h = await started(harness())
        h.ticker.fire(30)
        let early = h.vm.voiceLeadWords
        #expect(abs(early - 2.6 * 0.5) < 0.05)
    }

    @Test func glideFreezesAfterTheRecognizerGoesSilent() async {
        let h = await started(harness())
        h.ticker.fire(100)
        let frozen = h.vm.voiceLeadWords
        #expect(frozen > 3)
        h.ticker.fire(80)
        #expect(h.vm.voiceLeadWords == frozen)
    }

    @Test func recognitionResumesTheGlide() async {
        let h = await started(harness())
        h.ticker.fire(100)
        h.speech.say("alpha")
        let before = h.vm.voiceLeadWords
        h.ticker.fire(10)
        #expect(h.vm.voiceRecognizedIndex == 0)
        #expect(h.vm.voiceLeadWords != before)
    }

    @Test func glideNeverLeadsByMoreThanTheCeiling() async {
        let h = await started(harness())
        h.vm.maxLeadWords = 1
        h.ticker.fire(55)
        #expect(h.vm.voiceLeadWords < 2) // uncapped it would reach ~2.4
    }

    @Test func voicePositionCoversTheSectionBeingRead() async {
        let h = await started(harness())
        h.speech.say("alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima")
        h.ticker.fire(120)
        #expect(h.vm.voicePosition?.sectionIndex == 1)
    }

    @Test func wordsPerSecondIsExposedForTheDebugPanel() async {
        let h = await started(harness())
        #expect(h.vm.wordsPerSecond == 2.6)
        #expect(h.vm.maxLeadWords == 18)
    }

    // MARK: Stop / pause / reseat

    @Test func stopClearsLiveState() async {
        let h = await started(harness())
        h.speech.emitLevel(0.8)
        h.ticker.fire()
        h.vm.stopVoiceFollow()
        #expect(!h.vm.voiceFollowActive)
        #expect(h.vm.audioLevel == 0)
        #expect(h.vm.voiceStatus == "")
        #expect(h.vm.voicePosition == nil)
        #expect(h.speech.stopCount == 1)
    }

    @Test func pauseVoiceAlsoHaltsThePacingClock() async {
        let h = await started(harness())
        h.ticker.fire(10)
        let elapsed = h.vm.elapsed
        h.vm.pauseVoice()
        h.ticker.fire(10)
        #expect(h.vm.elapsed == elapsed)
        #expect(!h.ticker.isRunning)
    }

    @Test func playingWhileListeningStopsVoice() async {
        let h = await started(harness())
        h.vm.play()
        #expect(!h.vm.voiceFollowActive)
        #expect(h.vm.isPlaying)
    }

    @Test func changingFollowModeWhileListeningPausesVoice() async {
        let h = await started(harness())
        h.vm.setFollowMode(.voice)
        #expect(!h.vm.voiceFollowActive)
        #expect(!h.ticker.isRunning)
    }

    @Test func isFollowRunningReflectsTheActiveMode() async {
        let h = harness()
        h.vm.setFollowMode(.voice)
        #expect(!h.vm.isFollowRunning)
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(h.vm.isFollowRunning)
    }

    @Test func reseatMovesTheCursorToTheSectionStart() async {
        let h = await started(harness())
        h.vm.reseatVoice(to: 1)
        #expect(h.vm.currentIndex == 1)
        h.ticker.fire()
        // Section 1 starts at global token 10, so the anchor is 9.
        #expect(h.vm.voiceRecognizedIndex == 9)
    }

    @Test func switchingToOutlineStopsVoice() async {
        let h = await started(harness())
        h.vm.switchMode()
        #expect(!h.vm.voiceFollowActive)
        #expect(h.vm.followMode == .autoScroll)
    }
}
