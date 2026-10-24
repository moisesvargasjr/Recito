import SwiftUI
import Testing
@testable import Recito

@MainActor
struct LibraryGridPlanTests {
    /// A zero-width vertical hinge at `x`, spanning the full height.
    private func hinge(at x: CGFloat, width: CGFloat = 0) -> CGRect {
        CGRect(x: x - width / 2, y: 0, width: width, height: 669)
    }

    @Test func coverDisplayIsOneTwoColumnGrid() {
        let plan = LibraryGridPlan.make(containerWidth: 466, isRegular: false, divisions: [])
        #expect(plan.columns == 2)
        #expect(plan.split == nil)
        #expect(plan.diagnostics == "columns=2;gutter=12")
    }

    @Test func innerLandscapeWithoutFoldIsOneFourColumnGrid() {
        let plan = LibraryGridPlan.make(containerWidth: 951, isRegular: true, divisions: [])
        #expect(plan.columns == 4)
        #expect(plan.split == nil)
    }

    @Test func innerLandscapeWithHingeSplitsIntoTwoHalves() throws {
        let plan = LibraryGridPlan.make(containerWidth: 951, isRegular: true, divisions: [hinge(at: 475.5)])
        let split = try #require(plan.split)
        #expect(plan.columns == 4)
        #expect(split.columnsPerHalf == 2)
        #expect(split.gutter == Spacing.xxl)
        #expect(split.leadingWidth == 475.5 - Spacing.xxl / 2 - Spacing.lg)
        #expect(split.trailingWidth == 951 - Spacing.lg - (475.5 + Spacing.xxl / 2))
        #expect(plan.diagnostics == "columns=4;gutter=32")
    }

    @Test func asymmetricContainerKeepsGutterCenteredOnHinge() throws {
        // Trailing side toolbar shrinks the content area, hinge stays at screen center.
        let plan = LibraryGridPlan.make(containerWidth: 880, isRegular: true, divisions: [hinge(at: 475.5)])
        let split = try #require(plan.split)
        let gutterCenter = Spacing.lg + split.leadingWidth + split.gutter / 2
        #expect(gutterCenter == 475.5)
        #expect(split.leadingWidth > split.trailingWidth)
        #expect(Spacing.lg * 2 + split.leadingWidth + split.gutter + split.trailingWidth == 880)
    }

    @Test func wideHingeWidensGutter() throws {
        let plan = LibraryGridPlan.make(containerWidth: 951, isRegular: true, divisions: [hinge(at: 475, width: 40)])
        let split = try #require(plan.split)
        #expect(split.gutter == 40 + Spacing.lg)
    }

    @Test func horizontalDivisionDoesNotSplit() {
        let tabletop = CGRect(x: 0, y: 330, width: 951, height: 0)
        let plan = LibraryGridPlan.make(containerWidth: 951, isRegular: true, divisions: [tabletop])
        #expect(plan.split == nil)
    }

    @Test func divisionOutsideContentDoesNotSplit() {
        let plan = LibraryGridPlan.make(containerWidth: 669, isRegular: true, divisions: [hinge(at: 900)])
        #expect(plan.split == nil)
    }

    @Test func compactWidthNeverSplits() {
        let plan = LibraryGridPlan.make(containerWidth: 466, isRegular: false, divisions: [hinge(at: 233)])
        #expect(plan.split == nil)
    }

    @Test func rowsChunkRowMajor() {
        #expect(LibraryGridPlan.rows(count: 0, columns: 4).isEmpty)
        #expect(LibraryGridPlan.rows(count: 5, columns: 4) == [0..<4, 4..<5])
        #expect(LibraryGridPlan.rows(count: 8, columns: 4) == [0..<4, 4..<8])
        #expect(LibraryGridPlan.rows(count: 3, columns: 0) == [0..<1, 1..<2, 2..<3])
    }

    @Test func halvesSplitEachRowAtColumnsPerHalf() {
        let (lead, trail) = LibraryGridPlan.halves(of: 4..<7, columnsPerHalf: 2)
        #expect(lead == 4..<6)
        #expect(trail == 6..<7)
        let (shortLead, shortTrail) = LibraryGridPlan.halves(of: 8..<9, columnsPerHalf: 2)
        #expect(shortLead == 8..<9)
        #expect(shortTrail.isEmpty)
    }
}
