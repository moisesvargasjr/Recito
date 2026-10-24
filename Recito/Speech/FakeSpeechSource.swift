//
//  FakeSpeechSource.swift
//  Recito
//
//  DEBUG-only SpeechSource for UI tests: always available and authorized, never
//  touches the microphone, and optionally "recognizes" a scripted list of words
//  so voice-follow can be exercised end to end.
//

#if DEBUG
import Foundation

final class FakeSpeechSource: SpeechSource {
    let script: [String]
    /// Seconds between scripted words. Zero delivers them all inside `start`.
    let wordInterval: TimeInterval

    private var deliveryTask: Task<Void, Never>?

    init(script: [String] = [], wordInterval: TimeInterval = 0.4) {
        self.script = script
        self.wordInterval = wordInterval
    }

    var isAvailable: Bool { true }

    func requestAuthorization() async -> Bool { true }

    func start(
        localeIdentifier: String,
        onWord: @escaping (RecognizedWord) -> Void,
        onLevel: @escaping (Float) -> Void,
        onStatus: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) async throws {
        onStatus("Listening…")
        guard !script.isEmpty else { return }
        if wordInterval <= 0 {
            script.forEach { onWord(RecognizedWord(text: $0, timestamp: 0)) }
            return
        }
        deliveryTask?.cancel()
        deliveryTask = Task { [script, wordInterval] in
            for (offset, text) in script.enumerated() {
                try? await Task.sleep(nanoseconds: UInt64(wordInterval * 1_000_000_000))
                if Task.isCancelled { return }
                onWord(RecognizedWord(text: text, timestamp: wordInterval * Double(offset + 1)))
            }
        }
    }

    func stop() {
        deliveryTask?.cancel()
        deliveryTask = nil
    }
}
#endif
