//
//  FakeSpeechSourceTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct FakeSpeechSourceTests {
    private final class Collector {
        var words: [RecognizedWord] = []
        var statuses: [String] = []
        var errors: [String] = []
    }

    private func start(_ source: FakeSpeechSource, into c: Collector) async throws {
        try await source.start(
            localeIdentifier: "en-US",
            onWord: { c.words.append($0) },
            onLevel: { _ in },
            onStatus: { c.statuses.append($0) },
            onError: { c.errors.append($0) }
        )
    }

    @Test func isAvailableAndAuthorized() async {
        let source = FakeSpeechSource()
        #expect(source.isAvailable)
        #expect(await source.requestAuthorization())
    }

    @Test func withNoScriptItEmitsNothing() async throws {
        let c = Collector()
        try await start(FakeSpeechSource(), into: c)
        #expect(c.words.isEmpty)
        #expect(c.errors.isEmpty)
    }

    @Test func zeroIntervalDeliversScriptInOrderImmediately() async throws {
        let c = Collector()
        try await start(FakeSpeechSource(script: ["real", "patience", "is"], wordInterval: 0), into: c)
        #expect(c.words.map(\.text) == ["real", "patience", "is"])
    }

    @Test func timestampsFollowTheWordInterval() async throws {
        let c = Collector()
        try await start(FakeSpeechSource(script: ["a", "b", "c"], wordInterval: 0), into: c)
        #expect(c.words.map(\.timestamp) == [0, 0, 0])
        let spaced = Collector()
        try await start(FakeSpeechSource(script: ["a", "b"], wordInterval: 0.05), into: spaced)
        try await Task.sleep(nanoseconds: 400_000_000)
        #expect(spaced.words.map(\.timestamp) == [0.05, 0.1])
    }

    @Test func stopHaltsFurtherWords() async throws {
        let c = Collector()
        let source = FakeSpeechSource(script: ["a", "b", "c"], wordInterval: 0.05)
        try await start(source, into: c)
        source.stop()
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(c.words.isEmpty)
    }

    @Test func reportsListeningStatus() async throws {
        let c = Collector()
        try await start(FakeSpeechSource(), into: c)
        #expect(c.statuses.contains("Listening…"))
    }
}
