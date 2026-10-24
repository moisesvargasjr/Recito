//
//  LaunchUITests.swift
//  RecitoUITests
//

import XCTest

final class LaunchUITests: RecitoUITestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { true }

    func testLaunch() {
        launch(seed: .samples)
        XCTAssertTrue(LibraryScreen(app: app).root.waitForExistence(timeout: 15), "library should be the launch screen")
        screenshot()
    }
}
