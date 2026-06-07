//
//  SFSpeechSource.swift
//  Recito
//
//  PHASE 2 — Tier B. On-device speech recognition via SFSpeechRecognizer +
//  AVAudioEngine. SFSpeechRecognizer finalizes after pauses / ~1 min, so we
//  keep the audio engine running and transparently restart the recognition
//  task to give continuous long-form listening.
//

import Foundation
import Speech
import AVFoundation

final class SFSpeechSource: SpeechSource {
    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    /// How many words of the *current* request's transcription we've emitted.
    private var emittedWordCount = 0
    /// True between start() and stop(); gates auto-restart.
    private var active = false

    // Held so we can restart the recognition task without re-tapping audio.
    private var onWord: ((RecognizedWord) -> Void)?
    private var onError: ((String) -> Void)?

    enum SpeechError: Error { case unavailable }

    var isAvailable: Bool {
        guard let recognizer = SFSpeechRecognizer() else { return false }
        return recognizer.isAvailable
    }

    func requestAuthorization() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else { return false }
        return await requestMicPermission()
    }

    private func requestMicPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func start(
        localeIdentifier: String,
        onWord: @escaping (RecognizedWord) -> Void,
        onLevel: @escaping (Float) -> Void,
        onStatus: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) async throws {
        stop()

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) else {
            await MainActor.run { onError("No recognizer for \(localeIdentifier).") }
            throw SpeechError.unavailable
        }
        guard recognizer.isAvailable else {
            await MainActor.run { onError("Recognizer for \(localeIdentifier) isn't available right now.") }
            throw SpeechError.unavailable
        }
        self.recognizer = recognizer
        self.onWord = onWord
        self.onError = onError

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
            let level = Self.micLevel(buffer)
            DispatchQueue.main.async { onLevel(level) }
        }
        audioEngine.prepare()
        try audioEngine.start()
        onStatus("Listening (\(localeIdentifier))…")

        active = true
        beginTask()
    }

    /// Create a fresh recognition request + task. Called on start and on each
    /// finalize/error while still active, for continuous recognition.
    private func beginTask() {
        guard active, let recognizer else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        self.request = request
        emittedWordCount = 0

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let words = result.bestTranscription.formattedString.split(separator: " ")
                if words.count > self.emittedWordCount {
                    let fresh = words[self.emittedWordCount..<words.count].map(String.init)
                    self.emittedWordCount = words.count
                    let emit = self.onWord
                    DispatchQueue.main.async {
                        for word in fresh { emit?(RecognizedWord(text: word, timestamp: 0)) }
                    }
                }
            }

            let finished = (result?.isFinal ?? false) || error != nil
            guard finished else { return }

            if let error, self.active {
                let report = self.onError
                DispatchQueue.main.async { report?(error.localizedDescription) }
            }
            // Seamlessly restart so listening is continuous.
            if self.active {
                self.task = nil
                self.request = nil
                self.beginTask()
            }
        }
    }

    /// Rough normalized (0–1) mic level from a buffer's peak amplitude.
    private static func micLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        let samples = channels[0]
        var peak: Float = 0
        for i in 0..<count { peak = max(peak, abs(samples[i])) }
        // Light compression so quiet speech still shows movement.
        return min(1, peak * 6)
    }

    func stop() {
        active = false
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        recognizer = nil
        onWord = nil
        onError = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
