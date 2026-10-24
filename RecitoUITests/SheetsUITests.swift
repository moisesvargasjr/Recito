//
//  SheetsUITests.swift
//  RecitoUITests
//

import XCTest

final class SheetsUITests: RecitoUITestCase {
    private func openPacing() -> PacingSheetScreen {
        launchScriptReader()
        let sheet = reader.openPacing()
        XCTAssertTrue(sheet.waitForLoad(), "Pacing sheet should open")
        return sheet
    }

    private func assertPresetsLaidOut(_ sheet: PacingSheetScreen) {
        var named: [(String, XCUIElement)] = []
        for minutes in PacingSheetScreen.presets {
            let chip = sheet.preset(minutes)
            assertHittable(chip, "preset \(minutes)")
            assertInsideWindow(chip, "preset \(minutes)")
            named.append(("preset \(minutes)", chip))
        }
        assertHittable(sheet.custom, "Custom")
        named.append(("Custom", sheet.custom))
        assertNoOverlap(named)
    }

    func testPacingPresetsAreHittableAndDisjointInPortrait() {
        let sheet = openPacing()
        assertPresetsLaidOut(sheet)
        screenshot()
    }

    func testPacingPresetsAreHittableAndDisjointInLandscape() {
        let sheet = openPacing()
        for pose in [Pose.landscapeLeft, .landscapeRight] {
            rotate(to: pose)
            XCTAssertTrue(sheet.waitForLoad())
            assertPresetsLaidOut(sheet)
            screenshot()
        }
    }

    func testSelecting45UpdatesTimerReadout() {
        let sheet = openPacing()
        sheet.preset(45).tap()
        let previewShows45 = waitUntil { sheet.preview.label.contains("45:00") }
        XCTAssertTrue(previewShows45, "preview readout should show 45:00, got: \(sheet.preview.label)")
        sheet.done.tap()
        wait(for: sheet.root, "exists == false")
        let timer = reader.timerControl()
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        XCTAssertTrue(timer.label.contains("45:00"), "timer readout should contain 45:00, got: \(timer.label)")
    }

    func testTextDisplayHasScripturePickerWithBothOptions() {
        launch(seed: .samples)
        library.waitForLoad()
        let sheet = library.openTextDisplay()
        XCTAssertTrue(sheet.waitForLoad())
        sheet.revealScripturePicker()
        XCTAssertTrue(app.staticTexts["Open scriptures in"].firstMatch.exists, "picker title present")
        sheet.scripturePicker.tap()
        XCTAssertTrue(app.buttons[ScriptureDestinationOption.jwLibrary.rawValue].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[ScriptureDestinationOption.inRecito.rawValue].firstMatch.exists)
        screenshot()
    }

    func testScriptureDestinationPersistsAcrossRelaunch() {
        launch(seed: .samples)
        library.waitForLoad()
        var sheet = library.openTextDisplay()
        XCTAssertTrue(sheet.waitForLoad())
        sheet.chooseScriptureDestination(ScriptureDestinationOption.inRecito.rawValue)
        sheet.finish()
        app.terminate()

        launch(seed: .samples, reset: false)
        library.waitForLoad()
        sheet = library.openTextDisplay()
        XCTAssertTrue(sheet.waitForLoad())
        sheet.revealScripturePicker()
        let shown = "\(sheet.scripturePicker.label) \(sheet.scripturePicker.value ?? "")"
        XCTAssertTrue(shown.contains("In Recito"), "picker should still say In Recito after relaunch, got: \(shown)")
    }

    /// BUG: once the Text & Display form is scrolled, the toolbar Done button
    /// leaves the accessibility hierarchy (cover display), so the sheet can only
    /// be closed by scrolling back up or dragging it down.
    func testDoneStaysReachableWhileScrolled() {
        launch(seed: .samples)
        library.waitForLoad()
        let sheet = library.openTextDisplay()
        XCTAssertTrue(sheet.waitForLoad())
        sheet.revealScripturePicker()
        XCTExpectFailure("BUG: Text & Display Done disappears while the form is scrolled") {
            XCTAssertTrue(sheet.done.exists && sheet.done.isHittable)
        }
    }
}
