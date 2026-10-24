//
//  VersePanePlaceholder.swift
//  Recito
//
//  Stand-in for the verse pane until VersePaneView(citation:url:onDone:)
//  lands. ReaderStage.versePane is the single line to swap.
//

import SwiftUI

struct VersePanePlaceholder: View {
    let citation: ScriptureCitation
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                Text(citation.displayShort)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.md)
                Button("Done", action: onDone)
                    .font(.body.weight(.semibold))
                    .frame(minWidth: Spacing.hitTarget, minHeight: Spacing.hitTarget)
                    .accessibilityIdentifier(AXID.Reader.versePaneDone)
            }
            Text("The verse text will appear here.")
                .font(.body)
                .foregroundStyle(Theme.ink2)
            Spacer(minLength: 0)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.surface)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AXID.Reader.versePane)
    }
}
