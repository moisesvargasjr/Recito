//
//  BalancedColumns.swift
//  Recito
//
//  Column count for a short list of equal-width chips: everything on one row
//  when it fits, otherwise the fewest rows with the columns balanced across
//  them (6 chips that fit 5 across become 3 × 2, not 5 + 1).
//

import CoreGraphics

enum BalancedColumns {
    static func count(itemCount: Int, availableWidth: CGFloat, minItemWidth: CGFloat, spacing: CGFloat) -> Int {
        guard itemCount > 0 else { return 1 }
        guard availableWidth.isFinite, minItemWidth > 0 else { return itemCount }
        let fit = Int(((availableWidth + spacing) / (minItemWidth + spacing)).rounded(.down))
        let perRow = min(itemCount, max(1, fit))
        let rows = (itemCount + perRow - 1) / perRow
        return (itemCount + rows - 1) / rows
    }
}
