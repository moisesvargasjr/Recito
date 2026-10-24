//
//  LibraryToolbar.swift
//  Recito
//
//  Library toolbar: Import (prominent, high priority), Text & Display, and a
//  "Show Hidden" toggle in the overflow. iOS 27 adds `.visibilityPriority` so
//  Import is the last item the system collapses (iPhone Duo side toolbar).
//  ToolbarContentBuilder can't branch on #available below iOS 17.5, so the
//  modifier picks one of two toolbar structs instead.
//

import SwiftUI

struct LibraryToolbarModifier: ViewModifier {
    @Binding var showsHidden: Bool
    let onImport: () -> Void
    let onTextDisplay: () -> Void

    func body(content: Content) -> some View {
        let buttons = LibraryToolbarButtons(showsHidden: $showsHidden, onImport: onImport, onTextDisplay: onTextDisplay)
        if #available(iOS 27.0, *) {
            content.toolbar { PrioritizedLibraryToolbar(buttons: buttons) }
        } else {
            content.toolbar { LegacyLibraryToolbar(buttons: buttons) }
        }
    }
}

extension View {
    func libraryToolbar(
        showsHidden: Binding<Bool>,
        onImport: @escaping () -> Void,
        onTextDisplay: @escaping () -> Void
    ) -> some View {
        modifier(LibraryToolbarModifier(showsHidden: showsHidden, onImport: onImport, onTextDisplay: onTextDisplay))
    }
}

/// The individual controls, shared by both toolbar variants.
struct LibraryToolbarButtons {
    @Binding var showsHidden: Bool
    let onImport: () -> Void
    let onTextDisplay: () -> Void

    var importButton: some View {
        Button(action: onImport) {
            Label("Import", systemImage: "plus")
        }
        .modifier(ProminentToolbarButton())
        .accessibilityHint("Paste a script or import a file")
        .accessibilityIdentifier(AXID.Library.importButton)
    }

    var textDisplayButton: some View {
        Button(action: onTextDisplay) {
            Label("Text & Display", systemImage: "textformat.size")
        }
        .accessibilityIdentifier(AXID.Library.settingsButton)
    }

    var showHiddenToggle: some View {
        Toggle(isOn: $showsHidden) {
            Label("Show Hidden", systemImage: "eye")
        }
        .accessibilityIdentifier(AXID.Library.showHiddenToggle)
    }
}

@available(iOS 27.0, *)
private struct PrioritizedLibraryToolbar: ToolbarContent {
    let buttons: LibraryToolbarButtons

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            buttons.importButton
        }
        .visibilityPriority(.high)
        ToolbarItemGroup(placement: .primaryAction) {
            buttons.textDisplayButton
        }
        ToolbarItemGroup(placement: .secondaryAction) {
            buttons.showHiddenToggle
        }
        .visibilityPriority(.low)
    }
}

/// Before iOS 27: an explicit "More" menu holds the toggle, since iOS 16's
/// iPhone navigation bar has no reliable automatic overflow.
private struct LegacyLibraryToolbar: ToolbarContent {
    let buttons: LibraryToolbarButtons

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            buttons.importButton
            buttons.textDisplayButton
            Menu {
                buttons.showHiddenToggle
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
            .accessibilityIdentifier(AXID.Library.overflowMenu)
        }
    }
}

/// Tinted/prominent glass on iOS 26+; plain toolbar button before.
private struct ProminentToolbarButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.borderedProminent)
        } else {
            content.fontWeight(.semibold)
        }
    }
}
