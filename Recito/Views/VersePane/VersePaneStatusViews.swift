//
//  VersePaneStatusViews.swift
//  Recito
//
//  Loading and failure overlays for the verse pane, plus the pane's copy.
//

import SwiftUI

enum VersePaneCopy {
    static let openInJWLibrary = "Open in JW Library"
    static let openSymbol = "arrow.up.forward.app"
    static let done = "Done"
    static let retry = "Retry"
    static let failureMessage = "Couldn't load the verse. Check your connection, or open it in JW Library."

    static func loading(_ citation: String) -> String { "Loading \(citation)…" }

    /// A short extra line under the friendly message, when there is one.
    static func detail(for failure: VersePaneFailure) -> String? {
        switch failure {
        case .offline: return "You appear to be offline."
        case .http(let status): return "The page returned an error (\(status))."
        case .unavailable: return "There's no link for this reference."
        case .blocked: return "This page can't be shown in Recito."
        case .other: return nil
        }
    }
}

struct VersePaneLoadingView: View {
    let citation: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
            Text(VersePaneCopy.loading(citation))
                .font(.subheadline)
                .foregroundStyle(Theme.ink2)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AXID.VersePane.loading)
    }
}

struct VersePaneFailureView: View {
    let failure: VersePaneFailure
    let canOpenInJWLibrary: Bool
    let onRetry: () -> Void
    let onOpenInJWLibrary: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Image(systemName: failure == .offline ? "wifi.slash" : "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.ink3)
                    .accessibilityHidden(true)
                messageText
                actions
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface)
    }

    private var messageText: some View {
        VStack(spacing: Spacing.xs) {
            Text(VersePaneCopy.failureMessage)
                .font(.body)
                .foregroundStyle(Theme.ink)
            if let detail = VersePaneCopy.detail(for: failure) {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.ink2)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AXID.VersePane.error)
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.md) { retryButton; openButton }
            VStack(spacing: Spacing.sm) { retryButton; openButton }
        }
    }

    @ViewBuilder private var retryButton: some View {
        if failure.isRetryable {
            Button(action: onRetry) {
                Label(VersePaneCopy.retry, systemImage: "arrow.clockwise")
                    .frame(minHeight: Spacing.hitTarget)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(AXID.VersePane.retry)
        }
    }

    @ViewBuilder private var openButton: some View {
        if canOpenInJWLibrary {
            Button(action: onOpenInJWLibrary) {
                Label(VersePaneCopy.openInJWLibrary, systemImage: VersePaneCopy.openSymbol)
                    .frame(minHeight: Spacing.hitTarget)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier(AXID.VersePane.errorOpenInJWLibrary)
        }
    }
}
