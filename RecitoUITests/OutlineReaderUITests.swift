//
//  OutlineReaderUITests.swift
//  RecitoUITests
//

import XCTest

final class OutlineReaderUITests: RecitoUITestCase {
    func testOutlineOpensInOutlineMode() {
        launchOutlineReader()
        XCTAssertEqual(reader.mode, "outline")
        XCTAssertEqual(reader.index, 0)
        screenshot()
    }

    func testRowTapSetsIndex() {
        launchOutlineReader()
        let row = reader.outlineRow(3)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        waitUntil { reader.index == 3 }
        XCTAssertEqual(reader.index, 3)
    }

    func testPreviousAndNextMoveIndex() {
        launchOutlineReader()
        reader.nextControl().tap()
        waitUntil { reader.index == 1 }
        XCTAssertEqual(reader.index, 1)
        reader.nextControl().tap()
        waitUntil { reader.index == 2 }
        XCTAssertEqual(reader.index, 2)
        reader.prevControl().tap()
        waitUntil { reader.index == 1 }
        XCTAssertEqual(reader.index, 1)
    }

    /// BUG: on open (index 0) the outline is scrolled so rows 0-2 are above the
    /// top edge of the screen (row 0 frame y is negative).
    private func expectFirstRowVisibleBug() {
        XCTExpectFailure("BUG: outline reader opens scrolled past the current (first) row") {
            assertHittable(reader.outlineRow(0), "first outline row")
        }
    }

    func testDarkThemeScreenshot() {
        launchOutlineReader(extra: ["-theme", "dark"])
        XCTAssertEqual(reader.mode, "outline")
        expectFirstRowVisibleBug()
        screenshot("dark")
    }
}
