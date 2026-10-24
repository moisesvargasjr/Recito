//
//  ReaderLayoutPlan.swift
//  Recito
//
//  Pure placement of the reader's regions: the reading surface, the tabletop
//  transport panel, and the in-app verse pane. Decided from the window size,
//  the width size class and the fold (division) rects, so it is unit-testable
//  and identical across folding poses.
//

import CoreGraphics
import SwiftUI

nonisolated struct ReaderLayoutPlan: Equatable, Sendable {
    /// Diagnostics label (UI tests read it as `layout=<rawValue>`).
    enum Kind: String, Sendable {
        case standard, tabletop, split
    }

    /// Smallest width/height a split half may have before we ignore the fold
    /// and split evenly instead.
    static let minimumPaneExtent: CGFloat = 200

    let kind: Kind
    /// The script/outline surface.
    let readerFrame: CGRect
    /// Tabletop only: the flat half holding the transport panel.
    let transportFrame: CGRect?
    /// The inline verse pane (nil when hidden or presented as a sheet).
    let paneFrame: CGRect?
    /// Compact width: the verse pane is presented as a sheet.
    let paneAsSheet: Bool

    static func resolve(
        size: CGSize,
        isRegularWidth: Bool,
        divisions: [CGRect],
        activeDivisions: [CGRect],
        paneVisible: Bool
    ) -> ReaderLayoutPlan {
        let full = CGRect(origin: .zero, size: size)
        if let halves = TabletopSplit.compute(size: size, activeDivisions: activeDivisions) {
            return ReaderLayoutPlan(kind: .tabletop, readerFrame: halves.top,
                                    transportFrame: halves.bottom,
                                    paneFrame: paneVisible ? halves.top : nil,
                                    paneAsSheet: false)
        }
        guard paneVisible else {
            return ReaderLayoutPlan(kind: .standard, readerFrame: full, transportFrame: nil,
                                    paneFrame: nil, paneAsSheet: false)
        }
        guard isRegularWidth else {
            return ReaderLayoutPlan(kind: .standard, readerFrame: full, transportFrame: nil,
                                    paneFrame: nil, paneAsSheet: true)
        }
        let vertical = divisions.first { $0.height > $0.width }
        let sideBySide = size.width > size.height || vertical != nil
        let parts = sideBySide
            ? splitHorizontally(size: size, fold: vertical)
            : splitVertically(size: size, fold: divisions.first { $0.width > $0.height })
        return ReaderLayoutPlan(kind: .split, readerFrame: parts.reader, transportFrame: nil,
                                paneFrame: parts.pane, paneAsSheet: false)
    }

    /// Reader leading, pane trailing; split at a vertical fold when usable.
    private static func splitHorizontally(size: CGSize, fold: CGRect?) -> (reader: CGRect, pane: CGRect) {
        let half = size.width / 2
        var start = half, end = half
        if let fold, fold.minX >= minimumPaneExtent, size.width - fold.maxX >= minimumPaneExtent {
            start = fold.minX
            end = fold.maxX
        }
        return (CGRect(x: 0, y: 0, width: start, height: size.height),
                CGRect(x: end, y: 0, width: size.width - end, height: size.height))
    }

    /// Reader on top, pane below; split at a horizontal fold when usable.
    private static func splitVertically(size: CGSize, fold: CGRect?) -> (reader: CGRect, pane: CGRect) {
        let half = size.height / 2
        var start = half, end = half
        if let fold, fold.minY >= minimumPaneExtent, size.height - fold.maxY >= minimumPaneExtent {
            start = fold.minY
            end = fold.maxY
        }
        return (CGRect(x: 0, y: 0, width: size.width, height: start),
                CGRect(x: 0, y: end, width: size.width, height: size.height - end))
    }

    /// The part of the window's safe-area insets that falls inside `rect`:
    /// an edge keeps its inset only where the region reaches into it.
    static func insets(of rect: CGRect, in size: CGSize, safe: EdgeInsets) -> EdgeInsets {
        EdgeInsets(
            top: max(0, safe.top - rect.minY),
            leading: max(0, safe.leading - rect.minX),
            bottom: max(0, rect.maxY - (size.height - safe.bottom)),
            trailing: max(0, rect.maxX - (size.width - safe.trailing))
        )
    }
}
