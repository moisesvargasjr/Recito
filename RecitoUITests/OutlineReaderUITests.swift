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

    func testDarkThemeScreenshot() {
        launchOutlineReader(extra: ["-theme", "dark"])
        XCTAssertEqual(reader.mode, "outline")
        assertHittable(reader.outlineRow(0), "first outline row")
        screenshot("dark")
    }
}
