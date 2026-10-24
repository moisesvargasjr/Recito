//
//  LibraryUITests.swift
//  RecitoUITests
//

import XCTest

final class LibraryUITests: RecitoUITestCase {

    func testSeededCardsAreVisible() {
        launch(seed: .many)
        library.waitForLoad()
        assertHittable(library.importTile, "import tile")
        assertHittable(library.card(1), "first card")
        XCTAssertGreaterThanOrEqual(library.cardCount, 2)
        screenshot()
    }

    func testSearchFiltersAndClearRestores() {
        launch(seed: .many)
        library.waitForLoad()
        XCTAssertTrue(library.card(1).waitForExistence(timeout: 10))

        library.search("Talk 07")
        XCTAssertTrue(library.card(7).waitForExistence(timeout: 10), "matching card should remain")
        XCTAssertFalse(library.card(1).exists, "non-matching card should be filtered out")
        screenshot("filtered")

        library.clearSearch()
        XCTAssertTrue(library.card(1).waitForExistence(timeout: 10), "clearing search restores the grid")
    }

    func testSearchWithNoMatchesShowsEmptyState() {
        launch(seed: .many)
        library.waitForLoad()
        library.search("zzzzqqq")
        assertHittable(library.emptyStateImport, "empty-state Import")
        expectEmptyStateIdentifierBug()
    }

    /// BUG: LibraryEmptyState's `library.emptyState` id is swallowed by the
    /// parent's `library.root` container, so the element is not addressable.
    private func expectEmptyStateIdentifierBug() {
        XCTExpectFailure("BUG: library.emptyState identifier is not exposed (overridden by library.root)") {
            XCTAssertTrue(library.emptyState.waitForExistence(timeout: 2))
        }
    }

    func testImportButtonOpensSheet() {
        launch(seed: .samples)
        library.waitForLoad()
        let sheet = library.openImport()
        XCTAssertTrue(sheet.waitForLoad(), "Import sheet should open")
        assertHittable(sheet.cancel, "Import Cancel")
    }

    func testImportTileOpensSheet() {
        launch(seed: .samples)
        library.waitForLoad()
        library.importTile.tap()
        XCTAssertTrue(ImportSheetScreen(app: app).waitForLoad())
    }

    func testTextAndDisplayOpens() {
        launch(seed: .samples)
        library.waitForLoad()
        let sheet = library.openTextDisplay()
        XCTAssertTrue(sheet.waitForLoad(), "Text & Display sheet should open")
        assertHittable(sheet.done, "Text & Display Done")
        sheet.done.tap()
        XCTAssertTrue(library.root.waitForExistence(timeout: 5))
    }

    func testContextMenuEditOpensEditSheet() {
        launch(seed: .many)
        library.waitForLoad()
        library.card(1).press(forDuration: 1.0)
        let edit = app.buttons["Edit"].firstMatch
        XCTAssertTrue(edit.waitForExistence(timeout: 5), "context menu should offer Edit")
        edit.tap()
        XCTAssertTrue(EditSheetScreen(app: app).waitForLoad())
    }

    func testContextMenuDeleteRemovesCard() {
        launch(seed: .many)
        library.waitForLoad()
        XCTAssertTrue(library.card(2).waitForExistence(timeout: 10))
        library.card(2).press(forDuration: 1.0)
        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "context menu should offer Delete")
        delete.tap()
        wait(for: library.card(2), "exists == false")
    }

    func testShowHiddenRevealsHiddenTalks() {
        launch(seed: .mixedHidden)
        library.waitForLoad()
        XCTAssertTrue(library.card(1).waitForExistence(timeout: 10))
        XCTAssertFalse(library.card(2).exists, "hidden talk must not show by default")

        library.toggleShowHidden()
        XCTAssertTrue(library.card(2).waitForExistence(timeout: 10), "Show Hidden reveals talk 2")
        screenshot()
    }

    func testEmptySeedShowsImport() {
        launch(seed: .empty)
        library.waitForLoad()
        assertHittable(library.emptyStateImport, "empty-state Import")
        expectEmptyStateIdentifierBug()
        library.emptyStateImport.tap()
        XCTAssertTrue(ImportSheetScreen(app: app).waitForLoad())
    }

    func testGridColumnsMatchDisplay() {
        launch(seed: .many)
        library.waitForLoad()
        let values = diag(AXID.Library.grid)
        guard let columns = values["columns"].flatMap(Int.init) else {
            return XCTFail("grid has no columns diagnostic: \(values)")
        }
        switch displayKind {
        case .outer: XCTAssertEqual(columns, 2, "cover display shows 2 columns")
        case .inner:
            XCTAssertEqual(columns % 2, 0, "inner display uses an even column count")
            XCTAssertGreaterThanOrEqual(columns, 2)
        }
        screenshot()
    }
}
