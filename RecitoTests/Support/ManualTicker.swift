//
//  ManualTicker.swift
//  RecitoTests
//
//  A ReaderTicker the test drives by hand, so playback is deterministic.
//

import Combine
import Foundation
@testable import Recito

@MainActor
final class ManualTicker: ReaderTicker {
    private(set) var startCount = 0
    private(set) var cancelCount = 0
    private(set) var interval: TimeInterval = 0
    private var handler: ((TimeInterval) -> Void)?

    var isRunning: Bool { handler != nil }

    func start(interval: TimeInterval, tick: @escaping (TimeInterval) -> Void) -> Cancellable {
        startCount += 1
        self.interval = interval
        handler = tick
        return AnyCancellable { [weak self] in
            MainActor.assumeIsolated {
                self?.cancelCount += 1
                self?.handler = nil
            }
        }
    }

    /// Deliver `count` ticks (no-op once cancelled).
    func fire(_ count: Int = 1) {
        for _ in 0..<count {
            handler?(interval)
        }
    }
}
