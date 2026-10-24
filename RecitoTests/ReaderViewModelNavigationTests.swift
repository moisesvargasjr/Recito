//
//  ReaderViewModelNavigationTests.swift
//  RecitoTests
//
//  Cursor movement, mode switching and the point-progress rail.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelNavigationTests {
    private static let mixed = "# Head\n\nOne.\n\nTwo.\n\n- a\n- b\n- c"

    @Test func previousAtTheStartStaysPut() {
        let h = ReaderHarness()
        h.vm.goToPrevious()
        #expect(h.vm.currentIndex == 0)
    }

    @Test func nextStopsAtTheLastUnit() {
        let h = ReaderHarness()
        for _ in 0..<50 { h.vm.goToNext() }
        #expect(h.vm.currentIndex == h.vm.unitCount - 1)
    }

    @Test func previousStepsBackOneAtATime() {
        let h = ReaderHarness()
        h.vm.goToNext()
        h.vm.goToNext()
        h.vm.goToPrevious()
        #expect(h.vm.currentIndex == 1)
    }

    @Test func unitCountFollowsTheActiveMode() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: Self.mixed))
        let sections = h.vm.scriptSections.count
        let nodes = h.vm.outlineNodes.count
        #expect(h.vm.unitCount == sections)
        h.vm.switchMode()
        #expect(h.vm.unitCount == nodes)
    }

    @Test func emptyDocumentHasNoUnitsAndNavigationIsSafe() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: ""))
        #expect(h.vm.unitCount == 0)
        h.vm.goToNext()
        h.vm.goToPrevious()
        #expect(h.vm.currentIndex == 0)
        #expect(h.vm.pointProgress == 0)
        h.vm.switchMode()
        #expect(h.vm.currentIndex == 0)
    }

    @Test func switchModeClampsTheIndexIntoTheShorterList() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: "A.\n\nB.\n\nC.\n\nD.\n\nE.\n\n- only"))
        h.vm.currentIndex = h.vm.unitCount - 1
        h.vm.switchMode()
        #expect(h.vm.currentIndex == h.vm.outlineNodes.count - 1)
    }

    @Test func switchModeResetsPlaybackOffsetAndStopsPlay() {
        let h = ReaderHarness()
        h.vm.maxOffset = 600
        h.vm.play()
        h.ticker.fire(30)
        #expect(h.vm.playbackOffset > 0)
        h.vm.switchMode()
        #expect(h.vm.playbackOffset == 0)
        #expect(!h.vm.isPlaying)
        #expect(!h.ticker.isRunning)
    }

    @Test func switchModeToOutlineResetsFollowModeToAuto() {
        let h = ReaderHarness()
        h.vm.setFollowMode(.voice)
        h.vm.switchMode()
        #expect(h.vm.followMode == .autoScroll)
    }

    @Test func switchModeBackToScriptKeepsAutoFollow() {
        let h = ReaderHarness()
        h.vm.switchMode()
        h.vm.switchMode()
        #expect(h.vm.mode == .script)
        #expect(h.vm.followMode == .autoScroll)
    }

    @Test func switchModeStopsVoiceFollow() async {
        let h = ReaderHarness(talk: TalkFactory.talk(text: TalkFactory.voiceScript))
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(h.vm.voiceFollowActive)
        h.vm.switchMode()
        #expect(!h.vm.voiceFollowActive)
        #expect(h.speech.stopCount >= 1)
    }

    @Test func pointProgressIsZeroWithASingleUnit() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: "Just one paragraph."))
        #expect(h.vm.unitCount == 1)
        #expect(h.vm.pointProgress == 0)
    }

    @Test func pointProgressSpansZeroToOne() {
        let h = ReaderHarness()
        #expect(h.vm.pointProgress == 0)
        h.vm.goToNext()
        #expect(abs(h.vm.pointProgress - 1.0 / 3.0) < 1e-9)
        for _ in 0..<10 { h.vm.goToNext() }
        #expect(h.vm.pointProgress == 1)
    }

    @Test func modeStartsFromTheTalksPreferredMode() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: TalkFactory.outline, mode: .outline))
        #expect(h.vm.mode == .outline)
        #expect(h.vm.unitCount == h.vm.outlineNodes.count)
    }
}
