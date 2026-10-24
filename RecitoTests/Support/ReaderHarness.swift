//
//  ReaderHarness.swift
//  RecitoTests
//
//  A ReaderViewModel wired to manual clocks and a spy speech source.
//

import Foundation
@testable import Recito

@MainActor
struct ReaderHarness {
    let ticker = ManualTicker()
    let scheduler = ManualScheduler()
    let speech = SpySpeechSource()
    let vm: ReaderViewModel

    init(talk: Talk = TalkFactory.talk(), chromeHideDelay: TimeInterval = 3.5) {
        let ticker = self.ticker
        let scheduler = self.scheduler
        let speech = self.speech
        let deps = ReaderDependencies(
            ticker: ticker,
            scheduler: scheduler,
            alignmentFactory: { ScriptAlignmentEngine(sections: $0) },
            speechSourceFactory: { speech },
            chromeHideDelay: chromeHideDelay
        )
        vm = ReaderViewModel(talk: talk, deps: deps)
    }
}
