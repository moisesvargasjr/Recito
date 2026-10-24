//
//  ReaderToolbar.swift
//  Recito
//
//  The reader's system toolbar. The system decides where bars go (on iPhone
//  Duo's cover display and inner landscape it may stack them vertically on
//  the trailing side), so every item is a titled Label and carries a
//  visibility priority on iOS 27+: Play and Aa never overflow, A−/A+ and the
//  timer go first. ToolbarContentBuilder cannot branch on availability before
//  iOS 17.5, so the prioritized variant is a separate struct.
//

import SwiftUI

/// Snapshot of what the toolbar shows.
struct ReaderToolbarState: Equatable {
    let mode: DocumentMode
    let followMode: FollowMode
    let voiceAvailable: Bool
    let isRunning: Bool
    let elapsed: TimeInterval
    let timeLimit: TimeInterval
    /// False in tabletop, where the transport panel owns prev/play/next.
    let showsTransport: Bool

    var showsFollowMenu: Bool { voiceAvailable && mode == .script }
    var showsPlay: Bool { mode == .script }
    var timerTitle: String { "\(elapsed.clockString) / \(timeLimit.clockString)" }
}

/// Everything the toolbar can ask the reader to do.
struct ReaderToolbarActions {
    let close: () -> Void
    let setFollowMode: (FollowMode) -> Void
    let switchMode: () -> Void
    let showTextSettings: () -> Void
    let textSmaller: () -> Void
    let textLarger: () -> Void
    let showPacing: () -> Void
    let previous: () -> Void
    let togglePlay: () -> Void
    let next: () -> Void
}

/// The individual toolbar controls, shared by both toolbar variants.
struct ReaderToolbarItems {
    let state: ReaderToolbarState
    let actions: ReaderToolbarActions

    var close: some View {
        Button(action: actions.close) {
            Label("Close", systemImage: "chevron.backward")
        }
        .accessibilityIdentifier(AXID.Reader.close)
    }

    var followMenu: some View {
        Menu {
            followOption(.autoScroll, id: AXID.Reader.followModeAuto)
            followOption(.voice, id: AXID.Reader.followModeVoice)
        } label: {
            Label("Follow: \(state.followMode.label)", systemImage: state.followMode.symbol)
        }
        .accessibilityIdentifier(AXID.Reader.followMode)
    }

    private func followOption(_ mode: FollowMode, id: String) -> some View {
        Button { actions.setFollowMode(mode) } label: {
            Label(mode == .voice ? "Voice-follow" : "Auto-scroll",
                  systemImage: state.followMode == mode ? "checkmark" : mode.symbol)
        }
        .accessibilityIdentifier(id)
    }

    var modeToggle: some View {
        let target: DocumentMode = state.mode == .script ? .outline : .script
        return Button(action: actions.switchMode) {
            Label("Show \(target.label)", systemImage: target.symbol)
        }
        .accessibilityIdentifier(AXID.Reader.modeToggle)
    }

    var textSettings: some View {
        Button(action: actions.showTextSettings) {
            Label("Text & Display", systemImage: "textformat")
        }
        .accessibilityIdentifier(AXID.Reader.aa)
    }

    var textSmaller: some View {
        Button(action: actions.textSmaller) {
            Label("Smaller Text", systemImage: "textformat.size.smaller")
        }
        .accessibilityIdentifier(AXID.Reader.textSmaller)
    }

    var textLarger: some View {
        Button(action: actions.textLarger) {
            Label("Larger Text", systemImage: "textformat.size.larger")
        }
        .accessibilityIdentifier(AXID.Reader.textLarger)
    }

    var timer: some View {
        Button(action: actions.showPacing) {
            Label(state.timerTitle, systemImage: "timer")
        }
        .accessibilityLabel("Timer \(state.timerTitle). Set pace")
        .accessibilityIdentifier(AXID.Reader.timer)
    }

    var previous: some View { TransportButton(control: .previous, action: actions.previous) }
    var next: some View { TransportButton(control: .next, action: actions.next) }
    var play: some View {
        TransportButton(control: .playPause, isRunning: state.isRunning, action: actions.togglePlay)
    }
}

/// iOS 16–26 toolbar (no visibility priorities).
struct ReaderToolbar: ToolbarContent {
    let items: ReaderToolbarItems

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) { items.close }
        ToolbarItemGroup(placement: .primaryAction) {
            if items.state.showsFollowMenu { items.followMenu }
            items.modeToggle
            items.textSettings
        }
        ToolbarItemGroup(placement: .secondaryAction) {
            items.textSmaller
            items.textLarger
            items.timer
        }
        if items.state.showsTransport {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                items.previous
                Spacer()
                if items.state.showsPlay { items.play }
                Spacer()
                items.next
                Spacer()
            }
        }
    }
}

/// iOS 27+ toolbar: same items, one per ToolbarItem so each can carry its
/// own visibility priority.
@available(iOS 27.0, *)
struct PrioritizedReaderToolbar: ToolbarContent {
    let items: ReaderToolbarItems

    private var top: ToolbarItemVisibilityPriority { ToolbarItemVisibilityPriority(higherThan: .high) }

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) { items.close }.visibilityPriority(.high)
        if items.state.showsFollowMenu {
            ToolbarItem(placement: .primaryAction) { items.followMenu }.visibilityPriority(.automatic)
        }
        ToolbarItem(placement: .primaryAction) { items.modeToggle }.visibilityPriority(.automatic)
        ToolbarItem(placement: .primaryAction) { items.textSettings }.visibilityPriority(.high)
        ToolbarItem(placement: .secondaryAction) { items.textSmaller }.visibilityPriority(.low)
        ToolbarItem(placement: .secondaryAction) { items.textLarger }.visibilityPriority(.low)
        ToolbarItem(placement: .secondaryAction) { items.timer }.visibilityPriority(.low)
        if items.state.showsTransport {
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) { items.previous }.visibilityPriority(.high)
            if items.state.showsPlay {
                ToolbarItem(placement: .bottomBar) { items.play }.visibilityPriority(top)
            }
            ToolbarItem(placement: .bottomBar) { items.next }.visibilityPriority(.high)
            ToolbarSpacer(.flexible, placement: .bottomBar)
        }
    }
}

private struct ReaderToolbarModifier: ViewModifier {
    let items: ReaderToolbarItems

    func body(content: Content) -> some View {
        if #available(iOS 27.0, *) {
            content.toolbar { PrioritizedReaderToolbar(items: items) }
        } else {
            content.toolbar { ReaderToolbar(items: items) }
        }
    }
}

/// Shows or hides the navigation and bottom bars together.
private struct ReaderChromeVisibility: ViewModifier {
    let visible: Bool

    func body(content: Content) -> some View {
        let visibility: Visibility = visible ? .visible : .hidden
        if #available(iOS 18.0, *) {
            content.toolbarVisibility(visibility, for: .navigationBar, .bottomBar)
        } else {
            content.toolbar(visibility, for: .navigationBar, .bottomBar)
        }
    }
}

extension View {
    func readerToolbar(state: ReaderToolbarState, actions: ReaderToolbarActions) -> some View {
        modifier(ReaderToolbarModifier(items: ReaderToolbarItems(state: state, actions: actions)))
    }

    /// Auto-hide for the reader bars; the change animates with the caller's
    /// transaction (chrome toggles are wrapped in `withAnimation`).
    func readerChromeVisibility(_ visible: Bool) -> some View {
        modifier(ReaderChromeVisibility(visible: visible))
    }
}
