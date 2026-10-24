//
//  ReaderViewModelPlaybackTests.swift
//  RecitoTests
//
//  Auto-scroll, the pacing clock, scripture holds and navigation — all driven
//  by a ManualTicker so nothing depends on wall-clock time.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelPlaybackTests {
    // 60 s limit over 600 pt = 10 pt/s.
    private func harness(maxOffset: CGFloat = 600) -> ReaderHarness {
        let h = ReaderHarness()
        h.vm.maxOffset = maxOffset
        return h
    }

    @Test func startsPausedAtTheTop() {
        let h = harness()
        #expect(!h.vm.isPlaying)
        #expect(h.vm.currentIndex == 0)
        #expect(h.vm.elapsed == 0)
        #expect(h.vm.playbackOffset == 0)
        #expect(!h.ticker.isRunning)
    }

    @Test func playStartsTheClockAndScrolls() {
        let h = harness()
        h.vm.play()
        #expect(h.vm.isPlaying)
        #expect(h.ticker.startCount == 1)
        #expect(abs(h.ticker.interval - 1.0 / 60.0) < 1e-12)

        h.ticker.fire(60)
        #expect(abs(h.vm.elapsed - 1) < 1e-6)
        #expect(abs(h.vm.playbackOffset - 10) < 1e-3)
    }

    @Test func speedMultiplierScalesVelocity() {
        let h = harness()
        h.vm.speedMultiplier = 2
        h.vm.play()
        h.ticker.fire(60)
        #expect(abs(h.vm.playbackOffset - 20) < 1e-3)
    }

    @Test func pauseStopsTheClock() {
        let h = harness()
        h.vm.play()
        h.ticker.fire(30)
        h.vm.pause()
        let frozen = h.vm.elapsed
        h.ticker.fire(30)
        #expect(!h.vm.isPlaying)
        #expect(h.vm.elapsed == frozen)
        #expect(h.ticker.cancelCount == 1)
    }

    @Test func togglePlayFlipsState() {
        let h = harness()
        h.vm.togglePlay()
        #expect(h.vm.isPlaying)
        h.vm.togglePlay()
        #expect(!h.vm.isPlaying)
    }

    @Test func playTwiceDoesNotStartASecondTicker() {
        let h = harness()
        h.vm.play()
        h.vm.play()
        #expect(h.ticker.startCount == 1)
    }

    @Test func reachingTheEndPausesAtMaxOffset() {
        let h = harness(maxOffset: 1)
        h.vm.timeLimit = 1
        h.vm.play()
        h.ticker.fire(90)
        #expect(h.vm.playbackOffset == 1)
        #expect(!h.vm.isPlaying)
    }

    @Test func noScrollWithoutMeasuredGeometry() {
        let h = harness(maxOffset: 0)
        h.vm.play()
        h.ticker.fire(60)
        #expect(h.vm.playbackOffset == 0)
        #expect(h.vm.isPlaying)
    }

    @Test func noScrollWithZeroTimeLimit() {
        let h = harness()
        h.vm.timeLimit = 0
        h.vm.play()
        h.ticker.fire(60)
        #expect(h.vm.playbackOffset == 0)
    }

    @Test func startClockRunsPacingWithoutScrolling() {
        let h = harness()
        h.vm.startClock()
        h.vm.startClock()
        h.ticker.fire(60)
        #expect(h.ticker.startCount == 1)
        #expect(abs(h.vm.elapsed - 1) < 1e-6)
        #expect(h.vm.playbackOffset == 0)
    }

    // MARK: Pacing values

    @Test func youFillIsScrollFractionInScriptMode() {
        let h = harness(maxOffset: 200)
        h.vm.playbackOffset = 50
        #expect(h.vm.youFill == 0.25)
    }

    @Test func youFillIsZeroBeforeGeometry() {
        #expect(harness(maxOffset: 0).vm.youFill == 0)
    }

    @Test func outlineYouFillTracksThePoint() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: TalkFactory.outline, mode: .outline))
        h.vm.currentIndex = h.vm.unitCount - 1
        #expect(h.vm.youFill == 1)
    }

    // MARK: Scripture hold

    @Test func reachingALinkedScriptureHoldsAutoScroll() {
        let h = harness()
        h.vm.play()
        h.vm.currentIndex = 2
        #expect(!h.vm.isPlaying)
        #expect(h.vm.isHoldingForScripture)
        #expect(h.vm.chromeVisible)
    }

    @Test func clockKeepsCountingWhileHolding() {
        let h = harness()
        h.vm.play()
        h.ticker.fire(30)
        h.vm.currentIndex = 2
        let offset = h.vm.playbackOffset
        let elapsed = h.vm.elapsed
        h.ticker.fire(30)
        #expect(h.vm.elapsed > elapsed)
        #expect(h.vm.playbackOffset == offset)
    }

    @Test func holdHappensOncePerScripture() {
        let h = harness()
        h.vm.play()
        h.vm.currentIndex = 2
        h.vm.play()
        #expect(!h.vm.isHoldingForScripture)
        h.vm.currentIndex = 1
        h.vm.currentIndex = 2
        #expect(h.vm.isPlaying)
    }

    @Test func noHoldWhenNotPlaying() {
        let h = harness()
        h.vm.currentIndex = 2
        #expect(!h.vm.isHoldingForScripture)
    }

    @Test func noHoldOnPlainParagraphs() {
        let h = harness()
        h.vm.play()
        h.vm.currentIndex = 1
        #expect(h.vm.isPlaying)
    }

    @Test func pauseClearsTheHold() {
        let h = harness()
        h.vm.play()
        h.vm.currentIndex = 2
        h.vm.pause()
        #expect(!h.vm.isHoldingForScripture)
    }

    // MARK: Cue

    @Test func upcomingCitationIsTheNextLinkedOne() {
        let h = harness()
        #expect(h.vm.upcomingCitation?.displayShort == "Ps. 37:7")
        #expect(h.vm.cueShouldExpand == false)
        h.vm.currentIndex = 1
        #expect(h.vm.cueShouldExpand)
        #expect(h.vm.approachingLinkedCitationID == h.vm.upcomingCitation?.id)
    }

    @Test func noCueWithoutLinkedCitations() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: TalkFactory.voiceScript))
        #expect(h.vm.upcomingCitation == nil)
        #expect(!h.vm.cueShouldExpand)
        #expect(h.vm.approachingLinkedCitationID == nil)
    }

    // MARK: Navigation

    @Test func navigationIsBoundedByUnitCount() {
        let h = harness()
        h.vm.goToPrevious()
        #expect(h.vm.currentIndex == 0)
        for _ in 0..<10 { h.vm.goToNext() }
        #expect(h.vm.currentIndex == h.vm.unitCount - 1)
        #expect(h.vm.unitCount == 4)
        h.vm.goToPrevious()
        #expect(h.vm.currentIndex == 2)
    }

    @Test func switchModeClampsCursorAndResetsOffset() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: "# Head\n\nOne.\n\nTwo.\n\nThree.\n\nFour.\n\n- a\n- b"))
        h.vm.currentIndex = h.vm.unitCount - 1
        h.vm.playbackOffset = 120
        h.vm.play()
        h.vm.switchMode()
        #expect(h.vm.mode == .outline)
        #expect(!h.vm.isPlaying)
        #expect(h.vm.playbackOffset == 0)
        #expect(h.vm.currentIndex < h.vm.unitCount)
        h.vm.switchMode()
        #expect(h.vm.mode == .script)
    }

    // MARK: Follow mode

    @Test func setFollowModePausesAutoScrollAndDoesNotAutoStart() {
        let h = harness()
        h.vm.play()
        h.vm.setFollowMode(.voice)
        #expect(h.vm.followMode == .voice)
        #expect(!h.vm.isPlaying)
        #expect(!h.vm.voiceFollowActive)
        #expect(!h.vm.isFollowRunning)
    }

    @Test func settingTheSameFollowModeIsANoOp() {
        let h = harness()
        h.vm.play()
        h.vm.setFollowMode(.autoScroll)
        #expect(h.vm.isPlaying)
        #expect(h.vm.isFollowRunning)
    }

    @Test func convenienceInitUsesTheGivenSpeechSource() {
        let spy = SpySpeechSource()
        spy.isAvailable = false
        let vm = ReaderViewModel(talk: TalkFactory.talk(), speechSource: spy)
        #expect(vm.speechSource === spy)
        #expect(!vm.voiceAvailable)
    }
}
