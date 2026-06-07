//
//  CueChip.swift
//  Recito
//
//  Glance prompt for the next scripture reference. Primary tap reveals an
//  "Open" affordance; the secondary tap deep-links the reference app — opt-in
//  per tap, so it never steals focus from a side-by-side reference pane.
//

import SwiftUI

struct CueChip: View {
    let citation: ScriptureCitation
    /// Forces the "Open" affordance to show (e.g. as we approach the scripture).
    var forceExpanded: Bool = false
    let onOpen: () -> Void

    @State private var manualExpanded = false
    private var expanded: Bool { forceExpanded || manualExpanded }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { manualExpanded.toggle() }
            } label: {
                HStack(spacing: 9) {
                    Text("NEXT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text(citation.displayShort)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 7)
                .background(Theme.accentSoft(.light), in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.accent, lineWidth: 1))
            }
            .buttonStyle(.plain)

            if expanded {
                Button {
                    onOpen()
                    withAnimation(.easeOut(duration: 0.2)) { manualExpanded = false }
                } label: {
                    Label("Open", systemImage: "arrow.up.forward.app")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.onAccent)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 7)
                        .background(Theme.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: expanded)
    }
}
