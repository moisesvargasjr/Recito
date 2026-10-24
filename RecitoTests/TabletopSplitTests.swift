import CoreGraphics
import Testing
@testable import Recito

struct TabletopSplitTests {
    private let size = CGSize(width: 669, height: 951)

    @Test func noDivisionIsNil() {
        #expect(TabletopSplit.compute(size: size, activeDivisions: []) == nil)
    }

    @Test func verticalDivisionIsNil() {
        let d = CGRect(x: 640, y: 0, width: 20, height: 951)
        #expect(TabletopSplit.compute(size: size, activeDivisions: [d]) == nil)
    }

    @Test func horizontalDivisionTilesSize() throws {
        let d = CGRect(x: 0, y: 470, width: 669, height: 22)
        let s = try #require(TabletopSplit.compute(size: size, activeDivisions: [d]))
        #expect(s.top == CGRect(x: 0, y: 0, width: 669, height: 470))
        #expect(s.bottom == CGRect(x: 0, y: 492, width: 669, height: 459))
    }

    @Test func tooSmallHalfIsNil() {
        let nearTop = CGRect(x: 0, y: 100, width: 669, height: 20)
        #expect(TabletopSplit.compute(size: size, activeDivisions: [nearTop]) == nil)
        let nearBottom = CGRect(x: 0, y: 840, width: 669, height: 20)
        #expect(TabletopSplit.compute(size: size, activeDivisions: [nearBottom]) == nil)
    }

    @Test func exactlyMinimumHalfAccepted() {
        let d = CGRect(x: 0, y: 120, width: 669, height: 20)
        #expect(TabletopSplit.compute(size: size, activeDivisions: [d]) != nil)
    }

    @Test func firstHorizontalDivisionWins() throws {
        let v = CGRect(x: 640, y: 0, width: 20, height: 951)
        let h = CGRect(x: 0, y: 400, width: 669, height: 10)
        let s = try #require(TabletopSplit.compute(size: size, activeDivisions: [v, h]))
        #expect(s.top.height == 400)
    }
}
