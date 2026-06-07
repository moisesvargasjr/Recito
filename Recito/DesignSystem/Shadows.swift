//
//  Shadows.swift
//  Recito
//
//  Card and floating-control elevations from the design system. CSS blur radii
//  are roughly halved for SwiftUI's `shadow(radius:)`.
//

import SwiftUI

private struct CardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 8)
    }
}

private struct FloatShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 4)
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 16)
    }
}

extension View {
    /// Card / list-group elevation: `0 1px 2px rgba(0,0,0,.05), 0 8px 24px rgba(0,0,0,.06)`.
    func cardShadow() -> some View { modifier(CardShadow()) }

    /// Floating control-bar elevation: `0 4px 12px rgba(0,0,0,.10), 0 16px 40px rgba(0,0,0,.12)`.
    func floatShadow() -> some View { modifier(FloatShadow()) }
}
