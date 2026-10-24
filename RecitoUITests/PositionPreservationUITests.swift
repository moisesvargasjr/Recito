//
//  PositionPreservationUITests.swift
//  RecitoUITests
//
//  The reading position (diagnostic index) survives rotation and text-size
//  changes.
//

import XCTest

final class PositionPreservationUITests: RecitoUITestCase {
    private func advance(by steps: Int) -> Int {
        for _ in 0..<steps {
            let before = reader.index
            reader.nextControl().tap()
            waitForIndexChange(from: before)
        }
        return reader.index ?? -1
    }

    func testIndexSurvivesRotationThroughAllOrientations() {
        launchScriptReader()
        let target = advance(by: 10)
        XCTAssertGreaterThan(target, 0)
        for pose in [Pose.landscapeLeft, .landscapeRight, .portrait] {
            rotate(to: pose)
            XCTAssertTrue(reader.waitForLoad())
            XCTAssertEqual(reader.index, target, "index changed after rotating to \(pose)")
            screenshot()
        }
    }

    func testIndexDoesNotJumpWhenRotatingWhilePlaying() {
        launchScriptReader()
        _ = advance(by: 3)
        reader.playControl().tap()
        let before = reader.index ?? -1
        for pose in [Pose.landscapeLeft, .landscapeRight, .portrait] {
            rotate(to: pose)
            XCTAssertTrue(reader.waitForLoad())
            let after = reader.index ?? -1
            XCTAssertGreaterThanOrEqual(after, before - 1, "index went backwards by more than 1 at \(pose)")
            XCTAssertLessThanOrEqual(after, before + 2, "index jumped forward by more than 2 at \(pose)")
        }
    }

    func testIndexSurvivesTextSizeChange() {
        launchScriptReader()
        let target = advance(by: 4)
        let sheet = reader.openTextDisplay()
        XCTAssertTrue(sheet.waitForLoad())
        sheet.textSize.adjust(toNormalizedSliderPosition: 0.95)
        sheet.done.tap()
        wait(for: sheet.root, "exists == false")
        XCTAssertEqual(reader.index, target, "text size change must not move the reading position")
        screenshot("larger")

        let smaller = reader.openTextDisplay()
        XCTAssertTrue(smaller.waitForLoad())
        smaller.textSize.adjust(toNormalizedSliderPosition: 0.05)
        smaller.done.tap()
        wait(for: smaller.root, "exists == false")
        XCTAssertEqual(reader.index, target)
    }
}
