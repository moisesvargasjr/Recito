//
//  VersePaneHeader.swift
//  Recito
//
//  Title row for the verse pane: the citation, an "Open in JW Library"
//  hand-off, and a prominent Done. Falls back to an icon-only hand-off and
//  then a stacked layout when Dynamic Type or a narrow pane needs the room.
//

import SwiftUI

struct VersePaneHeader: View {
    let title: String
    let canOpenInJWLibrary: Bool
    let onOpenInJWLibrary: () -> Void
    let onDone: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.md) {
                titleText
                Spacer(minLength: Spacing.sm)
                openButton(iconOnly: false)
                doneButton
            }
            HStack(spacing: Spacing.sm) {
                titleText
                Spacer(minLength: Spacing.xs)
                openButton(iconOnly: true)
                doneButton
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                titleText
                HStack(spacing: Spacing.sm) {
                    openButton(iconOnly: true)
                    Spacer(minLength: 0)
                    doneButton
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    private var titleText: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.ink)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(AXID.VersePane.title)
    }

    @ViewBuilder private func openButton(iconOnly: Bool) -> some View {
        Button(action: onOpenInJWLibrary) {
            Group {
                if iconOnly {
                    Label(VersePaneCopy.openInJWLibrary, systemImage: VersePaneCopy.openSymbol)
                        .labelStyle(.iconOnly)
                } else {
                    Label(VersePaneCopy.openInJWLibrary, systemImage: VersePaneCopy.openSymbol)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: Spacing.hitTarget, minHeight: Spacing.hitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .fixedSize()
        .disabled(!canOpenInJWLibrary)
        .accessibilityLabel(VersePaneCopy.openInJWLibrary)
        .accessibilityIdentifier(AXID.VersePane.openInJWLibrary)
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text(VersePaneCopy.done)
                .fontWeight(.semibold)
                .lineLimit(1)
                .padding(.horizontal, Spacing.sm)
                .frame(minWidth: Spacing.hitTarget, minHeight: Spacing.hitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .fixedSize()
        .keyboardShortcut(.cancelAction)
        .accessibilityIdentifier(AXID.VersePane.done)
    }
}
