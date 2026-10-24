//
//  ReaderViewModelVerseTests.swift
//  RecitoTests
//
//  The in-app verse pane: opening a citation applies a scripture hold (clock
//  keeps running, auto-scroll holds, voice keeps listening); closing leaves the
//  position alone and offers Resume; resuming restarts auto-scroll only when it
//  was running before.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelVerseTests {
    private func citation(_ h: ReaderHarness) -> ScriptureCitation {
        guard let c = h.vm.upcomingCitation else {
            Issue.record("fixture should contain a linked citation")
            return ScriptureCitation(rawText: "Ps. 37:7", bookCanonical: "psalms",
                                     chapter: 37, verseStart: 7, verseEnd: nil,
                                     displayShort: "Ps. 37:7")
        }
        return c
    }

    // MARK: Open

    @Test func startsWithNothingPresented() {
        let h = ReaderHarness()
        #expect(h.vm.presentedCitation == nil)
        #expect(!h.vm.showsResume)
    }

    @Test func openVersePresentsTheCitation() {
        let h = ReaderHarness()
        let c = citation(h)
        h.vm.openVerse(c)
        #expect(h.vm.presentedCitation == c)
        #expect(!h.vm.showsResume)
    }

    @Test func openWhilePlayingHoldsAutoScrollButKeepsTheClock() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.openVerse(citation(h))
        #expect(!h.vm.isPlaying)
        #expect(h.vm.isHoldingForScripture)
        #expect(h.ticker.isRunning)
        let before = h.vm.elapsed
        h.ticker.fire(30)
        #expect(h.vm.elapsed > before)
    }

    @Test func holdDoesNotMovePlayback() {
        let h = ReaderHarness()
        h.vm.maxOffset = 1000
        h.vm.play()
        h.ticker.fire(10)
        h.vm.openVerse(citation(h))
        let offset = h.vm.playbackOffset
        h.ticker.fire(30)
        #expect(h.vm.playbackOffset == offset)
    }

    @Test func openWhilePausedDoesNotStartAnything() {
        let h = ReaderHarness()
        h.vm.openVerse(citation(h))
        #expect(!h.vm.isPlaying)
        #expect(!h.vm.isHoldingForScripture)
        #expect(!h.ticker.isRunning)
    }

    @Test func openDuringVoiceFollowKeepsListening() async {
        let h = ReaderHarness(talk: TalkFactory.talk(
            text: TalkFactory.voiceScript + "\n\nRead [Ps. 37:7](https://x/ps) now."))
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        h.vm.openVerse(citation(h))
        #expect(h.vm.voiceFollowActive)
        #expect(h.speech.stopCount == 0)
        #expect(h.ticker.isRunning)
    }

    // MARK: Close

    @Test func closeDismissesAndOffersResumeWithoutMoving() {
        let h = ReaderHarness()
        h.vm.maxOffset = 1000
        h.vm.play()
        h.ticker.fire(10)
        h.vm.openVerse(citation(h))
        let offset = h.vm.playbackOffset
        let index = h.vm.currentIndex
        h.vm.closeVerse()
        #expect(h.vm.presentedCitation == nil)
        #expect(h.vm.showsResume)
        #expect(h.vm.playbackOffset == offset)
        #expect(h.vm.currentIndex == index)
        #expect(!h.vm.isPlaying)
    }

    @Test func closeWithNothingOpenIsANoOp() {
        let h = ReaderHarness()
        h.vm.closeVerse()
        #expect(!h.vm.showsResume)
        #expect(h.vm.presentedCitation == nil)
    }

    // MARK: Resume

    @Test func resumeRestartsAutoScrollWhenItWasPlaying() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.openVerse(citation(h))
        h.vm.closeVerse()
        h.vm.resumeAfterVerse()
        #expect(h.vm.isPlaying)
        #expect(!h.vm.isHoldingForScripture)
        #expect(!h.vm.showsResume)
    }

    @Test func resumeAfterAnAutomaticHoldRestartsAutoScroll() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 2 // linked citation → automatic hold
        #expect(h.vm.isHoldingForScripture)
        h.vm.openVerse(citation(h))
        h.vm.closeVerse()
        h.vm.resumeAfterVerse()
        #expect(h.vm.isPlaying)
    }

    @Test func resumeDoesNotStartPlaybackThatWasPaused() {
        let h = ReaderHarness()
        h.vm.openVerse(citation(h))
        h.vm.closeVerse()
        h.vm.resumeAfterVerse()
        #expect(!h.vm.isPlaying)
        #expect(!h.vm.showsResume)
    }

    @Test func resumeWhileStillOpenAlsoClosesThePane() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.openVerse(citation(h))
        h.vm.resumeAfterVerse()
        #expect(h.vm.presentedCitation == nil)
        #expect(h.vm.isPlaying)
    }

    @Test func reopeningKeepsTheOriginalResumeIntent() {
        let h = ReaderHarness()
        h.vm.play()
        let c = citation(h)
        h.vm.openVerse(c)
        h.vm.openVerse(c) // e.g. tapping the cue again while open
        h.vm.closeVerse()
        h.vm.resumeAfterVerse()
        #expect(h.vm.isPlaying)
    }

    @Test func dismissResumeClearsThePill() {
        let h = ReaderHarness()
        h.vm.openVerse(citation(h))
        h.vm.closeVerse()
        h.vm.dismissResume()
        #expect(!h.vm.showsResume)
        #expect(!h.vm.isPlaying)
    }

    @Test func outlineModeResumeDoesNotStartAutoScroll() {
        let text = "- Read [Ps. 37:7](https://example.com/ps)\n- Next point"
        let h = ReaderHarness(talk: TalkFactory.talk(text: text, mode: .outline))
        h.vm.startClock()
        h.vm.openVerse(citation(h))
        #expect(h.ticker.isRunning)
        h.vm.closeVerse()
        h.vm.resumeAfterVerse()
        #expect(!h.vm.isPlaying)
        #expect(h.ticker.isRunning)
    }
}
