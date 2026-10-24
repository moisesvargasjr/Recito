//
//  LibraryView.swift
//  Recito
//
//  The home screen: browse / open / import saved talks. Uses the system large
//  title, search field and toolbar (which iPhone Duo places on the trailing
//  side), with the card grid in LibraryGrid.
//

import os
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var store: TalkStore
    @EnvironmentObject private var settings: DisplaySettings
    @StateObject private var model = LibraryViewModel()
    @StateObject private var vault = VaultViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.readerDependencies) private var readerDependencies
    @Environment(\.openTalkID) private var openTalkID
    @State private var showImport = false
    @State private var showSettings = false
    @State private var openedTalk: Talk?
    @State private var editingTalk: Talk?
    @State private var didHandleLaunchTarget = false

    private static let launchTargetTimeout: Duration = .seconds(5)
    private static let log = Logger(subsystem: "com.moisesvargas.Recito", category: "library")

    var body: some View {
        content
            .background(Theme.bg.ignoresSafeArea())
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AXID.Library.root)
            .navigationTitle("Recito")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $model.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search your talks"
            )
            .libraryToolbar(
                showsHidden: $model.showsHidden,
                onImport: { showImport = true },
                onTextDisplay: { showSettings = true }
            )
            .modifier(LibraryPresentations(
                vault: vault,
                showImport: $showImport,
                showSettings: $showSettings,
                openedTalk: $openedTalk,
                editingTalk: $editingTalk,
                readerDependencies: readerDependencies
            ))
            .task {
                vault.refresh(store: store, defaultTimeLimit: settings.defaultTimeLimit)
                openLaunchTargetIfNeeded()
                await abandonLaunchTargetAfterTimeout()
            }
            // Talks may load after the first look; keep trying until they do.
            .onChange(of: store.talks) { _ in openLaunchTargetIfNeeded() }
            .onChange(of: scenePhase) { phase in
                // Obsidian syncs in the background; re-read whenever we come
                // forward so an edit made elsewhere is already here.
                guard phase == .active else { return }
                vault.refresh(store: store, defaultTimeLimit: settings.defaultTimeLimit)
            }
    }

    @ViewBuilder
    private var content: some View {
        let talks = model.displayTalks(from: store.talks)
        let state = LibraryContentState.resolve(
            displayCount: talks.count, totalCount: store.talks.count, searchText: model.searchText
        )
        if state == .grid {
            LibraryGrid(
                talks: talks,
                recentID: model.recentTalkID(from: store.talks),
                actions: cardActions,
                onImport: { showImport = true }
            )
        } else {
            LibraryEmptyState(
                state: state,
                onImport: { showImport = true },
                onShowHidden: { model.showsHidden = true }
            )
        }
    }

    private var cardActions: LibraryCardActions {
        LibraryCardActions(
            open: open,
            edit: { editingTalk = $0 },
            delete: { store.delete($0) },
            setHidden: { hidden, talk in store.setHidden(hidden, for: talk.id) }
        )
    }

    private func open(_ talk: Talk) {
        store.markOpened(talk.id)
        openedTalk = talk
    }

    /// `-openTalk <uuid>`: open that talk once, exactly as tapping its card does.
    /// Handled only after a match, so talks that finish loading later still get
    /// opened (see `abandonLaunchTargetAfterTimeout`).
    private func openLaunchTargetIfNeeded() {
        guard !didHandleLaunchTarget, let openTalkID,
              let talk = OpenTalkTarget.talk(matching: openTalkID, in: store.talks) else { return }
        didHandleLaunchTarget = true
        open(talk)
    }

    /// Stop waiting for the launch target's talk after a short grace period.
    private func abandonLaunchTargetAfterTimeout() async {
        guard !didHandleLaunchTarget, let openTalkID else { return }
        try? await Task.sleep(for: Self.launchTargetTimeout)
        guard !didHandleLaunchTarget else { return }
        didHandleLaunchTarget = true
        Self.log.error("-openTalk \(openTalkID, privacy: .public) matches no talk in the library")
    }
}

/// Sheets, the vault folder picker, and the full-screen reader.
private struct LibraryPresentations: ViewModifier {
    @EnvironmentObject private var store: TalkStore
    @EnvironmentObject private var settings: DisplaySettings
    @ObservedObject var vault: VaultViewModel
    @Binding var showImport: Bool
    @Binding var showSettings: Bool
    @Binding var openedTalk: Talk?
    @Binding var editingTalk: Talk?
    let readerDependencies: ReaderDependencies

    func body(content: Content) -> some View {
        content
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
            .sheet(isPresented: $showSettings) {
                TextDisplaySheet()
            }
            .sheet(item: $editingTalk) { talk in
                EditSheet(talk: talk)
            }
            .fullScreenCover(item: $openedTalk) { talk in
                ReaderContainerView(vm: ReaderViewModel(talk: talk, deps: readerDependencies))
            }
    }
}

#Preview("Library") {
    NavigationStack { LibraryView() }
        .environmentObject(TalkStore(persistence: JSONTalkPersistence()))
        .environmentObject(DisplaySettings())
}

#Preview("Library, accessibility size") {
    NavigationStack { LibraryView() }
        .environmentObject(TalkStore(persistence: JSONTalkPersistence()))
        .environmentObject(DisplaySettings())
        .environment(\.dynamicTypeSize, .accessibility3)
}
