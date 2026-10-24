//
//  RecitoUITestCase+Flows.swift
//  RecitoUITests
//
//  Multi-step flows shared by several suites.
//

import XCTest

enum ScriptureDestinationOption: String {
    case jwLibrary = "JW Library app"
    case inRecito = "In Recito"
}

extension RecitoUITestCase {
    var library: LibraryScreen { LibraryScreen(app: app) }
    var reader: ReaderScreen { ReaderScreen(app: app) }

    /// Opens the long-script fixture in the reader.
    @discardableResult
    func launchScriptReader(extra: [String] = []) -> ReaderScreen {
        launch(seed: .longScript, extra: extra, openTalk: 1)
        XCTAssertTrue(reader.waitForLoad(), "reader should open for -openTalk")
        return reader
    }

    /// Opens the outline fixture in the reader.
    @discardableResult
    func launchOutlineReader(extra: [String] = []) -> ReaderScreen {
        launch(seed: .outline, extra: extra, openTalk: 1)
        XCTAssertTrue(reader.waitForLoad(), "reader should open for -openTalk")
        return reader
    }

    /// Sets "Open scriptures in" through the picker, then relaunches WITHOUT
    /// -reset so the stored setting is what the reader sees. Ends in the
    /// long-script reader.
    @discardableResult
    func launchScriptReader(scripture option: ScriptureDestinationOption, extra: [String] = []) -> ReaderScreen {
        launch(seed: .longScript, openTalk: 1)
        XCTAssertTrue(reader.waitForLoad(), "reader should open for -openTalk")
        let sheet = reader.openTextDisplay()
        XCTAssertTrue(sheet.waitForLoad(), "Text & Display should open")
        sheet.chooseScriptureDestination(option.rawValue)
        sheet.finish()
        app.terminate()
        launch(seed: .longScript, extra: extra, reset: false, openTalk: 1)
        XCTAssertTrue(reader.waitForLoad(), "reader should reopen after relaunch")
        return reader
    }

    /// Waits for the reader index to differ from `old` and returns it.
    @discardableResult
    func waitForIndexChange(from old: Int?, timeout: TimeInterval = 10) -> Int? {
        waitUntil(timeout: timeout) { reader.index != old }
        return reader.index
    }
}
