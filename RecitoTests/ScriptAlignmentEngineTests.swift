//
//  ScriptAlignmentEngineTests.swift
//  RecitoTests
//
//  The voice-follow brain: tracks position, tolerates imperfect transcription.
//

import Testing
import Foundation
@testable import Recito

struct ScriptAlignmentEngineTests {

    private func engine() -> ScriptAlignmentEngine {
        // Two reading sections.
        let sections = [
            ScriptSection(index: 0,
                          text: "Real patience is active the steady choice to keep doing what is right",
                          citations: []),
            ScriptSection(index: 1,
                          text: "Think of a farmer he cannot rush the harvest",
                          citations: []),
        ]
        return ScriptAlignmentEngine(sections: sections)
    }

    private func feed(_ engine: ScriptAlignmentEngine, _ sentence: String) -> Int? {
        var last: Int? = nil
        for word in sentence.split(separator: " ") {
            if let position = engine.consume(RecognizedWord(text: String(word), timestamp: 0)) {
                last = position.sectionIndex
            }
        }
        return last
    }

    @Test func tracksStraightReading() {
        let e = engine()
        let section = feed(e, "real patience is active the steady choice")
        #expect(section == 0)
        #expect(e.cursor >= 0)
    }

    @Test func advancesIntoNextSection() {
        let e = engine()
        _ = feed(e, "real patience is active the steady choice to keep doing what is right")
        let section = feed(e, "think of a farmer he cannot rush")
        #expect(section == 1)
    }

    @Test func skipsFillerAndOmissions() {
        let e = engine()
        // Speaker drops "the steady" and adds filler "um".
        let section = feed(e, "real patience is active um choice to keep")
        #expect(section == 0)
        #expect(e.cursor >= 0)
    }

    @Test func toleratesMinorMisrecognition() {
        let e = engine()
        // "patients" ~ "patience", "activ" ~ "active" (within threshold).
        let section = feed(e, "real patients is activ")
        #expect(section == 0)
    }

    @Test func holdsWhenOffScript() {
        let e = engine()
        _ = feed(e, "real patience is active")
        let before = e.cursor
        // Improvised aside, nothing matching ahead.
        let section = feed(e, "completely unrelated improvised tangent words")
        #expect(section == nil)
        #expect(e.cursor == before) // held position
    }

    @Test func resetSeatsCursorAtSection() {
        let e = engine()
        e.reset(to: 1)
        // Next forward match should be in section 1.
        let section = feed(e, "think of a farmer")
        #expect(section == 1)
    }

    @Test func singleStrayWordDoesNotJump() {
        let e = engine()
        _ = feed(e, "real patience")
        let before = e.cursor
        // "farmer" lives far ahead (section 1); one stray word must not jump.
        _ = e.consume(RecognizedWord(text: "farmer", timestamp: 0))
        #expect(e.cursor == before)
    }

    @Test func twoConsecutiveWordsConfirmAJump() {
        let e = engine()
        _ = feed(e, "real patience")
        // "farmer he" are consecutive in section 1 → confirmed jump.
        _ = e.consume(RecognizedWord(text: "farmer", timestamp: 0)) // candidate
        let position = e.consume(RecognizedWord(text: "he", timestamp: 0)) // confirm
        #expect(position?.sectionIndex == 1)
    }

    @Test func neverJumpsBackward() {
        let e = engine()
        _ = feed(e, "real patience is active the steady choice to keep doing what is right think of a farmer")
        let before = e.cursor
        _ = e.consume(RecognizedWord(text: "patience", timestamp: 0)) // earlier word
        #expect(e.cursor >= before)
    }

    @Test func shortStopwordsDoNotCauseFarJumps() {
        let e = engine()
        // "is" appears early; feeding only "is" shouldn't leap far ahead.
        _ = e.consume(RecognizedWord(text: "is", timestamp: 0))
        #expect(e.cursor <= 2)
    }
}
