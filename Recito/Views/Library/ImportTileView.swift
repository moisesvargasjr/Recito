//
//  ImportTileView.swift
//  Recito
//
//  The first cell of the library grid: a dashed "Import or paste" tile.
//

import SwiftUI

struct ImportTileView: View {
    var minHeight: CGFloat = LayoutMetrics.cardMinHeight(isCompactHeight: false)
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "doc.badge.plus")
                    .font(.title)
                    .accessibilityHidden(true)
                Text("Import or paste")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Theme.ink2)
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(
                        Theme.separator,
                        style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Import or paste a talk")
        .accessibilityIdentifier(AXID.Library.importTile)
    }
}
