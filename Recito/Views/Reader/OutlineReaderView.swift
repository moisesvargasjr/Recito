//
//  OutlineReaderView.swift
//  Recito
//
//  Outline teleprompter: numbered points + sub-bullets, the current point
//  enlarged with an accent-soft background. A left margin rail shows which
//  point you're on (distinct from the time pace bar). Advance with Prev/Next
//  or by tapping a point. After a resize, fold or text-size change the list
//  re-centers the current point.
//

import SwiftUI

struct OutlineReaderView: View {
    @EnvironmentObject private var settings: DisplaySettings
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var vm: ReaderViewModel
    let viewport: ReaderViewport
    let showsPaceAndCue: Bool
    let onOpenScripture: (ScriptureCitation) -> Void

    private static let railWidth: CGFloat = 58
    private static let topID = "outline.top"

    private var mainSize: CGFloat { settings.readingFontSize * 0.78 }
    private var subSize: CGFloat { settings.readingFontSize * 0.62 }

    var body: some View {
        ZStack {
            Theme.bg
            HStack(alignment: .top, spacing: 0) {
                marginRail
                outlineList
            }
            .padding(.leading, viewport.insets.leading)
            .padding(.trailing, viewport.insets.trailing)
            ReaderOverlays(vm: vm, insets: viewport.insets,
                           showsPaceAndCue: showsPaceAndCue,
                           onOpenScripture: onOpenScripture)
        }
        .frame(width: viewport.size.width, height: viewport.size.height)
        .onAppear { vm.startClock() }
    }

    // MARK: - List

    private var outlineList: some View {
        let available = max(0, viewport.size.width - viewport.insets.leading
                            - viewport.insets.trailing - Self.railWidth)
        let column = LayoutMetrics.outlineColumn(containerWidth: available, fontSize: mainSize)
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Color.clear.frame(height: viewport.insets.top + Spacing.xl).id(Self.topID)
                    ForEach(vm.outlineNodes) { node in
                        outlineRow(node).id(node.index)
                    }
                    // Room for the cue chip / resume pill above the bottom bar.
                    Color.clear.frame(height: viewport.insets.bottom + Spacing.xxxl + Spacing.xxl)
                }
                .padding(.horizontal, column.sidePadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Taps between rows toggle the bars; rows handle their own taps.
                .background(Color.clear.contentShape(Rectangle()).onTapGesture { toggleChrome() })
            }
            .onAppear { settle(proxy) }
            .onChange(of: vm.currentIndex) { index in
                withAnimation(.easeInOut(duration: 0.3)) { reveal(index, proxy) }
            }
            .onChange(of: reflowKey) { _ in
                // Re-center after the new layout pass (fold/rotate/text size).
                settle(proxy)
            }
        }
    }

    /// Brings the current point into place once the layout pass has run.
    /// Scrolling before it (or centering the first point, which has nothing
    /// above it to center against) overshoots and hides the first rows.
    private func settle(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async { reveal(vm.currentIndex, proxy) }
    }

    /// The first point sits at the top of the list; later ones are centered.
    private func reveal(_ index: Int, _ proxy: ScrollViewProxy) {
        if index <= 0 {
            proxy.scrollTo(Self.topID, anchor: .top)
        } else {
            proxy.scrollTo(index, anchor: .center)
        }
    }

    private var reflowKey: [CGFloat] {
        [viewport.size.width, viewport.size.height, settings.readingFontSize]
    }

    private func outlineRow(_ node: OutlineNode) -> some View {
        let isCurrent = node.index == vm.currentIndex
        let size = node.level == 0 ? mainSize : subSize
        let bold = node.level == 0 ? (isCurrent || settings.boldText) : settings.boldText

        return HStack(alignment: .firstTextBaseline, spacing: Spacing.lg) {
            Text(node.number ?? "—")
                .font(.system(size: size, weight: node.level == 0 ? .bold : .regular))
                .foregroundStyle(Theme.accent)
                .frame(minWidth: 24, alignment: node.level == 0 ? .leading : .trailing)

            Text(node.text)
                .font(Typography.reading(size: size, serif: settings.typeface.isSerif, bold: bold))
                .foregroundStyle(node.level == 0 ? Theme.ink : Theme.ink2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.leading, node.level == 1 ? 54 : 0)
        .padding(.vertical, isCurrent ? Spacing.md : 0)
        .padding(.horizontal, isCurrent ? Spacing.lg : 0)
        .background(
            RoundedRectangle(cornerRadius: Radius.outlineRow)
                .fill(isCurrent ? Theme.accentSoft(colorScheme) : .clear)
        )
        .overlay(alignment: .leading) {
            if isCurrent {
                RoundedRectangle(cornerRadius: 2).fill(Theme.accent).frame(width: 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { vm.currentIndex = node.index }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(AXID.Reader.outlineRow(node.index))
    }

    // MARK: - Margin rail (which point you're on)

    private var marginRail: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let progress = CGFloat(vm.pointProgress)
            ZStack(alignment: .top) {
                Capsule().fill(Theme.surface3).frame(width: 4, height: h)
                Capsule().fill(Theme.accent).frame(width: 4, height: max(0, h * progress))
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 16, height: 16)
                    .offset(y: max(0, h * progress - 8))
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: Self.railWidth)
        .padding(.top, viewport.insets.top + Spacing.xxxl)
        .padding(.bottom, viewport.insets.bottom + Spacing.xxxl)
        .accessibilityHidden(true)
    }

    private func toggleChrome() {
        withAnimation(.easeInOut(duration: 0.25)) { vm.toggleChrome() }
    }
}
