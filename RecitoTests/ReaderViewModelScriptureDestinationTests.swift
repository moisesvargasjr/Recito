//
//  ReaderViewModelScriptureDestinationTests.swift
//  RecitoTests
//
//  openScripture branches on the user's ScriptureDestination: the in-app
//  verse pane, or the JW Library app (external URL) with a hold that offers
//  Resume when the app comes back.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelScriptureDestinationTests {
    private struct StubLinker: ScriptureLinker {
        let result: URL?
        func url(for citation: ScriptureCitation) -> URL? { result }
    }

    private let bare = ScriptureCitation(rawText: "Ps. 37:7", bookCanonical: "psalms",
                                         chapter: 37, verseStart: 7, verseEnd: nil,
                                         displayShort: "Ps. 37:7")
    private let appURL = URL(string: "jwlibrary:///finder?bible=19037007")!

    private func openExternally(_ h: ReaderHarness) -> ScriptureAction {
        h.vm.openScripture(bare, destination: .jwLibrary, linker: StubLinker(result: appURL))
    }

    @Test func inAppPresentsThePane() {
        let h = ReaderHarness()
        let action = h.vm.openScripture(bare, destination: .inApp)
        #expect(action == .pane)
        #expect(h.vm.presentedCitation == bare)
    }

    @Test func jwLibraryPrefersASafeAuthorURL() throws {
        let h = ReaderHarness()
        let safe = try #require(URL(string: "https://www.jw.org/es/biblia/ps37"))
        let c = try #require(h.vm.upcomingCitation).activated(url: safe)
        let action = h.vm.openScripture(c, destination: .jwLibrary, linker: StubLinker(result: appURL))
        #expect(action == .external(safe))
        #expect(h.vm.presentedCitation == nil)
    }

    @Test func jwLibraryIgnoresAnUnsafeAuthorURL() throws {
        let h = ReaderHarness()
        // The fixture's author link points at example.com.
        let c = try #require(h.vm.upcomingCitation)
        let action = h.vm.openScripture(c, destination: .jwLibrary, linker: StubLinker(result: appURL))
        #expect(action == .external(appURL))
    }

    @Test func jwLibraryFallsBackToTheLinker() {
        let h = ReaderHarness()
        #expect(openExternally(h) == .external(appURL))
    }

    @Test func jwLibraryWithoutALinkChangesNothing() {
        let h = ReaderHarness()
        h.vm.play()
        let action = h.vm.openScripture(bare, destination: .jwLibrary, linker: StubLinker(result: nil))
        #expect(action == .unavailable)
        #expect(h.vm.isPlaying)
        #expect(h.vm.verseState == .idle)
    }

    @Test func jwLibraryHoldsAutoScrollAndKeepsTheClock() {
        let h = ReaderHarness()
        h.vm.play()
        _ = openExternally(h)
        #expect(!h.vm.isPlaying)
        #expect(h.vm.isHoldingForScripture)
        #expect(h.ticker.isRunning)
        #expect(!h.vm.showsResume)
    }

    @Test func returningWhilePlayingOffersResumeWithoutMoving() {
        let h = ReaderHarness()
        h.vm.maxOffset = 1000
        h.vm.play()
        h.ticker.fire(10)
        _ = openExternally(h)
        let offset = h.vm.playbackOffset
        let elapsed = h.vm.elapsed
        h.ticker.fire(60)
        h.vm.sceneEnteredBackground()
        h.vm.returnedFromExternalScripture()
        #expect(h.vm.showsResume)
        #expect(h.vm.playbackOffset == offset)
        #expect(h.vm.elapsed > elapsed)
        h.vm.resumeAfterVerse()
        #expect(h.vm.isPlaying)
    }

    @Test func returningWhenPausedShowsNoResume() {
        let h = ReaderHarness()
        _ = openExternally(h)
        h.vm.sceneEnteredBackground()
        h.vm.returnedFromExternalScripture()
        #expect(!h.vm.showsResume)
        #expect(h.vm.verseState == .idle)
    }

    @Test func becomingActiveWithoutAnExternalOpenIsANoOp() {
        let h = ReaderHarness()
        h.vm.openVerse(bare)
        h.vm.returnedFromExternalScripture()
        #expect(h.vm.presentedCitation == bare)
    }

    @Test func becomingActiveBeforeEverLeavingDoesNotEndTheHandOff() {
        let h = ReaderHarness()
        h.vm.play()
        _ = openExternally(h) // e.g. the "Open in JW Library?" prompt dismisses
        h.vm.returnedFromExternalScripture()
        #expect(!h.vm.showsResume)
        #expect(h.vm.verseState.awaitingReturn)
        h.vm.sceneEnteredBackground()
        h.vm.returnedFromExternalScripture()
        #expect(h.vm.showsResume)
    }

    @Test func backgroundingWithoutAnExternalOpenChangesNothing() {
        let h = ReaderHarness()
        h.vm.sceneEnteredBackground()
        #expect(h.vm.verseState == .idle)
    }

    @Test func aRefusedHandOffRestoresTheReaderImmediately() {
        let h = ReaderHarness()
        h.vm.play()
        _ = openExternally(h)
        h.vm.externalScriptureNotOpened()
        #expect(h.vm.showsResume)
        h.vm.resumeAfterVerse()
        #expect(h.vm.isPlaying)
    }
}
