//
//  TimePill.swift
//  Recito
//
//  Clock glyph + duration label, e.g. "🕐 30 min".
//

import SwiftUI

struct TimePill: View {
    let label: String

    var body: some View {
        Label {
            Text(label)
        } icon: {
            Image(systemName: "clock")
        }
        .font(Typography.tag)
        .foregroundStyle(Theme.ink2)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Theme.surface2, in: Capsule())
    }
}

#Preview {
    TimePill(label: "30 min").padding()
}
