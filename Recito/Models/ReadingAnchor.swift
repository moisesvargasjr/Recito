//
//  ReadingAnchor.swift
//  Recito
//
//  A layout-independent reading position: a section plus how far through it
//  (0...1). Survives reflow (fold, rotate, font change) unlike point offsets.
//

import Foundation

nonisolated struct ReadingAnchor: Equatable, Sendable {
    let sectionIndex: Int
    let fraction: Double
}
