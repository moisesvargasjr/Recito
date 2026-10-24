//
//  ScriptureLinkResolver.swift
//  Recito
//
//  A citation's `url` comes from the talk's Markdown, which is untrusted (it
//  can be imported). Before any URL reaches `openURL` or the verse pane it is
//  vetted here; unsafe targets fall back to the generated finder link.
//

import Foundation

enum ScriptureLinkResolver {
    private static let libraryScheme = "jwlibrary"

    /// URL to hand to the system: the author's link only when it is an https
    /// jw.org / jw-cdn.org page or a `jwlibrary:` link, else the linker's.
    static func safeURL(for citation: ScriptureCitation, linker: ScriptureLinker) -> URL? {
        if let author = citation.url, isSafeForSystem(author) { return author }
        return linker.url(for: citation)
    }

    /// URL for the in-app pane, which can only show https jw.org pages.
    static func paneURL(for citation: ScriptureCitation, linker: ScriptureLinker) -> URL? {
        if let author = citation.url, isAllowedWebPage(author) { return author }
        return linker.url(for: citation)
    }

    private static func isAllowedWebPage(_ url: URL) -> Bool {
        ScriptureWebPolicy.decision(for: url, isMainFrame: true, isUserInitiated: true) == .allow
    }

    private static func isSafeForSystem(_ url: URL) -> Bool {
        isAllowedWebPage(url) || url.scheme?.lowercased() == libraryScheme
    }
}
