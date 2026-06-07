//
//  OutlineReaderView.swift
//  Recito
//
//  Outline teleprompter: numbered points + sub-bullets, the current point
//  enlarged with an accent-soft background. A left margin rail shows which point
//  you're on (distinct from the time pace bar). Advance with Prev/Next or by
//  tapping a point.
//

import SwiftUI
import UIKit

struct OutlineReaderView: View {
    @EnvironmentObject private var settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ReaderViewModel

    @State private var showSettings = false
    @State private var showPacing = false

    private let linker: ScriptureLinker = JWLibraryLinker()

    private var mainSize: CGFloat { settings.readingFontSize * 0.78 }
    private var subSize: CGFloat { settings.readingFontSize * 0.62 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.bg.ignoresSafeArea()

                HStack(alignment: .top, spacing: 0) {
                    marginRail
                    outlineList(width: geo.size.width)
                }

                VStack(spacing: 0) {
                    PaceBarView(pace: vm.pace)
                    Spacer(minLength: 0)
                }

                ReaderChrome(
                    vm: vm,
                    labeledPrevNext: true,
                    title: vm.talk.title,
                    onClose: { dismiss() },
                    onAa: { showSettings = true },
                    onPrev: { advance(by: -1) },
                    onNext: { advance(by: 1) },
                    onSizeDown: { adjustTextSize(-0.08) },
                    onSizeUp: { adjustTextSize(0.08) },
                    onPaceTap: { showPacing = true },
                    topTrailing: cueChip
                )
            }
            .contentShape(Rectangle())
            .onTapGesture { vm.toggleChrome() }
        }
        .keepAwake(settings.keepAwake)
        .sheet(isPresented: $showSettings) { TextDisplaySheet() }
        .sheet(isPresented: $showPacing) { PacingSheet(timeLimit: $vm.timeLimit) }
        .onAppear { vm.startClock() }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - List

    private func outlineList(width: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Color.clear.frame(height: Spacing.xxxl + Spacing.xl) // top room for chrome title
                    ForEach(vm.outlineNodes) { node in
                        outlineRow(node).id(node.index)
                    }
                    Color.clear.frame(height: 120) // bottom room for control cluster
                }
                .padding(.horizontal, ScriptReaderView.sidePadding(for: width) * 0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: vm.currentIndex) { index in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
        }
    }

    private func outlineRow(_ node: OutlineNode) -> some View {
        let isCurrent = node.index == vm.currentIndex
        let size = node.level == 0 ? mainSize : subSize

        return HStack(alignment: .firstTextBaseline, spacing: Spacing.lg) {
            Text(node.number ?? "—")
                .font(.system(size: size, weight: node.level == 0 ? .bold : .regular))
                .foregroundStyle(Theme.accent)
                .frame(minWidth: 24, alignment: node.level == 0 ? .leading : .trailing)

            Text(node.text)
                .font(Typography.reading(size: size,
                                         serif: settings.typeface.isSerif,
                                         bold: node.level == 0 ? (isCurrent || settings.boldText) : settings.boldText))
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
                .fill(isCurrent ? Theme.accentSoft(.light) : .clear)
        )
        .overlay(alignment: .leading) {
            if isCurrent {
                RoundedRectangle(cornerRadius: 2).fill(Theme.accent).frame(width: 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { vm.currentIndex = node.index }
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
        .frame(width: 58)
        .padding(.vertical, Spacing.xxxl)
    }

    // MARK: - Actions

    private func advance(by delta: Int) {
        let target = vm.currentIndex + delta
        guard target >= 0, target < vm.outlineNodes.count else { return }
        vm.currentIndex = target
        vm.wakeChrome()
    }

    private func adjustTextSize(_ delta: Double) {
        settings.textScale = min(max(settings.textScale + delta, 0), 1)
    }

    private var cueChip: AnyView? {
        guard let citation = vm.upcomingCitation else { return nil }
        return AnyView(
            CueChip(citation: citation, forceExpanded: vm.cueShouldExpand) {
                if let url = citation.url ?? linker.url(for: citation) {
                    UIApplication.shared.open(url)
                }
            }
        )
    }
}
