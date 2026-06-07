//
//  ModeTag.swift
//  Recito
//
//  The reading-mode pill: "¶ Script" (gray) or "☰ Outline" (blue tint).
//

import SwiftUI

struct ModeTag: View {
    let mode: DocumentMode
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Label {
            Text(mode.label)
        } icon: {
            Image(systemName: mode.symbol)
        }
        .font(Typography.tag)
        .foregroundStyle(foreground)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(background, in: Capsule())
    }

    private var foreground: Color {
        mode == .outline ? Theme.accent : Theme.ink2
    }

    private var background: Color {
        mode == .outline ? Theme.accentSoft(scheme) : Theme.surface2
    }
}

#Preview {
    HStack { ModeTag(mode: .script); ModeTag(mode: .outline) }
        .padding()
}
