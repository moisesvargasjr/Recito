//
//  VersePaneView.swift
//  Recito
//
//  The in-app verse pane (DisplaySettings.scriptureDestination == .inApp):
//  a header with the citation, an "Open in JW Library" hand-off and Done,
//  over the verse's jw.org page in a locked-down, non-persistent web view.
//

import SwiftUI

struct VersePaneView: View {
    let citation: ScriptureCitation
    let url: URL?
    let onDone: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var state: VersePaneState

    init(citation: ScriptureCitation, url: URL?, onDone: @escaping () -> Void) {
        self.init(citation: citation, url: url, initialState: VersePaneState.initial(for: url), onDone: onDone)
    }

    /// Starts in a specific state (previews; tests of the layout).
    init(
        citation: ScriptureCitation,
        url: URL?,
        initialState: VersePaneState,
        onDone: @escaping () -> Void
    ) {
        self.citation = citation
        self.url = url
        self.onDone = onDone
        _state = State(initialValue: initialState)
    }

    var body: some View {
        VStack(spacing: 0) {
            VersePaneHeader(
                title: citation.displayShort,
                canOpenInJWLibrary: url != nil,
                onOpenInJWLibrary: openInJWLibrary,
                onDone: onDone
            )
            Divider()
            content
        }
        .background(Theme.surface.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AXID.VersePane.root)
        .onChange(of: url) { newURL in
            state = VersePaneState.initial(for: newURL)
        }
    }

    private var content: some View {
        ZStack {
            // The web view exists only while loading or loaded; a failure tears
            // it down, so Retry gets a fresh view (and a fresh load).
            if let url, state.failure == nil {
                ScriptureWebView(url: url, onEvent: send, openExternally: { openURL($0) })
                    .opacity(state == .loaded ? 1 : 0)
                    .accessibilityIdentifier(AXID.VersePane.web)
            }
            overlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var overlay: some View {
        switch state {
        case .loading:
            VersePaneLoadingView(citation: citation.displayShort)
        case .loaded:
            EmptyView()
        case .failed(let failure):
            VersePaneFailureView(
                failure: failure,
                canOpenInJWLibrary: url != nil,
                onRetry: { send(.retry) },
                onOpenInJWLibrary: openInJWLibrary
            )
        }
    }

    private func send(_ event: VersePaneState.Event) {
        state = VersePaneState.reduce(state, event: event)
    }

    private func openInJWLibrary() {
        guard let url else { return }
        openURL(url)
    }
}

#if DEBUG
private enum VersePanePreviewData {
    static let citation = ScriptureCitation(
        rawText: "Salmo 37:7", bookCanonical: "psalms", chapter: 37,
        verseStart: 7, verseEnd: nil, displayShort: "Ps. 37:7"
    )
    static let url = JWLibraryLinker().url(for: citation)
}

#Preview("Loaded (live jw.org)") {
    VersePaneView(citation: VersePanePreviewData.citation, url: VersePanePreviewData.url, onDone: {})
}

#Preview("Loading") {
    VersePaneView(citation: VersePanePreviewData.citation, url: nil, initialState: .loading, onDone: {})
}

#Preview("Failed: offline") {
    VersePaneView(
        citation: VersePanePreviewData.citation, url: VersePanePreviewData.url,
        initialState: .failed(.offline), onDone: {}
    )
}

#Preview("Failed: no link, dark") {
    VersePaneView(citation: VersePanePreviewData.citation, url: nil, onDone: {})
        .preferredColorScheme(.dark)
}
#endif
