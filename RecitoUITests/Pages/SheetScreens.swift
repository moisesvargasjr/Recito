//
//  SheetScreens.swift
//  RecitoUITests
//
//  Page objects for the Pacing, Import, Edit and Text & Display sheets.
//

import XCTest

struct PacingSheetScreen {
    let app: XCUIApplication
    static let presets = [10, 15, 30, 45, 60]

    var root: XCUIElement { app.element(AXID.Pacing.root) }
    var done: XCUIElement { app.buttons[AXID.Pacing.done] }
    var cancel: XCUIElement { app.buttons[AXID.Pacing.cancel] }
    var custom: XCUIElement { app.buttons[AXID.Pacing.custom] }
    var preview: XCUIElement { app.element(AXID.Pacing.preview) }

    func preset(_ minutes: Int) -> XCUIElement { app.buttons[AXID.Pacing.preset(minutes)] }

    @discardableResult
    func waitForLoad() -> Bool { root.waitForExistence(timeout: 10) }
}

struct ImportSheetScreen {
    let app: XCUIApplication

    var root: XCUIElement { app.element(AXID.Import.root) }
    var text: XCUIElement { app.textViews[AXID.Import.text] }
    var add: XCUIElement { app.buttons[AXID.Import.create] }
    var cancel: XCUIElement { app.buttons[AXID.Import.cancel] }
    var keyboardDone: XCUIElement { app.buttons[AXID.Import.keyboardDone] }

    @discardableResult
    func waitForLoad() -> Bool { root.waitForExistence(timeout: 10) }

    /// Types `content` (newlines included) into the editor.
    func enter(_ content: String) {
        text.tap()
        text.typeText(content)
    }
}

struct EditSheetScreen {
    let app: XCUIApplication

    var root: XCUIElement { app.element(AXID.Edit.root) }
    var title: XCUIElement { app.textFields[AXID.Edit.title] }
    var text: XCUIElement { app.textViews[AXID.Edit.text] }
    var save: XCUIElement { app.buttons[AXID.Edit.save] }
    var cancel: XCUIElement { app.buttons[AXID.Edit.cancel] }
    var keyboardDone: XCUIElement { app.buttons[AXID.Edit.keyboardDone] }

    @discardableResult
    func waitForLoad() -> Bool { root.waitForExistence(timeout: 10) }
}

struct TextDisplaySheetScreen {
    let app: XCUIApplication

    var root: XCUIElement { app.element(AXID.Text.root) }
    var done: XCUIElement { app.buttons[AXID.Text.done] }
    var textSize: XCUIElement { app.sliders[AXID.Text.textSize] }
    var scripturePicker: XCUIElement { app.buttons[AXID.Text.scriptureDestination] }

    @discardableResult
    func waitForLoad() -> Bool { root.waitForExistence(timeout: 10) }

    /// Scrolls the form until the scripture picker is on screen.
    func revealScripturePicker() {
        var swipes = 0
        while !(scripturePicker.exists && scripturePicker.isHittable) && swipes < 8 {
            root.swipeUp()
            swipes += 1
        }
    }

    /// Scrolls back to the top, where the Done button is reachable, and taps it.
    func finish() {
        var swipes = 0
        while !(done.exists && done.isHittable) && swipes < 8 {
            root.swipeDown()
            swipes += 1
        }
        done.tap()
    }

    /// Chooses "JW Library app" or "In Recito" through the menu picker.
    func chooseScriptureDestination(_ option: String) {
        revealScripturePicker()
        scripturePicker.tap()
        app.buttons[option].firstMatch.tap()
    }
}
