//
//  LibraryGridPlan.swift
//  Recito
//
//  Pure decision for how the library grid is laid out: one grid, or (when a
//  vertical fold crosses the content) two half-grids split at the hinge so the
//  gutter sits on the fold even when a trailing side toolbar makes the content
//  area asymmetric. Coordinates are in the grid container's local space.
//

import CoreGraphics

struct LibraryGridPlan: Equatable, Sendable {
    struct Split: Equatable, Sendable {
        /// Content width of the half before the hinge (padding excluded).
        let leadingWidth: CGFloat
        /// Content width of the half after the hinge (padding excluded).
        let trailingWidth: CGFloat
        /// Space between the halves, centered on the hinge.
        let gutter: CGFloat
        let columnsPerHalf: Int
    }

    /// Total columns across the whole width.
    let columns: Int
    let split: Split?

    static let sidePadding: CGFloat = Spacing.lg
    /// Base hinge gutter: wider than the card spacing so the fold reads as a seam.
    static let hingeBaseGutter: CGFloat = Spacing.xxl

    var gutter: CGFloat { split?.gutter ?? LayoutMetrics.librarySpacing }

    /// UI-test diagnostics string, e.g. `columns=4;gutter=32`.
    var diagnostics: String { "columns=\(columns);gutter=\(Int(gutter.rounded()))" }

    static func make(containerWidth: CGFloat, isRegular: Bool, divisions: [CGRect]) -> LibraryGridPlan {
        let columns = LayoutMetrics.libraryColumnCount(width: containerWidth, isRegular: isRegular)
        let single = LibraryGridPlan(columns: columns, split: nil)
        guard isRegular, columns >= 2, columns.isMultiple(of: 2),
              let fold = verticalDivision(in: divisions, containerWidth: containerWidth)
        else { return single }

        let gutter = LayoutMetrics.foldGutter(division: fold, base: hingeBaseGutter)
        let leading = fold.midX - gutter / 2 - sidePadding
        let trailing = containerWidth - sidePadding - (fold.midX + gutter / 2)
        guard leading > 0, trailing > 0 else { return single }
        let split = Split(leadingWidth: leading, trailingWidth: trailing, gutter: gutter, columnsPerHalf: columns / 2)
        return LibraryGridPlan(columns: columns, split: split)
    }

    /// First vertical division (taller than wide) centered inside the padded content.
    static func verticalDivision(in divisions: [CGRect], containerWidth: CGFloat) -> CGRect? {
        divisions.first { rect in
            rect.height > rect.width
                && rect.midX > sidePadding
                && rect.midX < containerWidth - sidePadding
        }
    }

    /// Row-major index ranges of `count` items laid out `columns` wide.
    static func rows(count: Int, columns: Int) -> [Range<Int>] {
        let width = max(1, columns)
        return stride(from: 0, to: max(0, count), by: width).map { start in
            start..<min(start + width, count)
        }
    }

    /// Splits one row's range into the part before and after the hinge.
    static func halves(of row: Range<Int>, columnsPerHalf: Int) -> (leading: Range<Int>, trailing: Range<Int>) {
        let pivot = min(row.upperBound, row.lowerBound + max(0, columnsPerHalf))
        return (row.lowerBound..<pivot, pivot..<row.upperBound)
    }
}
