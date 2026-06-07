//
//  NoOpSpeechSource.swift
//  Recito
//
//  PHASE 2. A valid SpeechSource that never produces words — the Tier C build.
//  The app is fully functional with this in place; voice-follow simply isn't
//  offered.
//

import Foundation

final class NoOpSpeechSource: SpeechSource {
    var isAvailable: Bool { false }
    func requestAuthorization() async -> Bool { false }
    func start(
        localeIdentifier: String,
        onWord: @escaping (RecognizedWord) -> Void,
        onLevel: @escaping (Float) -> Void,
        onStatus: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) async throws {}
    func stop() {}
}
