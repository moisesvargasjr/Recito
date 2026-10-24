//
//  LibraryGrid.swift
//  Recito
//
//  The library's card grid. Column count comes from LayoutMetrics; when a
//  vertical fold crosses the content (iPhone Duo inner display, landscape) the
//  grid renders as two half-grids, row by row, with a wider gutter centered on
//  the hinge. Divisions include inactive folds, so folding never re-flows.
//

import SwiftUI

/// What the grid's card context menus can do.
struct LibraryCardActions {
    let open: (Talk) -> Void
    let edit: (Talk) -> Void
    let delete: (Talk) -> Void
    let setHidden: (Bool, Talk) -> Void
}

/// One grid cell: the leading import tile or a talk card.
enum LibraryGridItem: Identifiable {
    case importTile
    case talk(Talk)

    var id: String {
        switch self {
        case .importTile: return "importTile"
        case .talk(let talk): return talk.id.uuidString
        }
    }
}

struct LibraryGrid: View {
    let talks: [Talk]
    let recentID: Talk.ID?
    let actions: LibraryCardActions
    let onImport: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.uiTestDiagnostics) private var uiTestDiagnostics

    private static let rowSpacing: CGFloat = Spacing.lg

    var body: some View {
        GeometryReader { proxy in
            FoldReader { snapshot in
                let plan = LibraryGridPlan.make(
                    containerWidth: proxy.size.width,
                    isRegular: horizontalSizeClass == .regular,
                    divisions: snapshot.divisions
                )
                ScrollView {
                    content(plan)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(AXID.Library.grid)
                        .modifier(DiagnosticsValue(enabled: uiTestDiagnostics, value: plan.diagnostics))
                        .padding(.horizontal, LibraryGridPlan.sidePadding)
                        .padding(.top, Spacing.xs)
                        .padding(.bottom, Spacing.xxl)
                }
            }
        }
    }

    private var items: [LibraryGridItem] {
        [.importTile] + talks.map(LibraryGridItem.talk)
    }

    private var cardMinHeight: CGFloat {
        LayoutMetrics.cardMinHeight(isCompactHeight: verticalSizeClass == .compact)
    }

    @ViewBuilder
    private func content(_ plan: LibraryGridPlan) -> some View {
        if let split = plan.split {
            splitGrid(split)
        } else {
            singleGrid(columns: plan.columns)
        }
    }

    private func singleGrid(columns: Int) -> some View {
        let gridItems = Array(
            repeating: GridItem(.flexible(), spacing: LayoutMetrics.librarySpacing, alignment: .top),
            count: max(1, columns)
        )
        return LazyVGrid(columns: gridItems, spacing: Self.rowSpacing) {
            ForEach(items) { cell($0) }
        }
    }

    /// Row-major across both halves (VoiceOver reads left half then right half
    /// of each row); each row is one HStack so heights line up across the hinge.
    private func splitGrid(_ split: LibraryGridPlan.Split) -> some View {
        let all = items
        let rows = LibraryGridPlan.rows(count: all.count, columns: split.columnsPerHalf * 2)
        return LazyVStack(spacing: Self.rowSpacing) {
            ForEach(rows, id: \.lowerBound) { row in
                let halves = LibraryGridPlan.halves(of: row, columnsPerHalf: split.columnsPerHalf)
                HStack(alignment: .top, spacing: split.gutter) {
                    half(all, range: halves.leading, columns: split.columnsPerHalf)
                        .frame(width: split.leadingWidth)
                    half(all, range: halves.trailing, columns: split.columnsPerHalf)
                        .frame(width: split.trailingWidth)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func half(_ all: [LibraryGridItem], range: Range<Int>, columns: Int) -> some View {
        HStack(alignment: .top, spacing: LayoutMetrics.librarySpacing) {
            ForEach(all[range]) { cell($0) }
            ForEach(0..<max(0, columns - range.count), id: \.self) { _ in
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
            }
        }
    }

    @ViewBuilder
    private func cell(_ item: LibraryGridItem) -> some View {
        switch item {
        case .importTile:
            ImportTileView(minHeight: cardMinHeight, onTap: onImport)
        case .talk(let talk):
            TalkCardView(talk: talk, isRecent: talk.id == recentID, minHeight: cardMinHeight) {
                actions.open(talk)
            }
            .contextMenu { contextMenu(for: talk) }
        }
    }

    @ViewBuilder
    private func contextMenu(for talk: Talk) -> some View {
        if talk.source.isVault {
            Button {
                actions.setHidden(!talk.isHidden, talk)
            } label: {
                talk.isHidden
                    ? Label("Show", systemImage: "eye")
                    : Label("Hide", systemImage: "eye.slash")
            }
        } else {
            Button { actions.edit(talk) } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                actions.delete(talk)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

/// Exposes `value` as the accessibility value only under UI tests.
private struct DiagnosticsValue: ViewModifier {
    let enabled: Bool
    let value: String

    func body(content: Content) -> some View {
        if enabled {
            content.accessibilityValue(value)
        } else {
            content
        }
    }
}
