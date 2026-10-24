//
//  ScriptureAutoOpenPolicyTests.swift
//  RecitoTests
//
//  When "open scripture as you approach" may fire: once per (section,
//  citation), never over an open pane or sheet, only in script mode.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ScriptureAutoOpenPolicyTests {
    private func decide(
        enabled: Bool = true,
        isScriptMode: Bool = true,
        key: ScriptureAutoOpenKey? = ScriptureAutoOpenKey(sectionIndex: 2, citationID: "psalms 37:7"),
        scriptureBusy: Bool = false,
        sheetPresented: Bool = false,
        opened: Set<ScriptureAutoOpenKey> = []
    ) -> ScriptureAutoOpenKey? {
        ScriptureAutoOpenPolicy.keyToOpen(
            enabled: enabled, isScriptMode: isScriptMode, approaching: key,
            scriptureBusy: scriptureBusy, sheetPresented: sheetPresented, alreadyOpened: opened
        )
    }

    private let key = ScriptureAutoOpenKey(sectionIndex: 2, citationID: "psalms 37:7")

    @Test func opensAnApproachingCitation() {
        #expect(decide() == key)
    }

    @Test func nothingApproachingOpensNothing() {
        #expect(decide(key: nil) == nil)
    }

    @Test func disabledSettingOpensNothing() {
        #expect(decide(enabled: false) == nil)
    }

    @Test func outlineModeOpensNothing() {
        #expect(decide(isScriptMode: false) == nil)
    }

    @Test func doesNotReplaceAnOpenPaneOrExternalHandOff() {
        #expect(decide(scriptureBusy: true) == nil)
    }

    @Test func doesNotFireWhileASheetIsUp() {
        #expect(decide(sheetPresented: true) == nil)
    }

    @Test func aKeyAlreadyOpenedIsSkipped() {
        #expect(decide(opened: [key]) == nil)
    }

    @Test func theSameCitationInAnotherSectionOpensAgain() {
        let again = ScriptureAutoOpenKey(sectionIndex: 5, citationID: "psalms 37:7")
        #expect(decide(key: again, opened: [key]) == again)
    }

    // MARK: View model glue

    @Test func approachingScriptureCarriesItsSectionIndex() {
        let h = ReaderHarness()
        h.vm.currentIndex = 1
        let approaching = h.vm.approachingScriptureKey
        #expect(approaching?.sectionIndex == 2)
        #expect(approaching?.citationID == h.vm.upcomingCitation?.id)
    }

    @Test func noApproachingKeyFarFromTheCitation() {
        let h = ReaderHarness()
        h.vm.currentIndex = 0
        #expect(h.vm.approachingScriptureKey == nil)
    }

    @Test func autoOpenedSectionDoesNotHoldAgainOnArrival() {
        let h = ReaderHarness()
        h.vm.play()
        h.vm.currentIndex = 1
        h.vm.markScriptureConsumed(at: 2)
        h.vm.currentIndex = 2
        #expect(h.vm.isPlaying)
        #expect(!h.vm.isHoldingForScripture)
    }
}
