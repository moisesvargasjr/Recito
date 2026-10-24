//
//  VersePaneStateTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

struct VersePaneStateTests {
    private typealias State = VersePaneState

    // MARK: Initial state

    @Test func initialStateDependsOnTheURL() throws {
        let finder = try #require(URL(string: "https://www.jw.org/finder?bible=19037007"))
        #expect(State.initial(for: finder) == .loading)
        #expect(State.initial(for: nil) == .failed(.unavailable))
        #expect(State.initial(for: URL(string: "http://www.jw.org/")) == .failed(.blocked))
        #expect(State.initial(for: URL(string: "https://example.com/")) == .failed(.blocked))
        #expect(State.initial(for: URL(string: "jwlibrary:///finder")) == .failed(.blocked))
    }

    // MARK: Reducer

    @Test func happyPathLoadsThenFinishes() {
        let started = State.reduce(.loading, event: .startedLoading)
        #expect(started == .loading)
        #expect(State.reduce(started, event: .finishedLoading) == .loaded)
    }

    @Test func aNewNavigationAfterLoadingShowsLoadingAgain() {
        #expect(State.reduce(.loaded, event: .startedLoading) == .loading)
    }

    @Test func failureWinsFromAnyState() {
        for state in [State.loading, .loaded, .failed(.other)] {
            #expect(State.reduce(state, event: .failed(.offline)) == .failed(.offline))
        }
    }

    @Test func aLateFinishNeverHidesAnError() {
        #expect(State.reduce(.failed(.http(status: 404)), event: .finishedLoading) == .failed(.http(status: 404)))
        #expect(State.reduce(.loaded, event: .finishedLoading) == .loaded)
    }

    @Test func retryReloadsRetryableFailures() {
        #expect(State.reduce(.failed(.offline), event: .retry) == .loading)
        #expect(State.reduce(.failed(.http(status: 503)), event: .retry) == .loading)
        #expect(State.reduce(.failed(.other), event: .retry) == .loading)
    }

    @Test func retryIsANoOpWhenItCannotHelp() {
        #expect(State.reduce(.failed(.unavailable), event: .retry) == .failed(.unavailable))
        #expect(State.reduce(.failed(.blocked), event: .retry) == .failed(.blocked))
    }

    @Test func helpers() {
        #expect(State.loading.isLoading)
        #expect(!State.loaded.isLoading)
        #expect(State.failed(.offline).failure == .offline)
        #expect(State.loaded.failure == nil)
    }

    // MARK: Error classification

    @Test(arguments: [
        NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost,
        NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost,
        NSURLErrorDNSLookupFailed, NSURLErrorTimedOut,
        NSURLErrorInternationalRoamingOff, NSURLErrorDataNotAllowed,
    ])
    func connectivityErrorsAreOffline(_ code: Int) {
        #expect(VersePaneFailure.classify(domain: NSURLErrorDomain, code: code) == .offline)
    }

    @Test func cancellationsAndPolicyHandOffsAreNotFailures() {
        #expect(VersePaneFailure.classify(domain: NSURLErrorDomain, code: NSURLErrorCancelled) == nil)
        #expect(VersePaneFailure.classify(domain: "WebKitErrorDomain", code: 102) == nil)
    }

    @Test func otherErrorsAreGeneric() {
        #expect(VersePaneFailure.classify(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse) == .other)
        #expect(VersePaneFailure.classify(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted) == .other)
        #expect(VersePaneFailure.classify(domain: "WebKitErrorDomain", code: 101) == .other)
        #expect(VersePaneFailure.classify(domain: "Other", code: 1) == .other)
    }

    @Test func classifiesErrorValues() {
        let offline = URLError(.notConnectedToInternet)
        #expect(VersePaneFailure.classify(offline) == .offline)
        #expect(VersePaneFailure.classify(URLError(.cancelled)) == nil)
    }

    @Test func httpStatusClassification() {
        #expect(VersePaneFailure.classify(httpStatus: 200) == nil)
        #expect(VersePaneFailure.classify(httpStatus: 302) == nil)
        #expect(VersePaneFailure.classify(httpStatus: 399) == nil)
        #expect(VersePaneFailure.classify(httpStatus: 400) == .http(status: 400))
        #expect(VersePaneFailure.classify(httpStatus: 404) == .http(status: 404))
        #expect(VersePaneFailure.classify(httpStatus: 503) == .http(status: 503))
    }

    @Test func retryability() {
        #expect(VersePaneFailure.offline.isRetryable)
        #expect(VersePaneFailure.http(status: 500).isRetryable)
        #expect(VersePaneFailure.other.isRetryable)
        #expect(!VersePaneFailure.unavailable.isRetryable)
        #expect(!VersePaneFailure.blocked.isRetryable)
    }
}
