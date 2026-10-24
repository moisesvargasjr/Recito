//
//  ScriptureLinkResolverTests.swift
//  RecitoTests
//
//  Author-supplied link targets are untrusted: only https jw.org / jw-cdn.org
//  and jwlibrary: URLs may reach openURL; everything else falls back to the
//  generated finder link.
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ScriptureLinkResolverTests {
    private let base = ScriptureCitation(
        rawText: "Salmo 37:7", bookCanonical: "psalms", chapter: 37,
        verseStart: 7, verseEnd: nil, displayShort: "Ps. 37:7"
    )

    private var fallback: URL? { JWLibraryLinker().url(for: base) }

    private func citation(_ string: String?) -> ScriptureCitation {
        base.activated(url: string.flatMap { URL(string: $0) })
    }

    @Test(arguments: [
        "https://www.jw.org/es/biblioteca/biblia/",
        "https://wol.jw.org/es/wol/b/r4/lp-s/nwtsty/19/37",
        "jwlibrary:///finder?bible=19037007",
        "JWLIBRARY:///finder?bible=19037007",
    ])
    func safeAuthorLinksAreKept(_ string: String) throws {
        let expected = try #require(URL(string: string))
        #expect(ScriptureLinkResolver.safeURL(for: citation(string), linker: JWLibraryLinker()) == expected)
    }

    @Test(arguments: [
        "tel:5551234", "sms:5551234", "mailto:a@b.com", "http://www.jw.org/en/",
        "https://evil.com/", "https://jw.org.evil.com/", "https://jw.org@evil.com/",
        "javascript:alert(1)", "file:///etc/passwd", "itms-apps://apps.apple.com/app/id1",
        "otherapp://do/thing",
    ])
    func unsafeAuthorLinksFallBackToTheFinderLink(_ string: String) {
        #expect(ScriptureLinkResolver.safeURL(for: citation(string), linker: JWLibraryLinker()) == fallback)
    }

    @Test func missingAuthorLinkUsesTheLinker() {
        #expect(ScriptureLinkResolver.safeURL(for: citation(nil), linker: JWLibraryLinker()) == fallback)
        #expect(fallback != nil)
    }

    @Test func unlinkableCitationWithUnsafeURLYieldsNil() {
        let unknown = ScriptureCitation(
            rawText: "x", bookCanonical: "nonexistent", chapter: 1, verseStart: 1,
            verseEnd: nil, displayShort: "x"
        ).activated(url: URL(string: "tel:1"))
        #expect(ScriptureLinkResolver.safeURL(for: unknown, linker: JWLibraryLinker()) == nil)
    }

    // The pane can only load https jw.org pages, so a jwlibrary: author link
    // must not be handed to it.
    @Test func paneURLRejectsNonHTTPSAuthorLinks() {
        let web = "https://www.jw.org/es/x"
        #expect(ScriptureLinkResolver.paneURL(for: citation(web), linker: JWLibraryLinker()) == URL(string: web))
        #expect(ScriptureLinkResolver.paneURL(for: citation("jwlibrary:///a"), linker: JWLibraryLinker()) == fallback)
        #expect(ScriptureLinkResolver.paneURL(for: citation("tel:1"), linker: JWLibraryLinker()) == fallback)
    }
}
