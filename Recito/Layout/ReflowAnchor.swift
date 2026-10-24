//
//  ReflowAnchor.swift
//  Recito
//
//  Pure rules for carrying the playback spot across a reflow (rotation, fold,
//  text-size change). A captured anchor is applied once, on the first pass
//  where the measured frames belong to the new layout, and then dropped, so
//  later frame or height callbacks can't roll auto-scroll back.
//

import CoreGraphics

nonisolated struct ReflowAnchorStep: Equatable, Sendable {
    /// Offset to jump to, or nil to leave the position alone.
    let offset: CGFloat?
    /// The anchor still waiting for current frames (nil once applied).
    let pending: ReadingAnchor?
    /// The anchor to remember as the latest known playback spot, if it changed.
    let remembered: ReadingAnchor?
}

nonisolated enum ReflowAnchor {
    /// The anchor to hold across a reflow: one already pending, else the last
    /// remembered, else one derived from the frames of the layout being left.
    static func captured(
        pending: ReadingAnchor?,
        last: ReadingAnchor?,
        outgoing: ReadingGeometry,
        playbackOffset: CGFloat,
        readingLine: CGFloat
    ) -> ReadingAnchor? {
        pending ?? last ?? outgoing.anchor(forOffset: playbackOffset, readingLine: readingLine)
    }

    /// One attempt to apply `pending`. Waits while frames are stale; once they
    /// are current the anchor is applied and cleared in the same step.
    static func apply(
        pending: ReadingAnchor?,
        framesAreCurrent: Bool,
        geometry: ReadingGeometry,
        readingLine: CGFloat
    ) -> ReflowAnchorStep {
        guard let pending else { return ReflowAnchorStep(offset: nil, pending: nil, remembered: nil) }
        guard framesAreCurrent,
              let offset = geometry.offset(for: pending, readingLine: readingLine) else {
            return ReflowAnchorStep(offset: nil, pending: pending, remembered: nil)
        }
        return ReflowAnchorStep(offset: offset, pending: nil, remembered: pending)
    }
}
