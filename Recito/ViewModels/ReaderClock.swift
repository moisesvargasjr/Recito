//
//  ReaderClock.swift
//  Recito
//
//  Time and collaborator seams for ReaderViewModel. Production uses a
//  RunLoop timer and the main queue; tests inject manual implementations so
//  playback, chrome auto-hide and the voice glide are fully deterministic.
//

import Foundation
import Combine

/// Delivers repeating ticks. `tick` receives the elapsed seconds per tick.
protocol ReaderTicker {
    func start(interval: TimeInterval, tick: @escaping (TimeInterval) -> Void) -> Cancellable
}

/// Runs one-shot work after a delay.
protocol ReaderScheduler {
    func schedule(after delay: TimeInterval, work: @escaping () -> Void) -> Cancellable
}

/// 60 Hz timer on the main run loop in `.common` mode (keeps ticking while
/// the user scrolls).
struct TimerTicker: ReaderTicker {
    func start(interval: TimeInterval, tick: @escaping (TimeInterval) -> Void) -> Cancellable {
        let timer = Timer(timeInterval: interval, repeats: true) { _ in tick(interval) }
        RunLoop.main.add(timer, forMode: .common)
        return AnyCancellable { timer.invalidate() }
    }
}

struct MainQueueScheduler: ReaderScheduler {
    func schedule(after delay: TimeInterval, work: @escaping () -> Void) -> Cancellable {
        let item = DispatchWorkItem(block: work)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        return AnyCancellable { item.cancel() }
    }
}

/// Everything ReaderViewModel needs from the outside world.
struct ReaderDependencies {
    static let defaultChromeHideDelay: TimeInterval = 3.5

    var ticker: ReaderTicker
    var scheduler: ReaderScheduler
    var alignmentFactory: ([ScriptSection]) -> AlignmentEngine
    var speechSourceFactory: () -> SpeechSource
    var chromeHideDelay: TimeInterval

    static var live: ReaderDependencies {
        ReaderDependencies(
            ticker: TimerTicker(),
            scheduler: MainQueueScheduler(),
            alignmentFactory: { ScriptAlignmentEngine(sections: $0) },
            speechSourceFactory: { bestSpeechSource() },
            chromeHideDelay: defaultChromeHideDelay
        )
    }

    /// Tier A (SpeechAnalyzer) on iOS 26+, otherwise Tier B (SFSpeechRecognizer).
    static func bestSpeechSource() -> SpeechSource {
        if #available(iOS 26.0, *) {
            return SpeechAnalyzerSource()
        }
        return SFSpeechSource()
    }
}
