//
//  LibraryScreen.swift
//  RecitoUITests
//

import XCTest

struct LibraryScreen {
    let app: XCUIApplication

    var root: XCUIElement { app.element(AXID.Library.root) }
    var grid: XCUIElement { app.element(AXID.Library.grid) }
    var importTile: XCUIElement { app.buttons[AXID.Library.importTile] }
    var importButton: XCUIElement { app.buttons[AXID.Library.importButton] }
    var settingsButton: XCUIElement { app.buttons[AXID.Library.settingsButton] }
    var searchField: XCUIElement { app.searchFields.firstMatch }
    var emptyState: XCUIElement { app.element(AXID.Library.emptyState) }
    var emptyStateImport: XCUIElement { app.buttons[AXID.Library.emptyStateImport] }
    var overflow: XCUIElement { app.visibleOverflowButton }

    func card(_ number: Int) -> XCUIElement {
        app.buttons[AXID.Library.card(UITestFixtureID.talk(number))]
    }

    /// Cards currently in the hierarchy.
    var cardCount: Int {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "library.card.")).count
    }

    @discardableResult
    func waitForLoad() -> Bool {
        root.waitForExistence(timeout: 15)
    }

    func search(_ text: String) {
        searchField.tap()
        searchField.typeText(text)
    }

    func clearSearch() {
        let clear = app.buttons["Clear text"].firstMatch
        if clear.waitForExistence(timeout: 3) {
            clear.tap()
        } else {
            let cancel = app.buttons["Cancel"].firstMatch
            if cancel.exists { cancel.tap() }
        }
    }

    /// Opens the overflow and taps "Show Hidden" (a toggle in the menu).
    func toggleShowHidden() {
        overflow.tap()
        let item = app.cells.buttons["Show Hidden"].firstMatch
        let fallback = app.buttons["Show Hidden"].firstMatch
        if item.waitForExistence(timeout: 5) { item.tap() } else { fallback.tap() }
    }

    func openImport() -> ImportSheetScreen {
        let button = ControlLookup.find(in: app, id: AXID.Library.importButton, label: "Import")
        button.tap()
        return ImportSheetScreen(app: app)
    }

    func openTextDisplay() -> TextDisplaySheetScreen {
        let button = ControlLookup.find(in: app, id: AXID.Library.settingsButton, label: "Text & Display")
        button.tap()
        return TextDisplaySheetScreen(app: app)
    }
}
