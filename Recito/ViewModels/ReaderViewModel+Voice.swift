//
//  ReaderViewModel+Voice.swift
//  Recito
//
//  Voice-follow orchestration. The glide/pace maths lives in VoicePredictor;
//  this file wires permission, the speech source, and published diagnostics.
//

import SwiftUI
import os

extension ReaderViewModel {
    /// Reading speed (words/sec), estimated live from recognition.
    var wordsPerSecond: Double { predictor.wordsPerSecond }

    /// Max words the prediction may lead the recognizer by.
    var maxLeadWords: Double {
        get { predictor.maxLeadWords }
        set { predictor = predictor.withMaxLeadWords(newValue) }
    }

    @MainActor
    func toggleVoiceFollow(localeIdentifier: String) async {
        if voiceFollowActive { stopVoiceFollow() } else { await startVoiceFollow(localeIdentifier: localeIdentifier) }
    }

    @MainActor
    func startVoiceFollow(localeIdentifier: String) async {
        guard voiceAvailable, mode == .script else {
            voiceStatus = "Voice-follow needs script mode on a supported device."
            return
        }
        voiceStatus = "Requesting permission…"
        guard await speechSource.requestAuthorization() else {
            voiceStatus = "Microphone or speech permission denied. Enable it in Settings."
            return
        }
        isPlaying = false                 // voice drives position, not time-scroll
        anchorVoice(atSection: currentIndex)
        startClock()                      // keep pacing running + drive the glide
        voiceFollowActive = true
        observeThermalState()
        recognizedText = ""
        voiceStatus = "Starting…"
        wakeChrome()
        await beginListening(localeIdentifier: localeIdentifier)
    }

    @MainActor
    private func beginListening(localeIdentifier: String) async {
        do {
            try await speechSource.start(
                localeIdentifier: localeIdentifier,
                onWord: { [weak self] in self?.handleRecognized($0) },
                onLevel: { [weak self] in self?.audioLevel = $0 },
                onStatus: { [weak self] in self?.voiceStatus = $0 },
                onError: { [weak self] in self?.voiceStatus = "Error: \($0)" }
            )
        } catch {
            voiceFollowActive = false
            voiceStatus = "Couldn't start: \(error.localizedDescription)"
            speechSource.stop()
        }
    }

    private func handleRecognized(_ word: RecognizedWord) {
        appendRecognized(word.text)
        guard let position = alignmentEngine.consume(word) else { return }
        // Only move the recognition *anchor* here — never the rendered
        // position. The ticker eases the prediction toward this, so a burst of
        // recognized words can't yank the scroll.
        predictor = predictor.recognized(index: Double(position.globalIndex), now: elapsed)
    }

    private func appendRecognized(_ word: String) {
        var words = recognizedText.split(separator: " ").map(String.init)
        words.append(word)
        recognizedText = words.suffix(12).joined(separator: " ")
    }

    func stopVoiceFollow() {
        speechSource.stop()
        voiceFollowActive = false
        audioLevel = 0
        voiceStatus = ""
        voicePosition = nil
        if let thermalObserver {
            NotificationCenter.default.removeObserver(thermalObserver)
            self.thermalObserver = nil
        }
    }

    /// Pause voice-follow: stop listening and hold the pacing clock, so the
    /// timer pauses too (symmetric with pausing auto-scroll).
    func pauseVoice() {
        stopVoiceFollow()
        stopClock()
    }

    /// Manually re-anchor voice tracking to a section (e.g. double-tap when the
    /// recognizer fell behind) — stays in voice-follow, does not auto-scroll.
    func reseatVoice(to section: Int) {
        anchorVoice(atSection: section)
        currentIndex = section
    }

    /// Seat the alignment cursor and predictor at the start of `section`.
    private func anchorVoice(atSection section: Int) {
        alignmentEngine.reset(to: section)
        let index = Double(max(alignmentEngine.currentGlobalIndex, 0))
        predictor = predictor.reseated(at: index, now: elapsed)
    }

    /// One clock tick of the glide; publishes the position the view scrolls to.
    func advanceVoiceGlide(dt: TimeInterval) {
        predictor = predictor.advanced(dt: dt, now: elapsed)
        voicePosition = alignmentEngine.position(forFractionalGlobalIndex: predictor.predictedIndex)
        voiceLeadWords = predictor.leadWords
        voiceRecognizedIndex = predictor.recognizedIndex
    }

    // MARK: - Thermal diagnostics

    /// Log thermal state at start and on every change while voice-follow runs,
    /// so a freeze during a long talk can be correlated with thermal throttling.
    private func observeThermalState() {
        logThermalState()
        if let thermalObserver {
            NotificationCenter.default.removeObserver(thermalObserver)
        }
        thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.logThermalState() }
    }

    private func logThermalState() {
        let name: String
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: name = "nominal"
        case .fair: name = "fair"
        case .serious: name = "serious"
        case .critical: name = "critical"
        @unknown default: name = "unknown"
        }
        voiceLog.notice("thermalState=\(name, privacy: .public) elapsed=\(Int(self.elapsed))s")
        if name == "serious" || name == "critical" {
            voiceStatus = "Device warm (\(name)) — voice tracking may stutter."
        }
    }
}
