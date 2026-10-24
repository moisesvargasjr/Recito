import CoreGraphics
import Testing
@testable import Recito

struct ReadingGeometryTests {
    /// 10 paragraphs of 100pt with 20pt gaps; indices 0 and 5 are headings.
    private func make(scale: CGFloat = 1, viewport: CGFloat = 600) -> ReadingGeometry {
        var frames: [Int: CGRect] = [:]
        for i in 0..<10 {
            frames[i] = CGRect(x: 0, y: CGFloat(i) * 120 * scale, width: 300, height: 100 * scale)
        }
        return ReadingGeometry(frames: frames, headingIndices: [0, 5],
                               viewportHeight: viewport, contentHeight: 1200 * scale)
    }

    @Test func maxOffset() {
        #expect(make().maxOffset == 600)
        let short = ReadingGeometry(frames: [:], headingIndices: [], viewportHeight: 600, contentHeight: 200)
        #expect(short.maxOffset == 0)
    }

    @Test func roundTripWithinOnePointForReadingLines() throws {
        let g = make()
        // Offsets whose reading line (offset + 252) lands inside a reading paragraph.
        for offset: CGFloat in [0, 10, 100, 150, 300, 330, 420, 500] {
            let line = offset + 600 * 0.42
            let a = try #require(g.anchor(forOffset: offset))
            let back = try #require(g.offset(for: a))
            let inHeading = g.headingIndices.contains(where: { g.frames[$0]!.contains(CGPoint(x: 1, y: line)) })
            let inGap = Int(line) % 120 >= 100
            if !inHeading && !inGap {
                #expect(abs(back - offset) <= 1, "offset \(offset)")
            }
        }
    }

    @Test func anchorInsideParagraph() throws {
        let g = make()
        // line = 300 + 252 = 552 -> paragraph 4 (480...580), fraction 0.72
        let a = try #require(g.anchor(forOffset: 300))
        #expect(a.sectionIndex == 4)
        #expect(abs(a.fraction - 0.72) < 0.001)
        #expect(abs(try #require(g.offset(for: a)) - 300) <= 1)
    }

    @Test func anchorPreservedWhenFramesScaled() throws {
        let g = make()
        let a = try #require(g.anchor(forOffset: 300))
        let wide = make(scale: 1.4)
        let newOffset = try #require(wide.offset(for: a))
        let again = try #require(wide.anchor(forOffset: newOffset))
        #expect(again.sectionIndex == a.sectionIndex)
        #expect(abs(again.fraction - a.fraction) < 0.01)
    }

    @Test func offsetClamps() throws {
        let g = make()
        #expect(try #require(g.offset(for: ReadingAnchor(sectionIndex: 9, fraction: 1))) == 600)
        #expect(try #require(g.offset(for: ReadingAnchor(sectionIndex: 1, fraction: 0))) == 0)
    }

    @Test func offsetForMissingSectionIsNil() {
        #expect(make().offset(for: ReadingAnchor(sectionIndex: 99, fraction: 0.5)) == nil)
    }

    @Test func anchorSkipsHeadings() throws {
        let g = make()
        // line = 360 + 252 = 612, inside heading 5 (600...700)
        let a = try #require(g.anchor(forOffset: 360))
        #expect(a.sectionIndex != 5)
        #expect((0...1).contains(a.fraction))
    }

    @Test func centerOffset() throws {
        let g = make()
        #expect(try #require(g.centerOffset(forParagraph: 3)) == 110)
        #expect(try #require(g.centerOffset(forParagraph: 0)) == 0)
        #expect(try #require(g.centerOffset(forParagraph: 9)) == 600)
        #expect(g.centerOffset(forParagraph: 42) == nil)
    }

    @Test func nearestReadingSkipsHeadings() {
        let g = make()
        #expect(g.nearestReading(toContentY: 650) == 4)
        #expect(g.nearestReading(toContentY: 0) == 1)
        #expect(g.nearestReading(toContentY: 5000) == 9)
    }

    @Test func currentIndexForPlaybackOffset() {
        // center = 100 + 300 = 400; paragraph 3 midY = 410
        #expect(make().currentIndex(forPlaybackOffset: 100) == 3)
    }

    @Test func emptyFramesAreSafe() {
        let g = ReadingGeometry(frames: [:], headingIndices: [], viewportHeight: 0, contentHeight: 0)
        #expect(g.anchor(forOffset: 10) == nil)
        #expect(g.nearestReading(toContentY: 10) == nil)
        #expect(g.currentIndex(forPlaybackOffset: 0) == nil)
        #expect(g.centerOffset(forParagraph: 0) == nil)
        #expect(g.maxOffset == 0)
    }

    @Test func zeroHeightFrameGivesZeroFraction() throws {
        let g = ReadingGeometry(frames: [0: CGRect(x: 0, y: 10, width: 1, height: 0)],
                                headingIndices: [], viewportHeight: 100, contentHeight: 500)
        let a = try #require(g.anchor(forOffset: 0))
        #expect(a.fraction == 0)
    }
}
