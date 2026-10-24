//
//  LayoutMetrics.swift
//  Recito
//
//  Pure, testable layout decisions (reading column, grid columns, fold
//  gutters, min heights). Replaces fixed values so the app resizes cleanly
//  across iPhone Duo's cover, inner, and folded states.
//

import SwiftUI

enum LayoutMetrics {
    // MARK: Reading column

    static let minColumn: CGFloat = 480
    static let maxColumn: CGFloat = 760
    static let columnPerPoint: CGFloat = 20
    static let narrowGutter: CGFloat = 20
    static let wideGutter: CGFloat = 32

    /// Readable column: ~20 characters-widths per point of font size, capped,
    /// and always leaving a gutter. Padding is symmetric.
    static func readableColumn(
        containerWidth: CGFloat,
        fontSize: CGFloat
    ) -> (width: CGFloat, sidePadding: CGFloat) {
        column(containerWidth: containerWidth, fontSize: fontSize, gutterScale: 1)
    }

    /// Outline reader variant: half-size gutters.
    static func outlineColumn(
        containerWidth: CGFloat,
        fontSize: CGFloat
    ) -> (width: CGFloat, sidePadding: CGFloat) {
        column(containerWidth: containerWidth, fontSize: fontSize, gutterScale: 0.5)
    }

    private static func column(
        containerWidth: CGFloat,
        fontSize: CGFloat,
        gutterScale: CGFloat
    ) -> (width: CGFloat, sidePadding: CGFloat) {
        let gutter = (containerWidth < minColumn ? narrowGutter : wideGutter) * gutterScale
        let preferred = min(max(fontSize * columnPerPoint, minColumn), maxColumn)
        let width = max(0, min(containerWidth - 2 * gutter, preferred))
        return (width, (containerWidth - width) / 2)
    }

    // MARK: Library grid

    static let libraryMinCard: CGFloat = 180
    static let librarySpacing: CGFloat = Spacing.md

    /// Adaptive card count. Side padding is Spacing.lg. Regular width rounds
    /// down to an even count (min 2) so the fold splits columns evenly.
    static func libraryColumnCount(
        width: CGFloat,
        isRegular: Bool,
        minCard: CGFloat = libraryMinCard,
        spacing: CGFloat = librarySpacing
    ) -> Int {
        let available = max(0, width - 2 * Spacing.lg)
        let fit = Int(((available + spacing) / (minCard + spacing)).rounded(.down))
        guard isRegular else { return max(1, fit) }
        return max(2, fit - fit % 2)
    }

    /// Gutter widened to clear a vertical fold.
    static func foldGutter(division: CGRect?, base: CGFloat) -> CGFloat {
        guard let division, division.height > division.width else { return base }
        return max(base, division.width + Spacing.lg)
    }

    // MARK: Heights

    enum EditorKind: Sendable { case importText, edit }

    static func editorMinHeight(isCompactHeight: Bool, kind: EditorKind) -> CGFloat {
        if isCompactHeight { return 96 }
        return kind == .edit ? 220 : 160
    }

    static func cardMinHeight(isCompactHeight: Bool) -> CGFloat {
        isCompactHeight ? 200 : 230
    }

    // MARK: Insets

    /// Per-edge max of current and previous insets so transient bar hiding
    /// doesn't reflow content; reset when the container size changes.
    static func stableInsets(
        current: EdgeInsets,
        previous: EdgeInsets?,
        sizeChanged: Bool
    ) -> EdgeInsets {
        guard let previous, !sizeChanged else { return current }
        return EdgeInsets(
            top: max(current.top, previous.top),
            leading: max(current.leading, previous.leading),
            bottom: max(current.bottom, previous.bottom),
            trailing: max(current.trailing, previous.trailing)
        )
    }
}
