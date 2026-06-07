//
//  LibraryView.swift
//  Recito
//
//  The home screen: browse / open / import saved talks in an adaptive grid that
//  reflows for full-screen and Split View widths.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: TalkStore
    @StateObject private var model = LibraryViewModel()
    @State private var showImport = false
    @State private var showSettings = false
    @State private var openedTalk: Talk?
    @State private var editingTalk: Talk?

    private let columns = [GridItem(.adaptive(minimum: 230, maximum: 360), spacing: Spacing.xl)]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                grid
            }
        }
        .sheet(isPresented: $showImport) {
            ImportSheet { talk in openedTalk = talk }
        }
        .sheet(isPresented: $showSettings) {
            TextDisplaySheet()
        }
        .sheet(item: $editingTalk) { talk in
            EditSheet(talk: talk)
        }
        .fullScreenCover(item: $openedTalk) { talk in
            ReaderContainerView(vm: ReaderViewModel(talk: talk))
        }
    }

    private func open(_ talk: Talk) {
        store.markOpened(talk.id)
        openedTalk = talk
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.md) {
            Text("Recito")
                .font(Typography.wordmark)
                .foregroundStyle(Theme.ink)

            searchField

            AaButton(size: Spacing.hitTarget) { showSettings = true }

            Button {
                showImport = true
            } label: {
                Label("Import", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, Spacing.lg)
                    .frame(height: Spacing.hitTarget)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Radius.control))
                    .foregroundStyle(Theme.onAccent)
            }
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.sm)
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.ink2)
            TextField("Search your talks", text: $model.searchText)
                .textFieldStyle(.plain)
            if !model.searchText.isEmpty {
                Button {
                    model.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.ink3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: Spacing.hitTarget)
        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: Radius.control))
    }

    // MARK: - Grid

    private var grid: some View {
        let talks = model.displayTalks(from: store.talks)
        let recentID = model.recentTalkID(from: store.talks)
        return ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.xl) {
                ImportTileView {
                    showImport = true
                }
                ForEach(talks) { talk in
                    TalkCardView(talk: talk, isRecent: talk.id == recentID) {
                        open(talk)
                    }
                    .contextMenu {
                        Button { editingTalk = talk } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            store.delete(talk)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(TalkStore(persistence: JSONTalkPersistence()))
}
