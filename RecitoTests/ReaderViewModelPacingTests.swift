//
//  ReaderViewModelPacingTests.swift
//  RecitoTests
//
//  youFill / pace per mode and the scripture cue (including wrap-around).
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelPacingTests {
    private static let outlineWithCitations = """
    1. First [Ps. 1:1](https://x/1)
    2. Second
    3. Third
    4. Fourth [Ps. 4:4](https://x/4)
    """

    @Test func scriptYouFillIsOffsetOverMax() {
        let h = ReaderHarness()
        h.vm.maxOffset = 400
        h.vm.playbackOffset = 100
        #expect(h.vm.youFill == 0.25)
    }

    @Test func scriptYouFillIsZeroWithoutGeometry() {
        let h = ReaderHarness()
        h.vm.playbackOffset = 100
        #expect(h.vm.youFill == 0)
    }

    @Test func outlineYouFillUsesPointProgress() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: TalkFactory.outline, mode: .outline))
        h.vm.maxOffset = 400
        h.vm.playbackOffset = 400
        #expect(h.vm.youFill == 0)
        h.vm.goToNext()
        #expect(abs(h.vm.youFill - 1.0 / Double(h.vm.unitCount - 1)) < 1e-9)
    }

    @Test func paceIsAheadWhenScrolledFartherThanTheClock() {
        let h = ReaderHarness()
        h.vm.maxOffset = 100
        h.vm.playbackOffset = 90
        h.vm.elapsed = 6
        #expect(h.vm.pace.status == .ahead)
    }

    @Test func paceIsBehindWhenTheClockOutrunsTheScroll() {
        let h = ReaderHarness()
        h.vm.maxOffset = 100
        h.vm.playbackOffset = 10
        h.vm.elapsed = 30
        #expect(h.vm.pace.status == .behind)
    }

    @Test func paceIsOnPaceWhenBalanced() {
        let h = ReaderHarness()
        h.vm.maxOffset = 100
        h.vm.playbackOffset = 50
        h.vm.elapsed = 30
        #expect(h.vm.pace.status == .onPace)
        #expect(h.vm.pace.timeLimit == 60)
    }

    @Test func editingTheTimeLimitChangesPace() {
        let h = ReaderHarness()
        h.vm.maxOffset = 100
        h.vm.playbackOffset = 50
        h.vm.elapsed = 30
        h.vm.timeLimit = 600
        #expect(h.vm.pace.status == .ahead)
    }

    @Test func upcomingCitationWrapsToTheFirstWhenPastTheLast() {
        let h = ReaderHarness()
        h.vm.currentIndex = 3
        #expect(h.vm.upcomingCitation?.displayShort == "Ps. 37:7")
        #expect(!h.vm.cueShouldExpand)
        #expect(h.vm.approachingLinkedCitationID == nil)
    }

    @Test func cueExpandsOnTheCitationSectionItself() {
        let h = ReaderHarness()
        h.vm.currentIndex = 2
        #expect(h.vm.cueShouldExpand)
        #expect(h.vm.approachingLinkedCitationID == h.vm.upcomingCitation?.id)
    }

    @Test func cueStaysCollapsedFarFromTheCitation() {
        let h = ReaderHarness()
        #expect(!h.vm.cueShouldExpand)
        #expect(h.vm.approachingLinkedCitationID == nil)
    }

    @Test func outlineCueFindsNextLinkedPoint() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: Self.outlineWithCitations, mode: .outline))
        h.vm.currentIndex = 1
        #expect(h.vm.upcomingCitation?.displayShort == "Ps. 4:4")
        #expect(!h.vm.cueShouldExpand)
        h.vm.currentIndex = 2
        #expect(h.vm.cueShouldExpand)
        #expect(h.vm.approachingLinkedCitationID != nil)
    }

    @Test func outlineCueWrapsPastTheLastCitation() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: "- A [Ps. 1:1](https://x)\n- B\n- C\n- D", mode: .outline))
        h.vm.currentIndex = 3
        #expect(h.vm.upcomingCitation?.displayShort == "Ps. 1:1")
        #expect(!h.vm.cueShouldExpand)
    }

    @Test func outlineWithoutLinkedCitationsHasNoCue() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: TalkFactory.outline, mode: .outline))
        #expect(h.vm.upcomingCitation == nil)
        #expect(!h.vm.cueShouldExpand)
    }

    @Test func emptyDocumentHasNoCue() {
        let h = ReaderHarness(talk: TalkFactory.talk(text: ""))
        #expect(h.vm.upcomingCitation == nil)
        #expect(h.vm.youFill == 0)
    }

    @Test func tickAccumulatesElapsedAtTheTickInterval() {
        let h = ReaderHarness()
        h.vm.startClock()
        h.ticker.fire(120)
        #expect(abs(h.vm.elapsed - 2) < 1e-6)
        h.vm.stopClock()
        h.ticker.fire(10)
        #expect(abs(h.vm.elapsed - 2) < 1e-6)
    }
}
