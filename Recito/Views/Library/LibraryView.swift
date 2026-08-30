//
//  LibraryView.swift
//  Recito
//
//  The home screen: browse / open / import saved talks in an adaptive grid that
//  reflows for full-screen and Split View widths.
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var store: TalkStore
    @EnvironmentObject private var settings: DisplaySettings
    @StateObject private var model = LibraryViewModel()
    @StateObject private var vault = VaultViewModel()
    @Environment(\.scenePhase) private var scenePhase
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
            ImportSheet(onLinkVault: { vault.pickerPresented = true }) { talk in
                openedTalk = talk
            }
        }
        .fileImporter(
            isPresented: $vault.pickerPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            vault.link(to: url, store: store, defaultTimeLimit: settings.defaultTimeLimit)
        }
        .task {
            vault.refresh(store: store, defaultTimeLimit: settings.defaultTimeLimit)
        }
        .onChange(of: scenePhase) { phase in
            // Obsidian syncs in the background; re-read whenever we come
            // forward so an edit made elsewhere is already here.
            guard phase == .active else { return }
            vault.refresh(store: store, defaultTimeLimit: settings.defaultTimeLimit)
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
                        if talk.source.isVault {
                            Button {
                                store.setHidden(!talk.isHidden, for: talk.id)
                            } label: {
                                talk.isHidden
                                    ? Label("Show", systemImage: "eye")
                                    : Label("Hide", systemImage: "eye.slash")
                            }
                        } else {
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
