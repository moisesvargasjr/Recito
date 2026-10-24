//
//  ScriptureWebPolicy.swift
//  Recito
//
//  Pure navigation policy for the in-app verse pane. The embedded web view
//  may only show jw.org pages (and load jw-cdn.org assets); anything else is
//  either handed to the system (Safari, Mail, JW Library…) or refused.
//

import Foundation

nonisolated enum ScriptureWebPolicy {
    enum Decision: Equatable, Sendable {
        /// Load it inside the verse pane.
        case allow
        /// Hand it to the system via `openURL` (Safari, Mail, JW Library…).
        case openExternally
        /// Refuse silently (for the main frame, the pane shows an error).
        case cancel
    }

    /// Registrable domains whose hosts (and subdomains) may load in the pane.
    static let allowedDomains: [String] = ["jw.org", "jw-cdn.org"]

    private static let secureScheme = "https"
    private static let insecureScheme = "http"
    private static let defaultHTTPSPort = 443
    /// Schemes that must never leave the web view nor be handed to the system.
    private static let refusedSchemes: Set<String> = ["javascript", "data", "blob", "file"]
    /// In-document placeholder frames (iframes with no source, srcdoc).
    private static let placeholderSchemes: Set<String> = ["about"]
    private static let hostCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-."
    )

    /// `isUserInitiated` is true only for a tapped link. Redirects, meta
    /// refresh, script `location=` and iframe top-navigation are page-initiated
    /// and may never hand off to another app, so `.openExternally` degrades to
    /// `.cancel` for them.
    static func decision(for url: URL, isMainFrame: Bool, isUserInitiated: Bool) -> Decision {
        let raw = rawDecision(for: url, isMainFrame: isMainFrame)
        return raw == .openExternally && !isUserInitiated ? .cancel : raw
    }

    private static func rawDecision(for url: URL, isMainFrame: Bool) -> Decision {
        guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty else { return .cancel }
        switch scheme {
        case secureScheme:
            return httpsDecision(for: url, isMainFrame: isMainFrame)
        case insecureScheme:
            return .cancel
        default:
            return otherSchemeDecision(scheme, isMainFrame: isMainFrame)
        }
    }

    /// True when `host` is one of `allowedDomains` or a subdomain of one.
    static func isAllowedHost(_ host: String) -> Bool {
        guard let normalized = normalizedHost(host) else { return false }
        return allowedDomains.contains { domain in
            normalized == domain || normalized.hasSuffix("." + domain)
        }
    }

    // MARK: - Private

    private static func httpsDecision(for url: URL, isMainFrame: Bool) -> Decision {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let rawHost = components.percentEncodedHost, normalizedHost(rawHost) != nil
        else { return .cancel }
        // Userinfo is a classic spoof ("https://jw.org@evil.com"); never follow it.
        if components.user != nil || components.password != nil { return .cancel }
        let usesDefaultPort = components.port == nil || components.port == defaultHTTPSPort
        if usesDefaultPort && isAllowedHost(rawHost) { return .allow }
        // Off-site pages go to Safari when the user navigates; off-site
        // iframes (ads, embeds) are simply not loaded.
        return isMainFrame ? .openExternally : .cancel
    }

    private static func otherSchemeDecision(_ scheme: String, isMainFrame: Bool) -> Decision {
        if refusedSchemes.contains(scheme) { return .cancel }
        if placeholderSchemes.contains(scheme) { return isMainFrame ? .cancel : .allow }
        // jwlibrary://, mailto:, tel:… only on a real top-level navigation, so
        // an embedded frame can't launch other apps on its own.
        return isMainFrame ? .openExternally : .cancel
    }

    /// Lowercased host without one trailing dot, or nil when it is malformed
    /// (empty, empty labels, or characters outside LDH — punycode is fine).
    private static func normalizedHost(_ host: String) -> String? {
        var lowered = host.lowercased()
        if lowered.hasSuffix(".") { lowered.removeLast() }
        guard !lowered.isEmpty,
              lowered.unicodeScalars.allSatisfy(hostCharacters.contains),
              !lowered.split(separator: ".", omittingEmptySubsequences: false).contains(where: \.isEmpty)
        else { return nil }
        return lowered
    }
}
