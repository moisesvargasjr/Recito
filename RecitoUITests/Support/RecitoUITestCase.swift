//
//  RecitoUITestCase.swift
//  RecitoUITests
//
//  Base class: launches the app with the UI-test launch contract, rotates back
//  to portrait around each test, and carries the layout assertions shared by
//  every suite.
//

import XCTest

/// Which physical display the simulator is showing (iPhone Duo).
enum DisplayKind: String {
    case outer, inner
}

enum Seed: String {
    case samples, empty, longScript, outline, many, mixedHidden
}

enum Pose: String, CaseIterable {
    case portrait, landscapeLeft, landscapeRight

    var deviceOrientation: UIDeviceOrientation {
        switch self {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        }
    }
}

enum UITestFixtureID {
    /// `UITestFixture.talkID(n)` in the app: 00000000-0000-0000-0000-00000000000n.
    static func talk(_ number: Int) -> String {
        String(format: "00000000-0000-0000-0000-%012d", number)
    }
}

class RecitoUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
        app = nil
    }

    // MARK: - Launching

    /// Launches with `-uitest -reset -noAnimations -chromeHideDelay 999` plus
    /// `extra`. Passing -chromeHideDelay in `extra` replaces the default; pass
    /// `reset: false` to relaunch with the previous state.
    @discardableResult
    func launch(
        seed: Seed? = .samples,
        extra: [String] = [],
        reset: Bool = true,
        openTalk: Int? = nil
    ) -> XCUIApplication {
        var args = ["-uitest", "-noAnimations"]
        if reset { args.append("-reset") }
        if !extra.contains("-chromeHideDelay") { args += ["-chromeHideDelay", "999"] }
        if let seed { args += ["-seed", seed.rawValue] }
        if let openTalk { args += ["-openTalk", UITestFixtureID.talk(openTalk)] }
        args += extra
        let application = XCUIApplication()
        application.launchArguments = args
        application.launch()
        app = application
        return application
    }

    // MARK: - Display

    var window: XCUIElement { app.windows.firstMatch }

    /// Outer (cover) display has a short side under 500 pt; the inner one is wider.
    var displayKind: DisplayKind {
        let frame = window.frame
        return min(frame.width, frame.height) < 500 ? .outer : .inner
    }

    var currentPose: Pose {
        switch XCUIDevice.shared.orientation {
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return .portrait
        }
    }

    /// Rotates and waits until the window frame stops changing. Returns whether
    /// the window size actually changed: the iPhone Duo cover display in the
    /// simulator keeps its 466x678 portrait window for every device orientation,
    /// so rotation checks there only prove the app survives the orientation event.
    @discardableResult
    func rotate(to pose: Pose) -> Bool {
        let before = window.frame.size
        XCUIDevice.shared.orientation = pose.deviceOrientation
        waitForStableFrame()
        let changed = window.frame.size != before
        if !changed && pose != .portrait {
            XCTContext.runActivity(named: "NOTE: window size unchanged after rotating to \(pose.rawValue)") { _ in }
        }
        return changed
    }

    /// Waits until the window frame is unchanged across consecutive samples.
    func waitForStableFrame(timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        var last = window.frame
        var stableSamples = 0
        while Date() < deadline {
            let probe = XCTestExpectation(description: "frame sample")
            probe.isInverted = true
            _ = XCTWaiter().wait(for: [probe], timeout: 0.15)
            let now = window.frame
            if now == last && !now.isEmpty {
                stableSamples += 1
                if stableSamples >= 3 { return }
            } else {
                stableSamples = 0
                last = now
            }
        }
        XCTFail("Window frame never stabilised (last \(last))", file: file, line: line)
    }

    // MARK: - Diagnostics

    /// Parses a `key=value;key=value` accessibility value of the element with `id`.
    func diag(_ id: String, file: StaticString = #filePath, line: UInt = #line) -> [String: String] {
        let element = anyElement(id)
        guard element.waitForExistence(timeout: 10) else {
            XCTFail("Diagnostics element \(id) not found", file: file, line: line)
            return [:]
        }
        let raw = (element.value as? String) ?? ""
        return Dictionary(
            raw.split(separator: ";").compactMap { pair -> (String, String)? in
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                return parts.count == 2 ? (parts[0], parts[1]) : nil
            },
            uniquingKeysWith: { _, latest in latest }
        )
    }

    /// Reader index from `reader.root` (fails the test when missing).
    func readerIndex(file: StaticString = #filePath, line: UInt = #line) -> Int {
        guard let value = diag(AXID.Reader.root, file: file, line: line)["index"], let index = Int(value) else {
            XCTFail("reader.root has no index diagnostic", file: file, line: line)
            return -1
        }
        return index
    }

    func anyElement(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    // MARK: - Layout assertions

    func assertHittable(_ element: XCUIElement, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), "\(name) does not exist", file: file, line: line)
        XCTAssertTrue(element.isHittable, "\(name) is not hittable (frame \(element.frame))", file: file, line: line)
    }

    func assertInsideWindow(_ element: XCUIElement, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let bounds = window.frame.insetBy(dx: -1, dy: -1)
        XCTAssertTrue(
            bounds.contains(element.frame),
            "\(name) frame \(element.frame) escapes window \(window.frame)",
            file: file, line: line
        )
    }

    /// Asserts no two named elements' frames intersect by more than `tolerance` points.
    func assertNoOverlap(
        _ named: [(String, XCUIElement)],
        tolerance: CGFloat = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for i in named.indices {
            for j in named.indices where j > i {
                let a = named[i].1.frame
                let b = named[j].1.frame
                let overlap = a.intersection(b)
                let overlaps = !overlap.isNull && overlap.width > tolerance && overlap.height > tolerance
                XCTAssertFalse(
                    overlaps,
                    "\(named[i].0) \(a) overlaps \(named[j].0) \(b)",
                    file: file, line: line
                )
            }
        }
    }

    // MARK: - Screenshots

    /// Attaches a screenshot named `<test>-<outer|inner>-<orientation>[-suffix]`.
    func screenshot(_ suffix: String? = nil) {
        let testName = name
            .replacingOccurrences(of: "-[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: " ", with: "_")
        var label = "\(testName)-\(displayKind.rawValue)-\(currentPose.rawValue)"
        if let suffix { label += "-\(suffix)" }
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = label
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Waiting

    /// Waits for `predicate` to hold on `element` (never sleeps).
    func wait(
        for element: XCUIElement,
        _ predicate: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Timed out waiting for \(predicate) on \(element)", file: file, line: line)
    }

    /// Polls `condition` until it holds, using a run-loop wait rather than sleep.
    @discardableResult
    func waitUntil(timeout: TimeInterval = 10, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            let tick = XCTestExpectation(description: "tick")
            tick.isInverted = true
            _ = XCTWaiter().wait(for: [tick], timeout: 0.2)
        }
        return condition()
    }
}
