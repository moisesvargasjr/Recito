//
//  ScriptureWebPolicyTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

struct ScriptureWebPolicyTests {
    private func decide(
        _ string: String, mainFrame: Bool = true, userInitiated: Bool = true
    ) throws -> ScriptureWebPolicy.Decision {
        let url = try #require(URL(string: string), "unparseable test URL \(string)")
        return ScriptureWebPolicy.decision(for: url, isMainFrame: mainFrame, isUserInitiated: userInitiated)
    }

    // MARK: Allowed hosts

    @Test(arguments: [
        "https://www.jw.org/finder?wtlocale=S&prefer=lang&pub=nwtsty&bible=19037007",
        "https://www.jw.org/es/biblioteca/biblia/biblia-estudio/libros/salmos/37/#v19037007",
        "https://jw.org/",
        "https://wol.jw.org/es/wol/b/r4/lp-s/nwtsty/19/37",
        "https://hub.jw.org/",
        "https://b.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS",
        "https://cms-imgp.jw-cdn.org/img/p/1/2/3.jpg",
    ])
    func allowsJWHostsInEitherFrame(_ string: String) throws {
        #expect(try decide(string, mainFrame: true) == .allow)
        #expect(try decide(string, mainFrame: false) == .allow)
    }

    @Test func hostMatchingIgnoresCaseAndOneTrailingDot() throws {
        #expect(try decide("https://WWW.JW.ORG/en/") == .allow)
        #expect(try decide("HTTPS://Wol.Jw.Org/") == .allow)
        #expect(try decide("https://www.jw.org./en/") == .allow)
    }

    @Test func explicitDefaultPortIsAllowed() throws {
        #expect(try decide("https://www.jw.org:443/en/") == .allow)
    }

    // MARK: Lookalikes and spoofs

    @Test(arguments: [
        "https://jw.org.evil.com/",
        "https://www.jw.org.evil.com/finder",
        "https://evil-jw.org/",
        "https://xjw.org/",
        "https://jw.org-evil.com/",
        "https://jw.organic.com/",
        "https://jw-cdn.org.evil.com/a.js",
        "https://example.com/?u=https://www.jw.org",
        "https://example.com/#www.jw.org",
    ])
    func lookalikesOpenExternallyOnTopLevelAndAreDroppedInFrames(_ string: String) throws {
        #expect(try decide(string, mainFrame: true) == .openExternally)
        #expect(try decide(string, mainFrame: false) == .cancel)
    }

    @Test(arguments: [
        "https://jw.org@evil.com/",
        "https://www.jw.org:pass@evil.com/",
        "https://user@www.jw.org/",
        "https://user:pw@wol.jw.org/",
    ])
    func userinfoIsAlwaysCancelled(_ string: String) throws {
        #expect(try decide(string, mainFrame: true) == .cancel)
        #expect(try decide(string, mainFrame: false) == .cancel)
    }

    @Test func nonDefaultPortOnJWHostIsNotTrusted() throws {
        #expect(try decide("https://www.jw.org:8443/en/") == .openExternally)
        #expect(try decide("https://www.jw.org:8443/en/", mainFrame: false) == .cancel)
    }

    // MARK: Schemes

    @Test(arguments: [
        "http://www.jw.org/en/",
        "http://wol.jw.org/",
        "http://evil.com/",
        "HTTP://WWW.JW.ORG/",
    ])
    func plainHTTPIsCancelled(_ string: String) throws {
        #expect(try decide(string, mainFrame: true) == .cancel)
        #expect(try decide(string, mainFrame: false) == .cancel)
    }

    @Test(arguments: [
        "jwlibrary:///finder?bible=19037007",
        "mailto:someone@example.com",
        "tel:5551234",
        "sms:5551234",
        "itms-apps://apps.apple.com/app/id672417831",
    ])
    func otherAppSchemesOpenExternallyOnlyFromTheTopLevel(_ string: String) throws {
        #expect(try decide(string, mainFrame: true) == .openExternally)
        #expect(try decide(string, mainFrame: false) == .cancel)
    }

    @Test(arguments: [
        "javascript:alert(1)",
        "data:text/html,<b>hi</b>",
        "blob:https://www.jw.org/1234",
        "file:///etc/passwd",
    ])
    func dangerousSchemesAreCancelled(_ string: String) throws {
        #expect(try decide(string, mainFrame: true) == .cancel)
        #expect(try decide(string, mainFrame: false) == .cancel)
    }

    @Test func aboutBlankIsOnlyAllowedInSubframes() throws {
        #expect(try decide("about:blank", mainFrame: false) == .allow)
        #expect(try decide("about:srcdoc", mainFrame: false) == .allow)
        #expect(try decide("about:blank", mainFrame: true) == .cancel)
    }

    // MARK: Malformed

    @Test(arguments: [
        "https:///path",
        "https://",
        "https://..jw.org/",
        "https://.jw.org/",
        "https://www..jw.org/",
        "https://jw%2Eorg/",
        "https://jw.org%2eevil.com/",
        "https://www.jw.org%2eevil.com/",
        "/relative/path",
        "www.jw.org/en/",
    ])
    func malformedOrHostlessURLsAreCancelled(_ string: String) throws {
        guard let url = URL(string: string) else { return } // unparseable is equally fine
        #expect(ScriptureWebPolicy.decision(for: url, isMainFrame: true, isUserInitiated: true) == .cancel)
        #expect(ScriptureWebPolicy.decision(for: url, isMainFrame: false, isUserInitiated: true) == .cancel)
    }

    // MARK: Host helper

    @Test func isAllowedHostMatchesOnlyWholeLabels() {
        #expect(ScriptureWebPolicy.isAllowedHost("jw.org"))
        #expect(ScriptureWebPolicy.isAllowedHost("a.b.jw.org"))
        #expect(ScriptureWebPolicy.isAllowedHost("b.jw-cdn.org"))
        #expect(!ScriptureWebPolicy.isAllowedHost("org"))
        #expect(!ScriptureWebPolicy.isAllowedHost("w.org"))
        #expect(!ScriptureWebPolicy.isAllowedHost("notjw.org"))
        #expect(!ScriptureWebPolicy.isAllowedHost(""))
        #expect(!ScriptureWebPolicy.isAllowedHost("."))
        #expect(!ScriptureWebPolicy.isAllowedHost("jw.org/evil"))
        #expect(!ScriptureWebPolicy.isAllowedHost("jw.org evil"))
    }

    @Test func theGeneratedFinderLinkIsAllowed() throws {
        let citation = ScriptureCitation(
            rawText: "Salmo 37:7", bookCanonical: "psalms", chapter: 37,
            verseStart: 7, verseEnd: nil, displayShort: "Ps. 37:7"
        )
        let url = try #require(JWLibraryLinker().url(for: citation))
        #expect(ScriptureWebPolicy.decision(for: url, isMainFrame: true, isUserInitiated: true) == .allow)
    }

    // MARK: User gesture (page-initiated navigations never leave the app)

    @Test(arguments: [
        "https://evil.com/",
        "jwlibrary:///finder?bible=19037007",
        "mailto:someone@example.com",
        "tel:5551234",
    ])
    func pageInitiatedExternalNavigationIsCancelled(_ string: String) throws {
        #expect(try decide(string, mainFrame: true, userInitiated: false) == .cancel)
        #expect(try decide(string, mainFrame: true, userInitiated: true) == .openExternally)
    }

    @Test func pageInitiatedNavigationWithinJWStillLoads() throws {
        #expect(try decide("https://www.jw.org/en/", userInitiated: false) == .allow)
    }

    // MARK: Spoof backslash and host agreement

    @Test(arguments: [
        #"https://jw.org\@evil.com"#,
        #"https://jw.org\.evil.com/"#,
        "https://jw.org.evil.com@jw.org/",
    ])
    func backslashAndUserinfoSpoofsNeverAllow(_ string: String) throws {
        guard URL(string: string) != nil else { return } // unparseable is equally safe
        if try decide(string) == .allow { Issue.record("\(string) must not be allowed") }
        if try decide(string, mainFrame: false) == .allow { Issue.record("\(string) must not be allowed in frames") }
    }

    @Test(arguments: [
        "https://www.jw.org/en/", "https://jw.org%2eevil.com/", "https://evil-jw.org/",
        "https://WOL.JW.ORG./x", "https://b.jw-cdn.org/a",
    ])
    func urlHostAgreesWithPercentEncodedHostWhenAllowed(_ string: String) throws {
        let url = try #require(URL(string: string))
        guard ScriptureWebPolicy.decision(for: url, isMainFrame: true, isUserInitiated: true) == .allow else { return }
        let encoded = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedHost)
        #expect(url.host?.lowercased() == encoded.lowercased())
    }
}
