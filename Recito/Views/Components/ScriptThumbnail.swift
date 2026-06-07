//
//  ScriptThumbnail.swift
//  Recito
//
//  The page-preview box on a talk card: a small title over the first faint
//  lines of the script.
//

import SwiftUI

struct ScriptThumbnail: View {
    let title: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: Spacing.xs + 2) {
                ForEach(Array(lines.prefix(5).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.ink3)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Spacing.md)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: Radius.thumbnail))
    }
}
