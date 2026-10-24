//
//  EditSheetUITests.swift
//  RecitoUITests
//

import XCTest

final class EditSheetUITests: RecitoUITestCase {
    private func openEdit() -> EditSheetScreen {
        launch(seed: .many)
        library.waitForLoad()
        library.card(1).press(forDuration: 1.0)
        let edit = app.buttons["Edit"].firstMatch
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        let sheet = EditSheetScreen(app: app)
        XCTAssertTrue(sheet.waitForLoad(), "Edit sheet should open")
        return sheet
    }

    func testSaveUpdatesTitle() {
        let sheet = openEdit()
        sheet.title.tap()
        sheet.title.typeText(" Edited")
        sheet.keyboardDone.tapIfPresent()
        assertHittable(sheet.save, "Save")
        sheet.save.tap()
        wait(for: sheet.root, "exists == false")
        let card = library.card(1)
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertTrue(card.label.contains("Edited"), "card label should include the new title: \(card.label)")
    }

    func testCancelKeepsTitle() {
        let sheet = openEdit()
        sheet.title.tap()
        sheet.title.typeText(" Discarded")
        sheet.keyboardDone.tapIfPresent()
        sheet.cancel.tap()
        wait(for: sheet.root, "exists == false")
        XCTAssertFalse(library.card(1).label.contains("Discarded"))
    }

    func testLandscapeWithKeyboardKeepsSaveReachable() {
        let sheet = openEdit()
        rotate(to: .landscapeRight)
        sheet.text.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10), "keyboard should appear")
        assertHittable(sheet.save, "Save (landscape + keyboard)")
        assertInsideWindow(sheet.save, "Save (landscape + keyboard)")
        screenshot()
    }

    func testKeyboardDoneDismissesKeyboard() {
        let sheet = openEdit()
        sheet.text.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(sheet.keyboardDone.waitForExistence(timeout: 5))
        sheet.keyboardDone.tap()
        wait(for: app.keyboards.firstMatch, "exists == false")
    }
}
