//
//  ReaderStage.swift
//  Recito
//
//  Measures the full window (ignoring the container safe area so hiding the
//  bars never resizes content), reads the fold, keeps safe-area insets stable
//  across bar hide/show, resolves the ReaderLayoutPlan and hands each region
//  to ReaderPaneLayout.
//

import SwiftUI

struct ReaderStage: View {
    @ObservedObject var vm: ReaderViewModel
    let command: ReaderCommand?
    let onOpenScripture: (ScriptureCitation) -> Void
    let onPrevious: () -> Void
    let onTogglePlay: () -> Void
    let onNext: () -> Void
    let onShowPacing: () -> Void
    /// Reports the plan kind so the container can drop the bottom-bar transport.
    let onLayoutKind: (ReaderLayoutPlan.Kind) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.uiTestDiagnostics) private var uiTestDiagnostics

    @State private var stableInsets: EdgeInsets?
    @State private var measuredSize: CGSize = .zero

    var body: some View {
        // The outer reader respects the safe area only to report its insets
        // (a reader that ignores the safe area reports zero insets); the inner
        // one measures the full window and the fold.
        GeometryReader { safe in
            GeometryReader { full in
                stage(full, safeInsets: safe.safeAreaInsets)
            }
            .ignoresSafeArea()
        }
    }

    private func stage(_ geo: GeometryProxy, safeInsets: EdgeInsets) -> some View {
        let fold = Self.foldSnapshot(geo)
        let plan = ReaderLayoutPlan.resolve(
            size: geo.size,
            isRegularWidth: horizontalSizeClass == .regular,
            divisions: fold.divisions,
            activeDivisions: fold.activeDivisions,
            paneVisible: vm.presentedCitation != nil
        )
        return ReaderPaneLayout(
            plan: plan,
            size: geo.size,
            safeInsets: stableInsets ?? safeInsets,
            onSheetDismiss: { vm.closeVerse() },
            primary: { reader(in: $0, plan: plan) },
            secondary: { versePane },
            transport: { transportPanel(in: $0) }
        )
        .onAppear { trackInsets(safeInsets, size: geo.size); onLayoutKind(plan.kind) }
        .onChange(of: safeInsets) { trackInsets($0, size: geo.size) }
        .onChange(of: geo.size) { trackInsets(safeInsets, size: $0) }
        .onChange(of: plan.kind) { onLayoutKind($0) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AXID.Reader.root)
        .accessibilityValue(uiTestDiagnostics ? diagnostics(plan.kind) : "")
    }

    // MARK: - Regions

    @ViewBuilder
    private func reader(in viewport: ReaderViewport, plan: ReaderLayoutPlan) -> some View {
        let showsPaceAndCue = plan.kind != .tabletop
        switch vm.mode {
        case .script:
            ScriptReaderView(vm: vm, viewport: viewport, command: command,
                             showsPaceAndCue: showsPaceAndCue, onOpenScripture: onOpenScripture)
        case .outline:
            OutlineReaderView(vm: vm, viewport: viewport,
                              showsPaceAndCue: showsPaceAndCue, onOpenScripture: onOpenScripture)
        }
    }

    /// The verse pane content. Swap the placeholder for the real pane here:
    /// `VersePaneView(citation: citation, url: citation.url, onDone: { vm.closeVerse() })`
    @ViewBuilder
    private var versePane: some View {
        if let citation = vm.presentedCitation {
            VersePanePlaceholder(citation: citation, onDone: { vm.closeVerse() })
        }
    }

    private func transportPanel(in viewport: ReaderViewport) -> some View {
        ReaderTransportPanel(
            vm: vm,
            insets: viewport.insets,
            onPrevious: onPrevious,
            onTogglePlay: onTogglePlay,
            onNext: onNext,
            onShowPacing: onShowPacing,
            onOpenScripture: onOpenScripture
        )
    }

    // MARK: - Geometry

    private static func foldSnapshot(_ proxy: GeometryProxy) -> FoldSnapshot {
        if #available(iOS 27.1, *) { return proxy.foldSnapshot }
        return .empty
    }

    /// Keep the per-edge maximum while the size is unchanged, so bars hiding
    /// (which shrinks the insets) never shifts the column or overlays.
    private func trackInsets(_ current: EdgeInsets, size: CGSize) {
        let sizeChanged = size != measuredSize
        measuredSize = size
        stableInsets = LayoutMetrics.stableInsets(current: current, previous: stableInsets,
                                                  sizeChanged: sizeChanged)
    }

    private func diagnostics(_ kind: ReaderLayoutPlan.Kind) -> String {
        "mode=\(vm.mode.rawValue);index=\(vm.currentIndex);of=\(vm.unitCount);layout=\(kind.rawValue)"
    }
}
