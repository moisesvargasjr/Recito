//
//  VoicePredictor.swift
//  Recito
//
//  The predictive glide behind voice-follow, extracted from ReaderViewModel as
//  an immutable value. The recognizer lags ~1-2 s and delivers words in bursts,
//  so the rendered position glides forward at an estimated reading pace and is
//  eased toward what recognition confirms. Gliding continuously also means we
//  pass through every paragraph (no skipping short ones).
//
//  Every transition returns a new value; the tuning constants are unchanged
//  from the original in-line implementation (see VoicePredictorTests).
//

import Foundation

struct VoicePredictor: Equatable {
    /// Time constant for easing the predicted position toward the recognizer.
    /// Larger = smoother but laggier; ~0.28 s reads as fluid without trailing.
    static let followTimeConstant: TimeInterval = 0.28
    /// If the recognizer hasn't advanced for this long, freeze the glide.
    static let pauseHold: TimeInterval = 1.2
    /// Reading speed (words/sec) before any is measured. ~2.6 is about 155 wpm.
    static let defaultWordsPerSecond = 2.6
    /// Max words the prediction may lead the recognizer by.
    static let defaultMaxLeadWords = 18.0
    static let wordsPerSecondRange: ClosedRange<Double> = 1.2...6.0
    /// EWMA weights: running estimate vs. the newest sample.
    private static let paceMemory = 0.7
    private static let paceSampleWeight = 0.3
    /// Pace samples closer together than this, or spanning less than a word, are noise.
    private static let minPaceSampleInterval: TimeInterval = 0.3

    /// Last recognized global token.
    private(set) var recognizedIndex = 0.0
    /// Smoothly advancing read position (what the view scrolls to).
    private(set) var predictedIndex = 0.0
    private(set) var lastRecognizedAdvance: TimeInterval = 0
    private(set) var prevRecognizedIndex = 0.0
    private(set) var prevRecognizedTime: TimeInterval = 0
    private(set) var wordsPerSecond = VoicePredictor.defaultWordsPerSecond
    private(set) var maxLeadWords = VoicePredictor.defaultMaxLeadWords

    /// How far the prediction is ahead of (positive) or behind recognition.
    var leadWords: Double { predictedIndex - recognizedIndex }

    /// Re-anchor everything at `index` (start of follow, or a manual reseat).
    /// The measured pace is kept.
    func reseated(at index: Double, now: TimeInterval) -> VoicePredictor {
        var next = self
        next.recognizedIndex = index
        next.predictedIndex = index
        next.prevRecognizedIndex = index
        next.prevRecognizedTime = now
        next.lastRecognizedAdvance = now
        return next
    }

    /// The recognizer confirmed a new anchor. Moves only the anchor, never the
    /// rendered position, then refines the pace estimate.
    func recognized(index: Double, now: TimeInterval) -> VoicePredictor {
        var next = self
        next.recognizedIndex = index
        next.lastRecognizedAdvance = now
        return next.refiningPace(now: now)
    }

    /// One glide step of `dt` seconds at time `now`.
    func advanced(dt: TimeInterval, now: TimeInterval) -> VoicePredictor {
        var next = self
        let stalled = now - lastRecognizedAdvance > Self.pauseHold
        if !stalled {
            next.predictedIndex += wordsPerSecond * dt
        }
        // Per-tick easing factor: approach the recognizer instead of snapping,
        // so neither a burst of words (lower bound) nor overshooting the lead
        // ceiling (upper bound) produces a visible lurch.
        let k = 1 - exp(-dt / Self.followTimeConstant)
        if next.predictedIndex < recognizedIndex {
            next.predictedIndex += (recognizedIndex - next.predictedIndex) * k
        }
        let leadCeiling = recognizedIndex + maxLeadWords
        if next.predictedIndex > leadCeiling {
            next.predictedIndex += (leadCeiling - next.predictedIndex) * k
        }
        return next
    }

    func withMaxLeadWords(_ words: Double) -> VoicePredictor {
        var next = self
        next.maxLeadWords = words
        return next
    }

    func withWordsPerSecond(_ rate: Double) -> VoicePredictor {
        var next = self
        next.wordsPerSecond = rate
        return next
    }

    /// Smooth the glide speed toward the speaker's actual measured pace.
    private func refiningPace(now: TimeInterval) -> VoicePredictor {
        let deltaWords = recognizedIndex - prevRecognizedIndex
        let deltaTime = now - prevRecognizedTime
        guard deltaTime >= Self.minPaceSampleInterval, deltaWords >= 1 else { return self }
        let instantaneous = deltaWords / deltaTime
        let blended = Self.paceMemory * wordsPerSecond + Self.paceSampleWeight * instantaneous
        var next = self
        next.wordsPerSecond = min(max(blended, Self.wordsPerSecondRange.lowerBound), Self.wordsPerSecondRange.upperBound)
        next.prevRecognizedIndex = recognizedIndex
        next.prevRecognizedTime = now
        return next
    }
}
