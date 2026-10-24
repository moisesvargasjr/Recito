//
//  ReadingGeometry.swift
//  Recito
//
//  Pure position math for the script reader (mirrors the logic previously
//  inlined in ScriptReaderView): anchors, centering, nearest-paragraph.
//

import CoreGraphics

nonisolated struct ReadingGeometry: Equatable, Sendable {
    /// Default reading line: ~42% down the viewport.
    static let defaultReadingLine: CGFloat = 0.42

    let frames: [Int: CGRect]
    let headingIndices: Set<Int>
    let viewportHeight: CGFloat
    let contentHeight: CGFloat

    var maxOffset: CGFloat { max(0, contentHeight - viewportHeight) }

    /// Reading (non-heading) paragraph frames.
    private var readingFrames: [Int: CGRect] {
        frames.filter { !headingIndices.contains($0.key) }
    }

    private func clamp(_ offset: CGFloat) -> CGFloat {
        min(max(offset, 0), maxOffset)
    }

    /// Anchor for the reading paragraph at the reading line of `offset`.
    /// A line in a heading or gap resolves to the closest reading paragraph.
    func anchor(
        forOffset offset: CGFloat,
        readingLine: CGFloat = ReadingGeometry.defaultReadingLine
    ) -> ReadingAnchor? {
        let y = offset + viewportHeight * readingLine
        let candidates = readingFrames
        guard let best = candidates.min(by: {
            (Self.distance(from: y, to: $0.value), $0.key) < (Self.distance(from: y, to: $1.value), $1.key)
        }) else { return nil }
        let frame = best.value
        let raw = frame.height > 0 ? Double((y - frame.minY) / frame.height) : 0
        return ReadingAnchor(sectionIndex: best.key, fraction: min(max(raw, 0), 1))
    }

    /// Offset placing the anchor at the reading line, clamped. Nil if the
    /// section has no measured frame.
    func offset(
        for anchor: ReadingAnchor,
        readingLine: CGFloat = ReadingGeometry.defaultReadingLine
    ) -> CGFloat? {
        guard let frame = frames[anchor.sectionIndex] else { return nil }
        let y = frame.minY + CGFloat(anchor.fraction) * frame.height
        return clamp(y - viewportHeight * readingLine)
    }

    /// Offset that centers a paragraph in the viewport.
    func centerOffset(forParagraph index: Int) -> CGFloat? {
        guard let frame = frames[index] else { return nil }
        return clamp(frame.midY - viewportHeight / 2)
    }

    /// Reading paragraph whose midpoint is closest to `y`; headings skipped.
    func nearestReading(toContentY y: CGFloat) -> Int? {
        readingFrames.min(by: {
            (abs($0.value.midY - y), $0.key) < (abs($1.value.midY - y), $1.key)
        })?.key
    }

    /// Paragraph at the playback center (offset + half viewport).
    func currentIndex(forPlaybackOffset offset: CGFloat) -> Int? {
        nearestReading(toContentY: offset + viewportHeight / 2)
    }

    private static func distance(from y: CGFloat, to frame: CGRect) -> CGFloat {
        if y < frame.minY { return frame.minY - y }
        if y > frame.maxY { return y - frame.maxY }
        return 0
    }
}
