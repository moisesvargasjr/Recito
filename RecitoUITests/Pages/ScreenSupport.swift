//
//  ScreenSupport.swift
//  RecitoUITests
//
//  Shared lookup helpers for the page objects: id-first button lookup with a
//  label fallback through the system overflow ("More") menu, where toolbar
//  items can lose their accessibility identifiers.
//

import XCTest

extension XCUIApplication {
    func element(_ id: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// The system toolbar overflow button that is currently on screen (a screen
    /// presented behind a full-screen cover keeps its own, unhittable one).
    var visibleOverflowButton: XCUIElement {
        let all = buttons.matching(identifier: "BottomOverflowBarButtonItem")
        for index in 0..<all.count {
            let candidate = all.element(boundBy: index)
            if candidate.exists && candidate.isHittable { return candidate }
        }
        return buttons["More"].firstMatch
    }
}

enum ControlLookup {
    /// Finds a toolbar control: by id when it is directly visible, otherwise by
    /// label inside the overflow menu (opened as a side effect).
    static func find(
        in app: XCUIApplication,
        id: String,
        label: String,
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        let direct = app.buttons[id]
        if direct.waitForExistence(timeout: timeout), direct.isHittable { return direct }
        let overflow = app.visibleOverflowButton
        if overflow.exists && overflow.isHittable { overflow.tap() }
        return app.cells.buttons[label].firstMatch
    }
}
