//
//  ReaderViewModelScriptureHoldTests.swift
//  RecitoTests
//
//  The soft pause on a linked (read-aloud) citation: once per section, only
//  while auto-scroll is playing in script mode.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelScriptureHoldTests {
    @Test func landingOnALinkedSectionWhilePlayingHolds() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 2
        #expect(!h.vm.isPlaying)
        #expect(h.vm.isHoldingForScripture)
    }

    @Test func holdKeepsThePacingClockRunning() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 2
        #expect(h.ticker.isRunning)
    }

    @Test func holdSurfacesTheChrome() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.chromeVisible = false
        h.vm.currentIndex = 2
        #expect(h.vm.chromeVisible)
    }

    @Test func playClearsTheHoldAndResumes() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 2
        h.vm.play()
        #expect(h.vm.isPlaying)
        #expect(!h.vm.isHoldingForScripture)
    }

    @Test func togglePlayResumesFromAHold() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 2
        h.vm.togglePlay()
        #expect(h.vm.isPlaying)
        #expect(!h.vm.isHoldingForScripture)
    }

    @Test func revisitingAConsumedSectionDoesNotHoldAgain() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 2
        h.vm.play()
        h.vm.currentIndex = 3
        h.vm.currentIndex = 2
        #expect(h.vm.isPlaying)
        #expect(!h.vm.isHoldingForScripture)
    }

    @Test func noHoldWhenPaused() {
        let h = ReaderHarness()
        h.vm.currentIndex = 2
        #expect(!h.vm.isHoldingForScripture)
        h.vm.play()
        #expect(h.vm.isPlaying)
    }

    @Test func pausedMovesDoNotConsumeTheSection() {
        let h = ReaderHarness()
        h.vm.currentIndex = 2
        h.vm.currentIndex = 0
        h.vm.play()
        h.vm.currentIndex = 2
        #expect(h.vm.isHoldingForScripture)
    }

    @Test func noHoldInOutlineMode() {
        let text = "- Read [Ps. 37:7](https://example.com/ps)\n- Next point"
        let h = ReaderHarness(talk: TalkFactory.talk(text: text, mode: .outline))
        h.vm.startClock()
        h.vm.isPlaying = true
        h.vm.currentIndex = 0
        h.vm.currentIndex = 1
        h.vm.currentIndex = 0
        #expect(h.vm.isPlaying)
        #expect(!h.vm.isHoldingForScripture)
    }

    @Test func bareMentionsDoNotHold() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: "One.\n\nSee Ps. 37:7 here.\n\nThree."))
        h.vm.play()
        h.vm.currentIndex = 1
        #expect(h.vm.isPlaying)
    }

    @Test func outOfRangeIndexesAreIgnored() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 99
        h.vm.currentIndex = -1
        #expect(h.vm.isPlaying)
        #expect(!h.vm.isHoldingForScripture)
    }

    @Test func pausingClearsTheHoldFlag() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 2
        h.vm.pause()
        #expect(!h.vm.isHoldingForScripture)
        #expect(!h.vm.isPlaying)
    }

    @Test func eachLinkedSectionHoldsOnceIndependently() {
        let text = "A.\n\nB [Ps. 1:1](https://x/1).\n\nC.\n\nD [Ps. 2:2](https://x/2)."
        let h = ReaderHarness(talk: TalkFactory.talk(text: text))
        h.vm.play()
        h.vm.currentIndex = 1
        #expect(h.vm.isHoldingForScripture)
        h.vm.play()
        h.vm.currentIndex = 3
        #expect(h.vm.isHoldingForScripture)
    }
}
