//
//  AaButton.swift
//  Recito
//
//  The circular Aa control present in every screen's chrome; opens Text &
//  Display. 1.5pt accent outline, transparent fill, accent glyph.
//

import SwiftUI

struct AaButton: View {
    var size: CGFloat = Spacing.hitTarget
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "textformat")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: size, height: size)
                .background(Color.clear)
                .overlay(Circle().strokeBorder(Theme.accent, lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
