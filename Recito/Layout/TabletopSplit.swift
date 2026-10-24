//
//  TabletopSplit.swift
//  Recito
//
//  Splits the window around a horizontal (tabletop) fold: script on the
//  upright top half, controls on the flat bottom half.
//

import CoreGraphics

nonisolated enum TabletopSplit {
    /// Minimum height each half must keep to be usable.
    static let minimumHalfHeight: CGFloat = 120

    /// Non-nil only for an active horizontal division (wider than tall) that
    /// leaves both halves at least `minimumHalfHeight` tall.
    static func compute(
        size: CGSize,
        activeDivisions: [CGRect]
    ) -> (top: CGRect, bottom: CGRect)? {
        guard let d = activeDivisions.first(where: { $0.width > $0.height }) else { return nil }
        let topHeight = d.minY
        let bottomY = d.maxY
        let bottomHeight = size.height - bottomY
        guard topHeight >= minimumHalfHeight, bottomHeight >= minimumHalfHeight else { return nil }
        return (
            top: CGRect(x: 0, y: 0, width: size.width, height: topHeight),
            bottom: CGRect(x: 0, y: bottomY, width: size.width, height: bottomHeight)
        )
    }
}
