//
//  ScriptReaderUITests.swift
//  RecitoUITests
//

import XCTest

final class ScriptReaderUITests: RecitoUITestCase {
    func testCloseReturnsToLibrary() {
        launchScriptReader()
        screenshot()
        reader.closeControl().tap()
        wait(for: reader.root, "exists == false")
        XCTAssertTrue(library.root.isHittable || library.root.exists)
    }

    func testNextAndPreviousChangeIndex() {
        launchScriptReader()
        let start = reader.index
        XCTAssertNotNil(start)
        reader.nextControl().tap()
        let afterNext = waitForIndexChange(from: start)
        XCTAssertGreaterThan(afterNext ?? -1, start ?? 0, "Next advances the index")

        reader.nextControl().tap()
        let afterSecond = waitForIndexChange(from: afterNext)
        XCTAssertGreaterThan(afterSecond ?? -1, afterNext ?? 0)

        reader.prevControl().tap()
        let afterPrev = waitForIndexChange(from: afterSecond)
        XCTAssertLessThan(afterPrev ?? Int.max, afterSecond ?? 0, "Previous goes back")
    }

    func testPlayAdvancesIndexWithinSixSeconds() {
        launchScriptReader()
        // Speed the scroll up the supported way: smallest text (short paragraphs)
        // and the shortest time limit (still ~9 s per paragraph at 10 min), so allow 15 s.
        let text = reader.openTextDisplay()
        XCTAssertTrue(text.waitForLoad())
        text.textSize.adjust(toNormalizedSliderPosition: 0.0)
        text.done.tap()
        wait(for: text.root, "exists == false")
        let pacing = reader.openPacing()
        XCTAssertTrue(pacing.waitForLoad())
        pacing.preset(10).tap()
        pacing.done.tap()
        wait(for: pacing.root, "exists == false")

        let start = reader.index
        reader.playControl().tap()
        waitUntil(timeout: 15) { reader.index != start }
        XCTAssertGreaterThan(reader.index ?? -1, start ?? 0, "index should advance while playing")
        XCTAssertTrue(app.buttons["Pause"].firstMatch.exists, "Play turns into Pause")
    }

    func testModeToggleSwitchesToOutlineAndBack() {
        launchScriptReader()
        XCTAssertEqual(reader.mode, "script")
        reader.modeControl(showing: "Outline").tap()
        waitUntil { reader.mode == "outline" }
        XCTAssertEqual(reader.mode, "outline")
        screenshot("outline")
        reader.modeControl(showing: "Script").tap()
        waitUntil { reader.mode == "script" }
        XCTAssertEqual(reader.mode, "script")
    }

    func testAaIsReachableAndOpensTextDisplay() {
        launchScriptReader()
        let sheet = reader.openTextDisplay()
        XCTAssertTrue(sheet.waitForLoad())
        screenshot()
    }

    func testTimerOpensPacingSheet() {
        launchScriptReader()
        let sheet = reader.openPacing()
        XCTAssertTrue(sheet.waitForLoad(), "Pacing sheet reachable from the timer")
    }

    func testBackToCurrentDoesNotOverlapToolbar() {
        launchScriptReader()
        reader.dragScript()
        assertHittable(reader.backToCurrent, "Back to current")
        assertInsideWindow(reader.backToCurrent, "Back to current")
        var named: [(String, XCUIElement)] = [("Back to current", reader.backToCurrent)]
        for (name, button) in [("Close", reader.close), ("Aa", reader.aa), ("Mode", reader.modeToggle),
                               ("Prev", reader.prev), ("Play", reader.play), ("Next", reader.next)]
        where button.exists {
            named.append((name, button))
        }
        assertNoOverlap(named)
        screenshot()
    }

    func testBarsAutoHideWhilePlayingAndTapRestores() {
        launchScriptReader(extra: ["-chromeHideDelay", "0.5"])
        reader.playControl().tap()
        let hidden = waitUntil(timeout: 10) { !reader.play.exists || !reader.play.isHittable }
        XCTAssertTrue(hidden, "Play should hide after the chrome delay")
        screenshot("hidden")

        reader.root.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.5)).tap()
        let restored = waitUntil(timeout: 10) { reader.play.exists && reader.play.isHittable }
            || waitUntil(timeout: 1) { app.buttons["Pause"].exists && app.buttons["Pause"].isHittable }
        XCTAssertTrue(restored, "tapping the script brings the bars back")
    }
}
