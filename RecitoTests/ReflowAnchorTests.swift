//
//  ReflowAnchorTests.swift
//  RecitoTests
//

import CoreGraphics
import Testing
@testable import Recito

struct ReflowAnchorTests {
    private let line: CGFloat = 0.5
    private let anchor = ReadingAnchor(sectionIndex: 3, fraction: 0.5)

    private func geometry(viewport: CGFloat = 600, withFrames: Bool = true) -> ReadingGeometry {
        var frames: [Int: CGRect] = [:]
        if withFrames {
            for i in 0..<10 { frames[i] = CGRect(x: 0, y: CGFloat(i) * 120, width: 300, height: 100) }
        }
        return ReadingGeometry(frames: frames, headingIndices: [], viewportHeight: viewport, contentHeight: 1200)
    }

    @Test func appliesOnceWhenFramesAreCurrentThenClears() throws {
        let step = ReflowAnchor.apply(pending: anchor, framesAreCurrent: true,
                                      geometry: geometry(), readingLine: line)
        let expected = try #require(geometry().offset(for: anchor, readingLine: line))
        #expect(step.offset == expected)
        #expect(step.pending == nil)
        #expect(step.remembered == anchor)
    }

    @Test func staleFramesKeepWaitingWithoutMoving() {
        let step = ReflowAnchor.apply(pending: anchor, framesAreCurrent: false,
                                      geometry: geometry(), readingLine: line)
        #expect(step.offset == nil)
        #expect(step.pending == anchor)
        #expect(step.remembered == nil)
    }

    @Test func unmeasuredSectionKeepsWaiting() {
        let step = ReflowAnchor.apply(pending: anchor, framesAreCurrent: true,
                                      geometry: geometry(withFrames: false), readingLine: line)
        #expect(step.offset == nil)
        #expect(step.pending == anchor)
    }

    @Test func nothingPendingNeverMoves() {
        let step = ReflowAnchor.apply(pending: nil, framesAreCurrent: true,
                                      geometry: geometry(), readingLine: line)
        #expect(step == ReflowAnchorStep(offset: nil, pending: nil, remembered: nil))
    }

    // MARK: Capture

    @Test func capturePrefersPendingThenLast() {
        let other = ReadingAnchor(sectionIndex: 7, fraction: 0.1)
        #expect(ReflowAnchor.captured(pending: anchor, last: other, outgoing: geometry(),
                                      playbackOffset: 0, readingLine: line) == anchor)
        #expect(ReflowAnchor.captured(pending: nil, last: other, outgoing: geometry(),
                                      playbackOffset: 0, readingLine: line) == other)
    }

    @Test func captureWithoutAnyAnchorDerivesOneFromTheOutgoingFrames() throws {
        let captured = try #require(ReflowAnchor.captured(
            pending: nil, last: nil, outgoing: geometry(), playbackOffset: 330, readingLine: line))
        #expect(captured.sectionIndex == 5) // y = 330 + 300 = 630 inside section 5 (600...700)
    }

    @Test func captureWithNoFramesYieldsNil() {
        #expect(ReflowAnchor.captured(pending: nil, last: nil, outgoing: geometry(withFrames: false),
                                      playbackOffset: 0, readingLine: line) == nil)
    }
}
