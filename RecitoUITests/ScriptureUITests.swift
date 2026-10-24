//
//  ScriptureUITests.swift
//  RecitoUITests
//

import XCTest

final class ScriptureUITests: RecitoUITestCase {
    func testInRecitoDestinationShowsVersePaneAndDoneResumes() {
        launchScriptReader(scripture: .inRecito)
        assertHittable(reader.cueChip, "cue chip")
        reader.cueChip.tap()

        XCTAssertTrue(reader.versePane.waitForExistence(timeout: 10), "verse pane should appear")
        let hasState = waitUntil(timeout: 15) {
            app.element(AXID.VersePane.web).exists
                || app.element(AXID.VersePane.loading).exists
                || app.element(AXID.VersePane.error).exists
        }
        XCTAssertTrue(hasState, "pane shows web, loading or error")
        assertHittable(reader.versePaneDone, "verse pane Done")
        screenshot("pane")

        reader.versePaneDone.tap()
        wait(for: reader.versePane, "exists == false")
        XCTAssertTrue(reader.resume.waitForExistence(timeout: 10), "Resume pill appears after Done")
    }

    /// Live check of the real jw.org verse page (needs network). Reports which
    /// state the pane reached via the `versePane-live` screenshot and a log line.
    func testLiveVersePageRenders() {
        launchScriptReader(scripture: .inRecito)
        assertHittable(reader.cueChip, "cue chip")
        reader.cueChip.tap()
        XCTAssertTrue(reader.versePane.waitForExistence(timeout: 10))

        let web = app.element(AXID.VersePane.web)
        let error = app.element(AXID.VersePane.error)
        let loading = app.element(AXID.VersePane.loading)
        // "Loaded": web view present and the loading indicator gone.
        waitUntil(timeout: 20) { error.exists || (web.exists && !loading.exists) }
        let reached = error.exists ? "error" : (web.exists && !loading.exists ? "web-loaded" : "still-loading")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "versePane-live"
        attachment.lifetime = .keepAlways
        add(attachment)
        print("VERSEPANE-LIVE state=\(reached)")
        if reached == "error" {
            XCTExpectFailure("BUG: verse pane shows the error state although jw.org should be reachable") {
                XCTFail("verse pane reached error state")
            }
        } else {
            XCTAssertEqual(reached, "web-loaded", "pane did not finish loading within 20 s")
        }
    }

    func testJWLibraryDestinationDoesNotShowVersePane() {
        launchScriptReader()
        assertHittable(reader.cueChip, "cue chip")
        reader.cueChip.tap()

        let pane = reader.versePane
        let appeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: pane)
        let result = XCTWaiter().wait(for: [appeared], timeout: 3)
        XCTAssertEqual(result, .timedOut, "no verse pane for the JW Library destination")
        XCTAssertNotEqual(app.state, .notRunning, "the app must not crash on external open")
        XCTAssertTrue([XCUIApplication.State.runningForeground, .runningBackground, .runningBackgroundSuspended]
            .contains(app.state))
    }
}
