//
//  BalancedChipGrid.swift
//  Recito
//
//  A Layout for a handful of equal-width chips: one row when they fit, else
//  balanced rows (six pacing chips become 3 × 2 on the cover display). Each row
//  is as tall as its tallest chip, so Dynamic Type growth stays aligned.
//

import SwiftUI

struct BalancedChipGrid: Layout {
    var minItemWidth: CGFloat
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? idealWidth(for: subviews.count)
        let metrics = rowMetrics(width: width, subviews: subviews)
        let height = metrics.rowHeights.reduce(0, +) + spacing * CGFloat(max(0, metrics.rowHeights.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let metrics = rowMetrics(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for (row, height) in metrics.rowHeights.enumerated() {
            let start = row * metrics.columns
            for column in 0..<metrics.columns where start + column < subviews.count {
                let x = bounds.minX + CGFloat(column) * (metrics.itemWidth + spacing)
                subviews[start + column].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: metrics.itemWidth, height: height)
                )
            }
            y += height + spacing
        }
    }

    // MARK: - Metrics

    private struct Metrics {
        let columns: Int
        let itemWidth: CGFloat
        let rowHeights: [CGFloat]
    }

    private func idealWidth(for count: Int) -> CGFloat {
        CGFloat(count) * minItemWidth + spacing * CGFloat(max(0, count - 1))
    }

    private func rowMetrics(width: CGFloat, subviews: Subviews) -> Metrics {
        let columns = BalancedColumns.count(
            itemCount: subviews.count, availableWidth: width, minItemWidth: minItemWidth, spacing: spacing
        )
        let itemWidth = max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        let rows = LibraryGridPlan.rows(count: subviews.count, columns: columns)
        let heights = rows.map { range in
            range.map { subviews[$0].sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height }
                .max() ?? 0
        }
        return Metrics(columns: columns, itemWidth: itemWidth, rowHeights: heights)
    }
}
