//
//  VoicePredictorTests.swift
//  RecitoTests
//
//  Characterization tests: the expected numbers were derived from the glide
//  logic as it lived inside ReaderViewModel (0.28 s easing, 1.2 s stall freeze,
//  18-word lead cap, 1.2...6.0 w/s pace clamp, 0.7/0.3 EWMA) before extraction.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct VoicePredictorTests {
    private let dt = 1.0 / 60.0

    private func started(at index: Double = 0) -> VoicePredictor {
        VoicePredictor().reseated(at: index, now: 0)
    }

    // MARK: Constants

    @Test func defaultsMatchTheOriginalTuning() {
        let p = VoicePredictor()
        #expect(p.wordsPerSecond == 2.6)
        #expect(p.maxLeadWords == 18)
        #expect(VoicePredictor.followTimeConstant == 0.28)
        #expect(VoicePredictor.pauseHold == 1.2)
    }

    // MARK: Free-run glide

    @Test func glidesAtReadingPaceWhenNotStalled() {
        let p = started(at: 10).advanced(dt: dt, now: dt)
        #expect(abs(p.predictedIndex - (10 + 2.6 * dt)) < 1e-9)
    }

    @Test func freezesWhenRecognizerHasBeenSilentPastPauseHold() {
        let p = started(at: 10).advanced(dt: dt, now: 1.3)
        #expect(p.predictedIndex == 10)
    }

    @Test func stillGlidesRightAtTheHoldBoundary() {
        // `>` not `>=`: exactly 1.2 s of silence is not yet a stall.
        let p = started(at: 10).advanced(dt: dt, now: 1.2)
        #expect(p.predictedIndex > 10)
    }

    // MARK: Easing toward recognition

    @Test func easesUpToARecognizerThatOvertookTheGlide() {
        let p = started(at: 10)
            .recognized(index: 20, now: 0.1)
            .advanced(dt: dt, now: 0.2)
        // free-run 10.04333, then +(20 - 10.04333) * (1 - e^(-dt/0.28)).
        #expect(abs(p.predictedIndex - 10.618698) < 1e-5)
        #expect(p.leadWords < 0)
    }

    @Test func leadStaysNearTheCeilingWhenRecognizerStopsAdvancing() {
        var p = started(at: 0)
        for _ in 0..<600 { p = p.advanced(dt: dt, now: 0) }
        // Steady state is ceiling + glide/k, about 18.75 words.
        #expect(p.leadWords > 18)
        #expect(p.leadWords < 19)
    }

    @Test func customLeadCeilingIsHonoured() {
        var p = started(at: 0).withMaxLeadWords(5)
        for _ in 0..<600 { p = p.advanced(dt: dt, now: 0) }
        #expect(p.leadWords > 5)
        #expect(p.leadWords < 6)
    }

    // MARK: Pace estimation

    @Test func recognitionBlendsMeasuredPaceIntoTheEstimate() {
        let p = started(at: 0).recognized(index: 5, now: 2)
        // 0.7 * 2.6 + 0.3 * (5 / 2)
        #expect(abs(p.wordsPerSecond - 2.57) < 1e-9)
        #expect(p.recognizedIndex == 5)
        #expect(p.lastRecognizedAdvance == 2)
    }

    @Test func paceIgnoresSamplesCloserThanPointThreeSeconds() {
        let p = started(at: 0).recognized(index: 5, now: 0.29)
        #expect(p.wordsPerSecond == 2.6)
        #expect(p.recognizedIndex == 5)
    }

    @Test func paceIgnoresSamplesWithoutAFullWord() {
        let p = started(at: 0).recognized(index: 0.5, now: 2)
        #expect(p.wordsPerSecond == 2.6)
    }

    @Test func paceClampsToSixWordsPerSecond() {
        let p = started(at: 0).recognized(index: 1000, now: 1)
        #expect(p.wordsPerSecond == 6.0)
    }

    @Test func paceClampsToOnePointTwoWordsPerSecond() {
        let p = started(at: 0).withWordsPerSecond(1.2).recognized(index: 1, now: 100)
        #expect(p.wordsPerSecond == 1.2)
    }

    @Test func skippedPaceSampleDoesNotMovePreviousAnchor() {
        let p = started(at: 0)
            .recognized(index: 5, now: 0.1)      // too soon: ignored
            .recognized(index: 10, now: 2)       // measured against (0, 0)
        // 0.7 * 2.6 + 0.3 * (10 / 2)
        #expect(abs(p.wordsPerSecond - 3.32) < 1e-9)
    }

    // MARK: Reseat

    @Test func reseatMovesEveryAnchorButKeepsPace() {
        let paced = started(at: 0).recognized(index: 5, now: 2)
        let p = paced.reseated(at: 40, now: 9)
        #expect(p.recognizedIndex == 40)
        #expect(p.predictedIndex == 40)
        #expect(p.prevRecognizedIndex == 40)
        #expect(p.prevRecognizedTime == 9)
        #expect(p.lastRecognizedAdvance == 9)
        #expect(p.wordsPerSecond == paced.wordsPerSecond)
    }

    @Test func functionsReturnNewValuesWithoutMutatingTheReceiver() {
        let original = started(at: 3)
        _ = original.advanced(dt: dt, now: dt)
        _ = original.recognized(index: 9, now: 2)
        #expect(original == started(at: 3))
    }
}
