//
//  ReaderContainerView.swift
//  Recito
//
//  Owns the ReaderViewModel and the reader's NavigationStack: the system
//  toolbar (with auto-hide), the Text & Display and Pacing sheets, keep-awake,
//  scripture opening (in-app pane or JW Library, per the user's setting) and
//  persistence of pacing + mode changes back to the library.
//

import SwiftUI

struct ReaderContainerView: View {
    @EnvironmentObject private var store: TalkStore
    @EnvironmentObject private var settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var vm: ReaderViewModel

    @State private var sheet: ReaderSheet?
    @State private var command: ReaderCommand?
    @State private var layoutKind: ReaderLayoutPlan.Kind = .standard
    /// (section, citation) pairs already auto-opened this session.
    @State private var autoOpened: Set<ScriptureAutoOpenKey> = []

    private static let textScaleStep = 0.08

    var body: some View {
        NavigationStack {
            ReaderStage(
                vm: vm,
                command: command,
                onOpenScripture: { openScripture($0) },
                onPrevious: { transport(-1) },
                onTogglePlay: togglePlay,
                onNext: { transport(1) },
                onShowPacing: { sheet = .pacing },
                onLayoutKind: { layoutKind = $0 }
            )
            .navigationBarTitleDisplayMode(.inline)
            .readerToolbar(state: toolbarState, actions: toolbarActions)
            .readerChromeVisibility(vm.chromeVisible)
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .textDisplay: TextDisplaySheet()
            case .pacing: PacingSheet(timeLimit: $vm.timeLimit)
            }
        }
        .keepAwake(settings.keepAwake)
        .onAppear { vm.setChromeLocked(UIAccessibility.isVoiceOverRunning) }
        .onReceive(NotificationCenter.default.publisher(
            for: UIAccessibility.voiceOverStatusDidChangeNotification)
        ) { _ in vm.setChromeLocked(UIAccessibility.isVoiceOverRunning) }
        .onChange(of: vm.timeLimit) { _ in persist() }
        .onChange(of: vm.mode) { _ in persist() }
        .onChange(of: vm.isPlaying) { playing in if playing { vm.dismissResume() } }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background: vm.sceneEnteredBackground()
            case .active: vm.returnedFromExternalScripture()
            default: break
            }
        }
        .onChange(of: vm.approachingScriptureKey) { autoOpen($0) }
        // An auto-open skipped because a sheet was up gets its turn afterwards.
        .onChange(of: sheet) { if $0 == nil { autoOpen(vm.approachingScriptureKey) } }
    }

    // MARK: - Toolbar

    private var toolbarState: ReaderToolbarState {
        ReaderToolbarState(
            mode: vm.mode,
            followMode: vm.followMode,
            voiceAvailable: vm.voiceAvailable,
            isRunning: vm.isFollowRunning,
            elapsed: vm.elapsed,
            timeLimit: vm.timeLimit,
            showsTransport: layoutKind != .tabletop
        )
    }

    private var toolbarActions: ReaderToolbarActions {
        ReaderToolbarActions(
            close: { dismiss() },
            setFollowMode: { mode in withAnimation(.easeInOut(duration: 0.2)) { vm.setFollowMode(mode) } },
            switchMode: { withAnimation(.easeInOut(duration: 0.2)) { vm.switchMode() } },
            showTextSettings: { sheet = .textDisplay },
            textSmaller: { adjustTextSize(-Self.textScaleStep) },
            textLarger: { adjustTextSize(Self.textScaleStep) },
            showPacing: { sheet = .pacing },
            previous: { transport(-1) },
            togglePlay: togglePlay,
            next: { transport(1) }
        )
    }

    // MARK: - Actions

    /// Prev/Next: the script reader needs its paragraph geometry, so it gets a
    /// command; the outline steps the index directly.
    private func transport(_ delta: Int) {
        switch vm.mode {
        case .script:
            command = ReaderCommand(kind: .jump(delta))
        case .outline:
            if delta < 0 { vm.goToPrevious() } else { vm.goToNext() }
            withAnimation(.easeInOut(duration: 0.25)) { vm.wakeChrome() }
        }
    }

    /// Play/pause the active follow mode (voice needs the recognition locale).
    private func togglePlay() {
        switch vm.followMode {
        case .autoScroll:
            vm.togglePlay()
        case .voice:
            if vm.voiceFollowActive {
                vm.pauseVoice()
            } else {
                Task { await vm.startVoiceFollow(localeIdentifier: settings.recognitionLanguage) }
            }
        }
    }

    /// Every scripture open goes through the view model, which applies the
    /// hold and decides the destination; the view only performs the URL open.
    @discardableResult
    private func openScripture(_ citation: ScriptureCitation) -> ScriptureAction {
        let action = withAnimation(.easeInOut(duration: 0.25)) {
            vm.openScripture(citation, destination: settings.scriptureDestination)
        }
        guard case .external(let url) = action else { return action }
        openURL(url) { accepted in
            // The app never left, so there's no return to wait for.
            if !accepted { vm.externalScriptureNotOpened() }
        }
        return action
    }

    /// Opt-in: open each linked scripture once as the reading approaches it.
    /// The decision is `ScriptureAutoOpenPolicy`; the key is remembered (and the
    /// arrival hold skipped) only if the scripture actually opened.
    private func autoOpen(_ approaching: ScriptureAutoOpenKey?) {
        guard let key = ScriptureAutoOpenPolicy.keyToOpen(
            enabled: settings.autoOpenScripture,
            isScriptMode: vm.mode == .script,
            approaching: approaching,
            scriptureBusy: vm.presentedCitation != nil || vm.verseState.awaitingReturn,
            sheetPresented: sheet != nil,
            alreadyOpened: autoOpened
        ), let citation = vm.upcomingCitation, citation.id == key.citationID else { return }
        guard openScripture(citation) != .unavailable else { return }
        autoOpened = autoOpened.union([key])
        vm.markScriptureConsumed(at: key.sectionIndex)
    }

    private func adjustTextSize(_ delta: Double) {
        settings.textScale = min(max(settings.textScale + delta, 0), 1)
    }

    private func persist() {
        var talk = vm.talk
        talk.timeLimit = vm.timeLimit
        talk.preferredMode = vm.mode
        store.update(talk)
    }
}

/// Sheets presented over the reader.
private enum ReaderSheet: String, Identifiable {
    case textDisplay, pacing
    var id: String { rawValue }
}
