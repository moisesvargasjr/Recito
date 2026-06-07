//
//  ScriptAlignmentEngine.swift
//  Recito
//
//  PHASE 2. Consumes a stream of recognized words and tracks where the speaker
//  is in the script. It tolerates imperfect transcription: it skips filler,
//  matches fuzzily, holds position when the speaker goes off-script, and only
//  moves backward on a strong backward match. Pure logic — fully unit-testable,
//  independent of which recognizer feeds it.
//

import Foundation

final class ScriptAlignmentEngine: AlignmentEngine {
    struct Token: Equatable {
        let text: String         // normalized word
        let sectionIndex: Int    // which reading section it belongs to
        let indexInSection: Int  // word position within that section
    }

    private let tokens: [Token]
    private let sectionWordCounts: [Int: Int]
    /// Index of the last confidently matched token (-1 = before the start).
    private(set) var cursor: Int = -1
    /// A match found ahead of the cursor, awaiting confirmation by the next word
    /// before we commit a forward jump (prevents stray words flinging the cursor).
    private var candidate: Int? = nil
    /// Consecutive non-advancing words — used to widen the search and re-acquire
    /// after the speaker has run well ahead of the cursor.
    private var missStreak = 0

    /// How far ahead of the cursor a jump may normally land.
    var forwardWindow = 16
    /// After this many misses, widen the search to re-acquire.
    var reacquireAfter = 4
    /// Wider window used to re-acquire when the cursor has fallen behind.
    var reacquireWindow = 90
    /// Minimum word similarity (0–1) to accept a fuzzy match.
    var matchThreshold = 0.72
    /// Words at/under this length must match exactly (avoids stopword jumps).
    private let shortWordLength = 3

    init(tokens: [Token]) {
        self.tokens = tokens
        var counts: [Int: Int] = [:]
        for token in tokens { counts[token.sectionIndex, default: 0] += 1 }
        self.sectionWordCounts = counts
    }

    /// Build from reading sections (headings are excluded — they aren't spoken).
    convenience init(sections: [ScriptSection]) {
        var toks: [Token] = []
        for section in sections where !section.isHeading {
            var wordIndex = 0
            for raw in section.text.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }) {
                let norm = ScriptAlignmentEngine.normalize(String(raw))
                if !norm.isEmpty {
                    toks.append(Token(text: norm, sectionIndex: section.index, indexInSection: wordIndex))
                    wordIndex += 1
                }
            }
        }
        self.init(tokens: toks)
    }

    // MARK: - AlignmentEngine

    /// Feed a recognized word; returns the section index if the cursor advanced
    /// (forward-only), or nil if we held position. Strategy:
    ///  1. If it's the very next expected word → advance one step (smooth).
    ///  2. If it confirms a pending candidate (candidate+1) → commit the jump.
    ///  3. Otherwise, if it matches somewhere ahead → remember as a candidate,
    ///     but don't move until a second word confirms it.
    /// This makes single stray/misheard words unable to fling the cursor, and it
    /// never jumps backward (disorienting while reading forward).
    func consume(_ word: RecognizedWord) -> AlignmentPosition? {
        let w = Self.normalize(word.text)
        guard !w.isEmpty, !tokens.isEmpty else { return nil }

        // 1. Expected next word — confident, smooth advance.
        let next = cursor + 1
        if next < tokens.count, accepts(w, tokens[next].text) {
            cursor = next
            candidate = nil
            missStreak = 0
            return position(at: cursor)
        }

        // 2. Confirm a pending forward jump.
        if let c = candidate, c + 1 < tokens.count, accepts(w, tokens[c + 1].text) {
            cursor = c + 1
            candidate = nil
            missStreak = 0
            return position(at: cursor)
        }

        // 3. New match ahead → hold it as a candidate, await confirmation. The
        // window widens once we've missed several words (speaker ran ahead).
        let window = missStreak >= reacquireAfter ? reacquireWindow : forwardWindow
        let start = cursor + 2
        let end = min(tokens.count, cursor + 1 + window)
        if start < end {
            for p in start..<end where accepts(w, tokens[p].text) {
                candidate = p
                missStreak += 1
                return nil
            }
        }

        missStreak += 1
        return nil // off-script / unconfirmed — hold.
    }

    var currentGlobalIndex: Int { cursor }

    /// The position for an arbitrary global token index, clamped in range.
    func position(forGlobalIndex index: Int) -> AlignmentPosition? {
        guard !tokens.isEmpty else { return nil }
        return position(at: min(max(index, 0), tokens.count - 1))
    }

    /// Position for a fractional index, interpolating the within-section fraction
    /// by the fractional part — for smooth (sub-word) predictive scrolling.
    func position(forFractionalGlobalIndex index: Double) -> AlignmentPosition? {
        guard !tokens.isEmpty else { return nil }
        let clamped = min(max(index, 0), Double(tokens.count - 1))
        let whole = Int(clamped.rounded(.down))
        let frac = clamped - Double(whole)
        let token = tokens[whole]
        let count = sectionWordCounts[token.sectionIndex] ?? 1
        let fraction = count > 0 ? (Double(token.indexInSection) + frac) / Double(count) : 0
        return AlignmentPosition(
            globalIndex: whole,
            sectionIndex: token.sectionIndex,
            wordIndexInSection: token.indexInSection,
            fractionInSection: min(max(fraction, 0), 1)
        )
    }

    private func position(at tokenIndex: Int) -> AlignmentPosition {
        let token = tokens[tokenIndex]
        let count = sectionWordCounts[token.sectionIndex] ?? 1
        let fraction = count > 0 ? (Double(token.indexInSection) + 0.5) / Double(count) : 0
        return AlignmentPosition(
            globalIndex: tokenIndex,
            sectionIndex: token.sectionIndex,
            wordIndexInSection: token.indexInSection,
            fractionInSection: min(max(fraction, 0), 1)
        )
    }

    /// Re-seat the cursor at the start of a section (e.g. after a manual jump).
    func reset(to index: Int) {
        candidate = nil
        missStreak = 0
        if let first = tokens.firstIndex(where: { $0.sectionIndex >= index }) {
            cursor = first - 1
        } else {
            cursor = tokens.count - 1
        }
    }

    // MARK: - Matching

    private func accepts(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        // Short words must match exactly to avoid false stopword jumps.
        if a.count <= shortWordLength || b.count <= shortWordLength { return false }
        return Self.similarity(a, b) >= matchThreshold
    }

    static func normalize(_ s: String) -> String {
        let folded = s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return String(folded.filter { $0.isLetter || $0.isNumber })
    }

    /// Normalized similarity (1 − Levenshtein/maxLen), 0…1.
    static func similarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1 }
        let maxLen = max(a.count, b.count)
        guard maxLen > 0 else { return 0 }
        return 1 - Double(levenshtein(a, b)) / Double(maxLen)
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        let s = Array(a), t = Array(b)
        if s.isEmpty { return t.count }
        if t.isEmpty { return s.count }
        var prev = Array(0...t.count)
        var curr = [Int](repeating: 0, count: t.count + 1)
        for i in 1...s.count {
            curr[0] = i
            for j in 1...t.count {
                let cost = s[i - 1] == t[j - 1] ? 0 : 1
                curr[j] = min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &curr)
        }
        return prev[t.count]
    }
}
