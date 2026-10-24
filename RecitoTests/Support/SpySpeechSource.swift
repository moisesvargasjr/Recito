//
//  SpySpeechSource.swift
//  RecitoTests
//
//  A SpeechSource that records calls and lets the test emit words/levels.
//

import Foundation
@testable import Recito

struct SpyStartFailure: LocalizedError {
    var errorDescription: String? { "mic busy" }
}

@MainActor
final class SpySpeechSource: SpeechSource {
    var isAvailable = true
    var authorizationResult = true
    var startError: Error?

    private(set) var authorizationRequests = 0
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var lastLocale: String?

    private var onWord: ((RecognizedWord) -> Void)?
    private var onLevel: ((Float) -> Void)?
    private var onStatus: ((String) -> Void)?
    private var onError: ((String) -> Void)?

    func requestAuthorization() async -> Bool {
        authorizationRequests += 1
        return authorizationResult
    }

    func start(
        localeIdentifier: String,
        onWord: @escaping (RecognizedWord) -> Void,
        onLevel: @escaping (Float) -> Void,
        onStatus: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) async throws {
        startCount += 1
        lastLocale = localeIdentifier
        if let startError { throw startError }
        self.onWord = onWord
        self.onLevel = onLevel
        self.onStatus = onStatus
        self.onError = onError
    }

    func stop() { stopCount += 1 }

    // MARK: - Test drivers

    func say(_ text: String) {
        for (offset, word) in text.split(separator: " ").enumerated() {
            onWord?(RecognizedWord(text: String(word), timestamp: TimeInterval(offset)))
        }
    }

    func emitLevel(_ level: Float) { onLevel?(level) }
    func emitStatus(_ status: String) { onStatus?(status) }
    func emitError(_ message: String) { onError?(message) }
}
