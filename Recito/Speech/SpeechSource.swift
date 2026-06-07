//
//  SpeechSource.swift
//  Recito
//
//  PHASE 2. Abstracts on-device speech recognition behind a protocol so the
//  iOS-26 SpeechAnalyzer path and the SFSpeechRecognizer fallback are
//  interchangeable and testable. Recognized words are delivered via a callback.
//

import Foundation

/// One recognized word from the speech stream.
struct RecognizedWord: Equatable {
    let text: String
    let timestamp: TimeInterval
}

protocol SpeechSource: AnyObject {
    /// Whether voice-follow is usable on this device/locale right now.
    var isAvailable: Bool { get }

    /// Request mic + speech-recognition permission. Returns true if both granted.
    func requestAuthorization() async -> Bool

    /// Begin recognizing. Newly recognized words go to `onWord`, and a 0–1 mic
    /// level goes to `onLevel` (for the live "listening" indicator). Both are
    /// delivered on the main thread.
    func start(
        localeIdentifier: String,
        onWord: @escaping (RecognizedWord) -> Void,
        onLevel: @escaping (Float) -> Void,
        onStatus: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) async throws

    func stop()
}
