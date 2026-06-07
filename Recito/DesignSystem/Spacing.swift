//
//  Spacing.swift
//  Recito
//
//  8pt spacing grid, corner radii, and hit-target constants from the locked
//  design system (design_handoff_recito_mvp/README.md).
//

import CoreGraphics

/// 8pt spacing grid: 4 / 8 / 12 / 16 / 24 / 32 / 48.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    /// Minimum interactive hit target (44×44).
    static let hitTarget: CGFloat = 44
}

/// Corner radii: 13 control · 14 group/sheet · 16 sheet container · 18 card · 11 thumbnail · full pill.
enum Radius {
    static let control: CGFloat = 13
    static let group: CGFloat = 14
    static let sheet: CGFloat = 16
    static let card: CGFloat = 18
    static let thumbnail: CGFloat = 11
    static let outlineRow: CGFloat = 10
    /// Fully rounded (pills, circular controls).
    static let pill: CGFloat = 999
}
