//
//  SpeechAnalyzerSource.swift
//  Recito
//
//  PHASE 2 — Tier A (iOS 26+). Continuous long-form on-device recognition via
//  SpeechAnalyzer + SpeechTranscriber. Unlike SFSpeechRecognizer it doesn't
//  finalize/stop after pauses, so it tracks a whole talk without restarting.
//

import Foundation
import Speech
import AVFoundation

@available(iOS 26.0, *)
final class SpeechAnalyzerSource: SpeechSource {
    private let audioEngine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    private var converter: AVAudioConverter?
    private var analyzerFormat: AVAudioFormat?
    /// Words already emitted for the current (not-yet-final) phrase.
    private var emittedInPhrase = 0

    var isAvailable: Bool { true } // gated by #available where constructed

    func requestAuthorization() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else { return false }
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
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

        let locale = Locale(identifier: localeIdentifier)
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        self.transcriber = transcriber

        // Ensure the language model is installed (downloads on first use).
        do {
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                onStatus("Downloading \(localeIdentifier) model… (one-time)")
                try await request.downloadAndInstall()
            }
        } catch {
            onError("Language model unavailable: \(error.localizedDescription)")
            throw error
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation

        // Audio capture.
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = audioEngine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        if let analyzerFormat {
            converter = AVAudioConverter(from: inputFormat, to: analyzerFormat)
        }
        let converter = self.converter
        let targetFormat = analyzerFormat

        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
            let level = Self.micLevel(buffer)
            DispatchQueue.main.async { onLevel(level) }
            let outBuffer = Self.convert(buffer, using: converter, to: targetFormat)
            continuation.yield(AnalyzerInput(buffer: outBuffer))
        }
        audioEngine.prepare()
        try audioEngine.start()
        onStatus("Listening (\(localeIdentifier))…")

        emittedInPhrase = 0
        resultsTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    guard let self else { return }
                    let words = String(result.text.characters)
                        .split(whereSeparator: { $0 == " " || $0 == "\n" })
                        .map(String.init)
                    if words.count > self.emittedInPhrase {
                        for word in words[self.emittedInPhrase...] {
                            onWord(RecognizedWord(text: word, timestamp: 0))
                        }
                        self.emittedInPhrase = words.count
                    }
                    if result.isFinal { self.emittedInPhrase = 0 }
                }
            } catch {
                onError("Recognition error: \(error.localizedDescription)")
            }
        }

        try await analyzer.start(inputSequence: stream)
    }

    /// Convert a mic buffer to the analyzer's format (no-op if no converter).
    private static func convert(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter?,
        to format: AVAudioFormat?
    ) -> AVAudioPCMBuffer {
        guard let converter, let format else { return buffer }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return buffer }
        var consumed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        return error == nil ? output : buffer
    }

    private static func micLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        let samples = channels[0]
        var peak: Float = 0
        for i in 0..<count { peak = max(peak, abs(samples[i])) }
        return min(1, peak * 6)
    }

    func stop() {
        inputContinuation?.finish()
        inputContinuation = nil
        resultsTask?.cancel()
        resultsTask = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        let analyzer = self.analyzer
        Task { try? await analyzer?.finalizeAndFinishThroughEndOfInput() }
        self.analyzer = nil
        transcriber = nil
        converter = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
