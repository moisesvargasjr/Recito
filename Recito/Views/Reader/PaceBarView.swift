//
//  PaceBarView.swift
//  Recito
//
//  The 8pt time-pace bar flush at the top of each reader: a tertiary fill shows
//  how far through the script you are; a 3pt accent marker shows where you
//  should be by now. Behind = fill sits left of the marker.
//

import SwiftUI

struct PaceBarView: View {
    let pace: PaceState
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.surface3)

                Rectangle()
                    .fill(Theme.ink3)
                    .opacity(0.7)
                    .frame(width: max(0, w * pace.youFill))

                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 3)
                    .offset(x: max(0, w * pace.shouldBe - 1.5))
            }
        }
        .frame(height: height)
    }
}
