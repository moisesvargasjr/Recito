//
//  AlignmentEngine.swift
//  Recito
//
//  PHASE-2 SEAM. Consumes recognized words and maintains a cursor over the
//  parsed script, returning a new index when the speaker advances. Phase 2 will
//  implement fuzzy forward-window matching here; Phase 1 ships the no-op so the
//  build is unaffected. When implemented, it moves the same `currentIndex` the
//  auto-scroller already drives — so the readers need no changes.
//

import Foundation

/// Where the speaker is, precise to the word, for smooth word-level following.
struct AlignmentPosition: Equatable {
    /// Global token index across the whole script (for leading ahead).
    let globalIndex: Int
    let sectionIndex: Int
    /// 0-based word index within the section.
    let wordIndexInSection: Int
    /// 0…1 progress through the section (for smooth scroll interpolation).
    let fractionInSection: Double
}

protocol AlignmentEngine {
    /// The last confidently recognized global token index (-1 before start).
    var currentGlobalIndex: Int { get }
    /// Feed a recognized word; returns the new position if the cursor advanced.
    func consume(_ word: RecognizedWord) -> AlignmentPosition?
    /// The position for an arbitrary global token index.
    func position(forGlobalIndex index: Int) -> AlignmentPosition?
    /// The position for a *fractional* global index (sub-word interpolation),
    /// for smooth predictive scrolling.
    func position(forFractionalGlobalIndex index: Double) -> AlignmentPosition?
    /// Re-seat the cursor (e.g. after a manual jump).
    func reset(to index: Int)
}

struct NoOpAlignmentEngine: AlignmentEngine {
    var currentGlobalIndex: Int { -1 }
    func consume(_ word: RecognizedWord) -> AlignmentPosition? { nil }
    func position(forGlobalIndex index: Int) -> AlignmentPosition? { nil }
    func position(forFractionalGlobalIndex index: Double) -> AlignmentPosition? { nil }
    func reset(to index: Int) {}
}
