//
//  ScriptureContentRules.swift
//  Recito
//
//  Defense in depth under ScriptureWebPolicy: a WKContentRuleList that blocks
//  every load (subresources, XHR, frames) except hosts the pane may show. The
//  navigation policy still decides top-level and frame navigations; this stops
//  a jw.org page from pulling in third-party trackers or scripts.
//
//  Allow-listed beyond jw.org / jw-cdn.org, because the verse page embeds them
//  itself (found by fetching the page): www.gstatic.com (Chromecast sender
//  script) and *.awswaf.com (bot-challenge script and its token requests).
//  Both are limited to the resource types below, never documents or frames.
//

import Foundation
import OSLog
import WebKit

nonisolated enum ScriptureContentRules {
    static let identifier = "recito.scripture.host-allow-list.v1"

    private static let scriptTypes = ["script"]
    private static let scriptAndFetchTypes = ["script", "raw"]
    private static let gstaticHost = "www.gstatic.com"
    private static let wafDomain = "awswaf.com"

    private static let log = Logger(subsystem: "com.moisesvargas.Recito", category: "versePane")

    /// Rule dictionaries in WebKit content-blocker format. Later rules win, so
    /// the block-all rule goes first and the allows follow.
    static func rules() -> [[String: Any]] {
        var result: [[String: Any]] = [rule(filter: ".*", action: "block")]
        for domain in ScriptureWebPolicy.allowedDomains {
            result.append(allow(hostFilter(exact: domain)))
            result.append(allow(hostFilter(subdomainsOf: domain)))
        }
        result.append(allow(hostFilter(exact: gstaticHost), types: scriptTypes))
        result.append(allow(hostFilter(subdomainsOf: wafDomain), types: scriptAndFetchTypes))
        return result
    }

    static func rulesJSON() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: rules(), options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }

    /// Compiles (or fetches the cached) list. Throws if WebKit rejects the JSON.
    @MainActor
    static func compile() async throws -> WKContentRuleList {
        let json = try rulesJSON()
        guard let list = try await WKContentRuleListStore.default()
            .compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json)
        else { throw CompileError.noList }
        return list
    }

    /// Adds the list to `controller`. On failure it logs and returns false and
    /// the pane carries on with navigation policy alone.
    @MainActor
    @discardableResult
    static func install(into controller: WKUserContentController) async -> Bool {
        do {
            controller.add(try await compile())
            return true
        } catch {
            log.error("Verse pane content rules unavailable: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    enum CompileError: Error { case noList }

    // MARK: - Private

    private static func hostFilter(exact domain: String) -> String {
        "^https://\(escaped(domain))/"
    }

    private static func hostFilter(subdomainsOf domain: String) -> String {
        "^https://[^/:@]*\\.\(escaped(domain))/"
    }

    private static func escaped(_ domain: String) -> String {
        domain.replacingOccurrences(of: ".", with: "\\.")
    }

    private static func allow(_ filter: String, types: [String]? = nil) -> [String: Any] {
        rule(filter: filter, action: "ignore-previous-rules", types: types)
    }

    private static func rule(filter: String, action: String, types: [String]? = nil) -> [String: Any] {
        var trigger: [String: Any] = ["url-filter": filter]
        if let types { trigger["resource-type"] = types }
        return ["trigger": trigger, "action": ["type": action]]
    }
}
