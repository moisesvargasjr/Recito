//
//  ImportUITests.swift
//  RecitoUITests
//

import XCTest

final class ImportUITests: RecitoUITestCase {
    private func openImport(seed: Seed = .samples) -> ImportSheetScreen {
        launch(seed: seed)
        library.waitForLoad()
        let sheet = library.openImport()
        XCTAssertTrue(sheet.waitForLoad(), "Import sheet should open")
        return sheet
    }

    func testPastedProseOpensReaderInScriptMode() {
        let sheet = openImport()
        sheet.enter("The first paragraph of a plain spoken talk.\n\nA second paragraph that continues the thought.")
        XCTAssertTrue(sheet.add.isEnabled)
        screenshot("typed")
        sheet.keyboardDone.tapIfPresent()
        assertHittable(sheet.add, "Add")
        sheet.add.tap()
        XCTAssertTrue(reader.waitForLoad(), "Add should open the reader")
        XCTAssertEqual(reader.mode, "script")
    }

    func testOutlineTextOpensReaderInOutlineMode() {
        let sheet = openImport()
        sheet.enter("1. Opening point\n- supporting idea\n2. Second point\n- another idea\n3. Closing point\n- last idea")
        sheet.keyboardDone.tapIfPresent()
        assertHittable(sheet.add, "Add")
        sheet.add.tap()
        XCTAssertTrue(reader.waitForLoad(), "Add should open the reader")
        XCTAssertEqual(reader.mode, "outline")
    }

    func testAddIsDisabledWhenEmpty() {
        let sheet = openImport()
        XCTAssertFalse(sheet.add.isEnabled)
    }

    func testCancelDiscardsText() {
        let sheet = openImport(seed: .many)
        let before = library.cardCount
        sheet.enter("Draft that will be thrown away")
        sheet.keyboardDone.tapIfPresent()
        sheet.cancel.tap()
        wait(for: sheet.root, "exists == false")
        XCTAssertEqual(library.cardCount, before, "Cancel must not add a talk")

        let reopened = library.openImport()
        XCTAssertTrue(reopened.waitForLoad())
        XCTAssertFalse(reopened.add.isEnabled, "a fresh sheet starts empty")
    }

    func testLandscapeWithKeyboardKeepsAddReachable() {
        let sheet = openImport()
        rotate(to: .landscapeLeft)
        sheet.text.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10), "keyboard should appear")
        sheet.text.typeText("Landscape keyboard talk")
        assertHittable(sheet.add, "Add (landscape + keyboard)")
        assertInsideWindow(sheet.add, "Add (landscape + keyboard)")
        screenshot()
    }

    func testKeyboardDoneDismissesKeyboard() {
        let sheet = openImport()
        sheet.text.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(sheet.keyboardDone.waitForExistence(timeout: 5), "keyboard Done button")
        sheet.keyboardDone.tap()
        wait(for: app.keyboards.firstMatch, "exists == false")
        XCTAssertTrue(sheet.root.exists, "sheet stays open")
    }
}

extension XCUIElement {
    /// Taps when the element is on screen, otherwise does nothing.
    func tapIfPresent(timeout: TimeInterval = 2) {
        if waitForExistence(timeout: timeout) { tap() }
    }
}
