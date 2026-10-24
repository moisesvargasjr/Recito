//
//  OrientationSweepUITests.swift
//  RecitoUITests
//
//  Every key screen in portrait, landscapeLeft and landscapeRight: controls are
//  hittable, inside the window and do not overlap each other.
//

import XCTest

final class OrientationSweepUITests: RecitoUITestCase {
    private func sweep(_ body: (Pose) -> Void) {
        for pose in Pose.allCases {
            rotate(to: pose)
            body(pose)
            screenshot()
        }
    }

    private func check(_ named: [(String, XCUIElement)]) {
        for (name, element) in named {
            assertHittable(element, "\(name) [\(currentPose.rawValue)]")
            assertInsideWindow(element, "\(name) [\(currentPose.rawValue)]")
        }
        assertNoOverlap(named)
    }

    /// Toolbar buttons that must be directly visible (never only in overflow).
    private func readerControls(includeMode: Bool = true) -> [(String, XCUIElement)] {
        var controls: [(String, XCUIElement)] = [
            ("Close", reader.close),
            ("Aa", reader.aa),
            ("Prev", reader.prev),
            ("Play", reader.play),
            ("Next", reader.next),
        ]
        if includeMode { controls.insert(("Mode", reader.modeToggle), at: 1) }
        return controls
    }

    func testLibrarySweep() {
        launch(seed: .many)
        library.waitForLoad()
        sweep { _ in
            XCTAssertTrue(library.card(1).waitForExistence(timeout: 10))
            check([
                ("Import tile", library.importTile),
                ("Import button", library.importButton),
                ("Text & Display", library.settingsButton),
                ("Overflow", library.overflow),
            ])
        }
    }

    func testScriptReaderSweep() {
        launchScriptReader()
        sweep { _ in
            check(readerControls() + [("Cue chip", reader.cueChip), ("Pace bar", reader.paceBar)])
        }
    }

    func testOutlineReaderSweep() {
        launchOutlineReader()
        sweep { _ in
            // Play is hidden in outline mode.
            check(readerControls().filter { $0.0 != "Play" })
        }
    }

    func testPacingSheetSweep() {
        launchScriptReader()
        let sheet = reader.openPacing()
        XCTAssertTrue(sheet.waitForLoad())
        sweep { _ in
            var controls: [(String, XCUIElement)] = PacingSheetScreen.presets.map { ("preset \($0)", sheet.preset($0)) }
            controls.append(("Custom", sheet.custom))
            controls.append(("Done", sheet.done))
            controls.append(("Cancel", sheet.cancel))
            check(controls)
        }
    }

    func testVersePaneSheetSweep() {
        launchScriptReader(scripture: .inRecito)
        reader.cueChip.tap()
        XCTAssertTrue(reader.versePane.waitForExistence(timeout: 10))
        sweep { _ in
            XCTAssertTrue(reader.versePane.waitForExistence(timeout: 10))
            check([("Pane Done", reader.versePaneDone)])
            assertInsideWindow(reader.versePane, "verse pane")
        }
    }
}
