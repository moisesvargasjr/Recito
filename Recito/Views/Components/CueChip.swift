//
//  CueChip.swift
//  Recito
//
//  Glance prompt for the next scripture reference. One tap opens it (in the
//  verse pane or JW Library, per the user's setting). As the scripture
//  approaches, the chip grows an "Open" affordance so it's easy to hit.
//

import SwiftUI

struct CueChip: View {
    let citation: ScriptureCitation
    /// Shows the "Open" affordance (as we approach the scripture).
    var forceExpanded: Bool = false
    let onOpen: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: Spacing.sm) {
                Text("NEXT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.accent)
                Text(citation.displayShort)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                if forceExpanded {
                    Label("Open", systemImage: "book")
                        .labelStyle(.titleAndIcon)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.onAccent)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Theme.accent, in: Capsule())
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: Spacing.hitTarget)
            .background(Theme.accentSoft(colorScheme), in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.accent, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: forceExpanded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Next scripture, \(citation.displayShort)")
        .accessibilityHint("Opens the verse")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AXID.Reader.cueChip)
    }
}
