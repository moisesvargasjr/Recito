//
//  ReaderPaneLayout.swift
//  Recito
//
//  Places the reading surface, the verse pane and the tabletop transport
//  panel according to a ReaderLayoutPlan:
//    • inner landscape / book fold → side by side, split at the fold
//    • inner portrait (regular, taller) → script on top, pane below
//    • tabletop → pane covers the upright half; transport panel stays below
//    • compact width (cover display, ordinary iPhones) → pane as a sheet
//  The reader is always the first child at the same position so its scroll
//  state survives every change of plan.
//
//  Known limitation: the pane is a different view in the inline regions and in
//  the compact-width sheet, so crossing between them (rotation, fold change
//  while a verse is open) rebuilds the web view and reloads the verse. Keeping
//  one web view alive across a sheet presentation isn't possible with a plain
//  `.sheet`, so the transition is made clean instead: no animation runs while
//  the pane moves into a sheet, so the sheet never presents over a layout that
//  is mid-animation.
//
//  ArrangementView(.split) (iOS 27.1) was evaluated for this: it takes only
//  primary/secondary builders and an axis set, with no way to pin the split
//  to the fold, fall back to a sheet in compact width, or keep a third
//  (transport) region, so the plan-driven frames are used instead.
//

import SwiftUI

/// A region's size and the part of the window safe area that falls in it.
struct ReaderViewport: Equatable {
    let size: CGSize
    let insets: EdgeInsets
}

struct ReaderPaneLayout<Primary: View, Secondary: View, Transport: View>: View {
    let plan: ReaderLayoutPlan
    let size: CGSize
    let safeInsets: EdgeInsets
    /// Called when the user swipes the compact-width sheet away.
    let onSheetDismiss: () -> Void
    @ViewBuilder let primary: (ReaderViewport) -> Primary
    @ViewBuilder let secondary: () -> Secondary
    @ViewBuilder let transport: (ReaderViewport) -> Transport

    /// The compact-width sheet opens tall enough to show a verse (.medium
    /// shows almost nothing on the cover display).
    private static var sheetDetent: PresentationDetent { .fraction(0.72) }
    @State private var sheetSelection: PresentationDetent = Self.sheetDetent

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.bg
            region(plan.readerFrame) { primary($0) }
                // The pane covers the reader in tabletop; keep VoiceOver from
                // reading the hidden text underneath it.
                .accessibilityHidden(coversReader)
            if let pane = plan.paneFrame {
                region(pane) { viewport in
                    secondary()
                        .padding(viewport.insets)
                        .background(Theme.surface)
                }
                .accessibilityAddTraits(coversReader ? .isModal : [])
                .transition(.opacity)
            }
            if plan.kind == .split, let pane = plan.paneFrame {
                foldSeparator(between: plan.readerFrame, and: pane)
            }
            if let panel = plan.transportFrame {
                region(panel) { transport($0) }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .animation(plan.paneAsSheet ? nil : .easeInOut(duration: 0.25), value: plan)
        .sheet(isPresented: sheetBinding) {
            secondary()
                .presentationDetents([Self.sheetDetent, .large], selection: $sheetSelection)
                .presentationDragIndicator(.visible)
                .onDisappear { sheetSelection = Self.sheetDetent }
        }
    }

    /// Tabletop with an open pane: it sits exactly over the reader.
    private var coversReader: Bool { plan.kind == .tabletop && plan.paneFrame != nil }

    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { plan.paneAsSheet },
            // Only an interactive dismissal writes false; a plan change that
            // moves the pane inline just stops presenting it.
            set: { presented in if !presented { onSheetDismiss() } }
        )
    }

    private func region<Content: View>(
        _ rect: CGRect,
        @ViewBuilder content: (ReaderViewport) -> Content
    ) -> some View {
        let viewport = ReaderViewport(
            size: rect.size,
            insets: ReaderLayoutPlan.insets(of: rect, in: size, safe: safeInsets)
        )
        return content(viewport)
            .frame(width: rect.width, height: rect.height)
            .clipped()
            .offset(x: rect.minX, y: rect.minY)
    }

    /// A hairline in the gap between reader and pane (on the hinge when the
    /// split follows the fold).
    private func foldSeparator(between reader: CGRect, and pane: CGRect) -> some View {
        let vertical = pane.minX >= reader.maxX
        let rect = vertical
            ? CGRect(x: reader.maxX, y: 0, width: max(1, pane.minX - reader.maxX), height: size.height)
            : CGRect(x: 0, y: reader.maxY, width: size.width, height: max(1, pane.minY - reader.maxY))
        return Rectangle()
            .fill(Theme.separator)
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .accessibilityHidden(true)
    }
}
