//
//  ReaderScreen.swift
//  RecitoUITests
//

import XCTest

struct ReaderScreen {
    let app: XCUIApplication

    var root: XCUIElement { app.element(AXID.Reader.root) }
    var paceBar: XCUIElement { app.element(AXID.Reader.paceBar) }
    var cueChip: XCUIElement { app.buttons[AXID.Reader.cueChip] }
    var backToCurrent: XCUIElement { app.buttons[AXID.Reader.backToCurrent] }
    var resume: XCUIElement { app.buttons[AXID.Reader.resume] }
    var versePane: XCUIElement { app.element(AXID.VersePane.root) }
    var versePaneDone: XCUIElement { app.buttons[AXID.VersePane.done] }

    // Directly addressable toolbar buttons (no overflow fallback).
    var close: XCUIElement { app.buttons[AXID.Reader.close] }
    var modeToggle: XCUIElement { app.buttons[AXID.Reader.modeToggle] }
    var aa: XCUIElement { app.buttons[AXID.Reader.aa] }
    var prev: XCUIElement { app.buttons[AXID.Reader.prev] }
    var play: XCUIElement { app.buttons[AXID.Reader.play] }
    var next: XCUIElement { app.buttons[AXID.Reader.next] }

    @discardableResult
    func waitForLoad(timeout: TimeInterval = 15) -> Bool { root.waitForExistence(timeout: timeout) }

    private func field(_ key: String) -> String? {
        guard let raw = root.value as? String else { return nil }
        for pair in raw.split(separator: ";") where pair.hasPrefix("\(key)=") {
            return String(pair.dropFirst(key.count + 1))
        }
        return nil
    }

    var index: Int? { field("index").flatMap(Int.init) }
    var mode: String? { field("mode") }
    var layout: String? { field("layout") }

    // MARK: - Fallback-aware controls

    func closeControl() -> XCUIElement { ControlLookup.find(in: app, id: AXID.Reader.close, label: "Close") }
    func prevControl() -> XCUIElement { ControlLookup.find(in: app, id: AXID.Reader.prev, label: "Previous") }
    func nextControl() -> XCUIElement { ControlLookup.find(in: app, id: AXID.Reader.next, label: "Next") }
    func playControl() -> XCUIElement { ControlLookup.find(in: app, id: AXID.Reader.play, label: "Play") }

    func aaControl() -> XCUIElement {
        ControlLookup.find(in: app, id: AXID.Reader.aa, label: "Text & Display")
    }

    /// Mode toggle label is "Show Outline" / "Show Script".
    func modeControl(showing target: String) -> XCUIElement {
        ControlLookup.find(in: app, id: AXID.Reader.modeToggle, label: "Show \(target)")
    }

    /// The timer lives in the overflow with an "m:ss / m:ss" label.
    func timerControl() -> XCUIElement {
        let direct = app.buttons[AXID.Reader.timer]
        if direct.exists && direct.isHittable { return direct }
        let overflow = app.visibleOverflowButton
        if overflow.exists && overflow.isHittable { overflow.tap() }
        return app.cells.buttons.matching(NSPredicate(format: "label CONTAINS ' / '")).firstMatch
    }

    func openPacing() -> PacingSheetScreen {
        timerControl().tap()
        return PacingSheetScreen(app: app)
    }

    func openTextDisplay() -> TextDisplaySheetScreen {
        aaControl().tap()
        return TextDisplaySheetScreen(app: app)
    }

    func outlineRow(_ index: Int) -> XCUIElement { app.element(AXID.Reader.outlineRow(index)) }

    /// A drag that previews the script without moving playback.
    func dragScript() {
        let start = root.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.7))
        let end = root.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.3))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
}
