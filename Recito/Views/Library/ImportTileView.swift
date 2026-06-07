//
//  ImportTileView.swift
//  Recito
//
//  The first cell of the library grid: a dashed "Import or paste" tile.
//

import SwiftUI

struct ImportTileView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 30))
                Text("Import or paste")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Theme.ink2)
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(
                        Theme.separator,
                        style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
