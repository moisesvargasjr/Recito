//
//  ReaderViewModelChromeTests.swift
//  RecitoTests
//
//  Chrome auto-hide, driven by a ManualScheduler.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelChromeTests {
    @Test func chromeStartsVisibleWithNothingScheduled() {
        let h = ReaderHarness()
        #expect(h.vm.chromeVisible)
        #expect(h.scheduler.pending.isEmpty)
    }

    @Test func playingSchedulesAHideAfterTheConfiguredDelay() {
        let h = ReaderHarness(chromeHideDelay: 3.5)
        h.vm.play()
        #expect(h.scheduler.pending.count == 1)
        #expect(h.scheduler.pending.first?.delay == 3.5)
    }

    @Test func customDelayIsUsed() {
        let h = ReaderHarness(chromeHideDelay: 0.2)
        h.vm.play()
        #expect(h.scheduler.pending.first?.delay == 0.2)
    }

    @Test func scheduledHideHidesTheChrome() {
        let h = ReaderHarness()
        h.vm.play()
        h.scheduler.runPending()
        #expect(!h.vm.chromeVisible)
    }

    @Test func wakeChromeRevealsAndReschedulesWhilePlaying() {
        let h = ReaderHarness()
        h.vm.play()
        h.scheduler.runPending()
        h.vm.wakeChrome()
        #expect(h.vm.chromeVisible)
        #expect(h.scheduler.pending.count == 1)
    }

    @Test func rescheduleCancelsThePreviousHide() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.wakeChrome()
        h.vm.wakeChrome()
        #expect(h.scheduler.pending.count == 1)
    }

    @Test func wakeChromeWhileIdleDoesNotScheduleAHide() {
        let h = ReaderHarness()
        h.vm.wakeChrome()
        #expect(h.vm.chromeVisible)
        #expect(h.scheduler.pending.isEmpty)
    }

    @Test func toggleChromeHidesAndCancelsPendingHide() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.toggleChrome()
        #expect(!h.vm.chromeVisible)
        #expect(h.scheduler.pending.isEmpty)
    }

    @Test func toggleChromeAgainRevealsAndReschedules() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.toggleChrome()
        h.vm.toggleChrome()
        #expect(h.vm.chromeVisible)
        #expect(h.scheduler.pending.count == 1)
    }

    @Test func pauseAfterHideScheduleLeavesChromeStable() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.pause()
        h.vm.wakeChrome()
        #expect(h.vm.chromeVisible)
        #expect(h.scheduler.pending.isEmpty)
    }

    @Test func voiceFollowAlsoAutoHidesChrome() async {
        let h = ReaderHarness(talk: TalkFactory.talk(text: TalkFactory.voiceScript))
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(h.scheduler.pending.count == 1)
        h.scheduler.runPending()
        #expect(!h.vm.chromeVisible)
    }

    @Test func scriptureHoldWakesTheChrome() {
        let h = ReaderHarness()
        h.vm.play()
        h.scheduler.runPending()
        h.vm.currentIndex = 2
        #expect(h.vm.chromeVisible)
    }

    @Test func changingFollowModeWakesTheChrome() {
        let h = ReaderHarness()
        h.vm.toggleChrome()
        h.vm.setFollowMode(.voice)
        #expect(h.vm.chromeVisible)
    }

    // MARK: Assistive technology

    @Test func lockingChromeForVoiceOverNeverAutoHides() {
        let h = ReaderHarness()
        h.vm.setChromeLocked(true)
        h.vm.play()
        #expect(h.scheduler.pending.isEmpty)
        #expect(h.vm.chromeVisible)
    }

    @Test func lockingRevealsHiddenChromeAndCancelsAPendingHide() {
        let h = ReaderHarness()
        h.vm.play()
        h.scheduler.runPending()
        #expect(!h.vm.chromeVisible)
        h.vm.setChromeLocked(true)
        #expect(h.vm.chromeVisible)
        h.vm.wakeChrome()
        #expect(h.scheduler.pending.isEmpty)
    }

    @Test func tapToggleCannotHideALockedChrome() {
        let h = ReaderHarness()
        h.vm.setChromeLocked(true)
        h.vm.toggleChrome()
        #expect(h.vm.chromeVisible)
    }

    @Test func unlockingResumesAutoHideWhilePlaying() {
        let h = ReaderHarness()
        h.vm.setChromeLocked(true)
        h.vm.play()
        h.vm.setChromeLocked(false)
        #expect(h.scheduler.pending.count == 1)
    }
}
