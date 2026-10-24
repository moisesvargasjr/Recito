import SwiftUI
import Testing
@testable import Recito

@MainActor
struct LayoutMetricsTests {
    private let widths: [CGFloat] = [466, 669, 951, 1366]
    private let fonts: [CGFloat] = [28, 40, 64]

    @Test func columnNeverWiderThanMaxAndPaddingSymmetric() {
        for w in widths {
            for f in fonts {
                let c = LayoutMetrics.readableColumn(containerWidth: w, fontSize: f)
                #expect(c.width <= 760)
                #expect(c.width > 0)
                #expect(abs(c.sidePadding * 2 + c.width - w) < 0.001)
                #expect(c.sidePadding >= 20)
            }
        }
    }

    @Test func coverWidthUsesCompactGutter() {
        let c = LayoutMetrics.readableColumn(containerWidth: 466, fontSize: 40)
        #expect(c.sidePadding == 20)
        #expect(c.width == 426)
    }

    @Test func innerWidthCapsAtMaxColumn() {
        let c = LayoutMetrics.readableColumn(containerWidth: 951, fontSize: 40)
        #expect(c.width == 760)
        #expect(c.sidePadding == 95.5)
    }

    @Test func smallFontGivesNarrowerColumn() {
        let c = LayoutMetrics.readableColumn(containerWidth: 951, fontSize: 28)
        #expect(c.width == 560)
    }

    @Test func tinyContainerStaysNonNegative() {
        let c = LayoutMetrics.readableColumn(containerWidth: 30, fontSize: 40)
        #expect(c.width >= 0)
        #expect(c.sidePadding >= 0)
    }

    @Test func outlineGutterIsHalf() {
        let c = LayoutMetrics.outlineColumn(containerWidth: 466, fontSize: 40)
        #expect(c.sidePadding == 10)
        let wide = LayoutMetrics.outlineColumn(containerWidth: 1366, fontSize: 40)
        #expect(wide.width == 760)
    }

    @Test func libraryColumns() {
        #expect(LayoutMetrics.libraryColumnCount(width: 466, isRegular: false) == 2)
        #expect(LayoutMetrics.libraryColumnCount(width: 669, isRegular: true) == 2)
        #expect(LayoutMetrics.libraryColumnCount(width: 951, isRegular: true) == 4)
        let big = LayoutMetrics.libraryColumnCount(width: 1366, isRegular: true)
        #expect(big % 2 == 0 && big >= 4)
    }

    @Test func compactAllowsOddAndMinOne() {
        #expect(LayoutMetrics.libraryColumnCount(width: 678, isRegular: false) == 3)
        #expect(LayoutMetrics.libraryColumnCount(width: 100, isRegular: false) == 1)
        #expect(LayoutMetrics.libraryColumnCount(width: 0, isRegular: false) == 1)
    }

    @Test func regularMinTwo() {
        #expect(LayoutMetrics.libraryColumnCount(width: 300, isRegular: true) == 2)
    }

    @Test func foldGutter() {
        #expect(LayoutMetrics.foldGutter(division: nil, base: 16) == 16)
        let vertical = CGRect(x: 470, y: 0, width: 24, height: 669)
        #expect(LayoutMetrics.foldGutter(division: vertical, base: 16) == 40)
        let thin = CGRect(x: 470, y: 0, width: 2, height: 669)
        #expect(LayoutMetrics.foldGutter(division: thin, base: 32) == 32)
        let horizontal = CGRect(x: 0, y: 470, width: 669, height: 24)
        #expect(LayoutMetrics.foldGutter(division: horizontal, base: 16) == 16)
    }

    @Test func minHeights() {
        #expect(LayoutMetrics.editorMinHeight(isCompactHeight: true, kind: .edit) == 96)
        #expect(LayoutMetrics.editorMinHeight(isCompactHeight: true, kind: .importText) == 96)
        #expect(LayoutMetrics.editorMinHeight(isCompactHeight: false, kind: .edit) == 220)
        #expect(LayoutMetrics.editorMinHeight(isCompactHeight: false, kind: .importText) == 160)
        #expect(LayoutMetrics.cardMinHeight(isCompactHeight: true) == 200)
        #expect(LayoutMetrics.cardMinHeight(isCompactHeight: false) == 230)
    }

    @Test func stableInsetsTakesPerEdgeMax() {
        let prev = EdgeInsets(top: 50, leading: 0, bottom: 34, trailing: 10)
        let cur = EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0)
        let r = LayoutMetrics.stableInsets(current: cur, previous: prev, sizeChanged: false)
        #expect(r == EdgeInsets(top: 50, leading: 5, bottom: 34, trailing: 10))
    }

    @Test func stableInsetsResetsOnSizeChangeOrNoPrevious() {
        let prev = EdgeInsets(top: 50, leading: 0, bottom: 34, trailing: 10)
        let cur = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4)
        #expect(LayoutMetrics.stableInsets(current: cur, previous: prev, sizeChanged: true) == cur)
        #expect(LayoutMetrics.stableInsets(current: cur, previous: nil, sizeChanged: false) == cur)
    }
}
