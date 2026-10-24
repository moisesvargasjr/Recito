//
//  VersePaneState.swift
//  Recito
//
//  Immutable load state for the verse pane plus a pure reducer, so every
//  transition (start, finish, fail, retry) is unit-testable without WebKit.
//

import Foundation

/// Why the verse could not be shown.
nonisolated enum VersePaneFailure: Equatable, Sendable {
    /// No network (offline, DNS failure, timeout, connection lost).
    case offline
    /// The server answered with an HTTP error status.
    case http(status: Int)
    /// There is no link for this citation (unknown book).
    case unavailable
    /// The page isn't one the pane is allowed to show (e.g. plain http).
    case blocked
    /// Any other load error.
    case other

    private static let webKitErrorDomain = "WebKitErrorDomain"
    /// WebKitErrorFrameLoadInterruptedByPolicyChange: our own policy cancelled
    /// the load (e.g. a link handed to Safari). Not a failure.
    private static let webKitPolicyInterruption = 102
    private static let offlineCodes: Set<Int> = [
        NSURLErrorNotConnectedToInternet,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorTimedOut,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorDataNotAllowed,
        NSURLErrorCallIsActive,
    ]
    private static let firstHTTPErrorStatus = 400

    /// Classifies a navigation error. Returns nil for errors that are not
    /// failures from the user's point of view (cancellations, policy hand-offs).
    static func classify(domain: String, code: Int) -> VersePaneFailure? {
        if domain == NSURLErrorDomain {
            if code == NSURLErrorCancelled { return nil }
            return offlineCodes.contains(code) ? .offline : .other
        }
        if domain == webKitErrorDomain && code == webKitPolicyInterruption { return nil }
        return .other
    }

    static func classify(_ error: Error) -> VersePaneFailure? {
        let nsError = error as NSError
        return classify(domain: nsError.domain, code: nsError.code)
    }

    /// Classifies a main-frame HTTP status; nil when the page is fine.
    static func classify(httpStatus status: Int) -> VersePaneFailure? {
        status >= firstHTTPErrorStatus ? .http(status: status) : nil
    }

    /// Retrying only makes sense when the same URL might load next time.
    var isRetryable: Bool {
        switch self {
        case .offline, .http, .other: return true
        case .unavailable, .blocked: return false
        }
    }
}

nonisolated enum VersePaneState: Equatable, Sendable {
    case loading
    case loaded
    case failed(VersePaneFailure)

    enum Event: Equatable, Sendable {
        case startedLoading
        case finishedLoading
        case failed(VersePaneFailure)
        case retry
    }

    /// Initial state for a pane about to show `url`.
    static func initial(for url: URL?) -> VersePaneState {
        guard let url else { return .failed(.unavailable) }
        switch ScriptureWebPolicy.decision(for: url, isMainFrame: true) {
        case .allow: return .loading
        case .openExternally, .cancel: return .failed(.blocked)
        }
    }

    static func reduce(_ state: VersePaneState, event: Event) -> VersePaneState {
        switch (state, event) {
        case (_, .failed(let failure)):
            return .failed(failure)
        case (.failed(let failure), .retry):
            return failure.isRetryable ? .loading : state
        case (_, .retry), (_, .startedLoading):
            return .loading
        case (.loading, .finishedLoading):
            return .loaded
        case (_, .finishedLoading):
            // A late "finished" never hides an error or re-enters loaded twice.
            return state
        }
    }

    var isLoading: Bool { self == .loading }

    var failure: VersePaneFailure? {
        if case .failed(let failure) = self { return failure }
        return nil
    }
}
