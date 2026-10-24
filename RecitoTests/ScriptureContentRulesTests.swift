//
//  ScriptureContentRulesTests.swift
//  RecitoTests
//

import Foundation
import Testing
import WebKit
@testable import Recito

@MainActor
struct ScriptureContentRulesTests {
    private func allowFilters(types: Bool) -> [String] {
        ScriptureContentRules.rules().dropFirst().compactMap { rule in
            let trigger = rule["trigger"] as? [String: Any]
            guard (trigger?["resource-type"] != nil) == types else { return nil }
            return trigger?["url-filter"] as? String
        }
    }

    private func matches(_ filters: [String], _ url: String) -> Bool {
        filters.contains { filter in
            guard let regex = try? NSRegularExpression(pattern: filter, options: [.caseInsensitive]) else { return false }
            return regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) != nil
        }
    }

    @Test func blocksEverythingFirstThenAllowsHosts() throws {
        let rules = ScriptureContentRules.rules()
        let first = try #require(rules.first)
        #expect((first["action"] as? [String: String])?["type"] == "block")
        for rule in rules.dropFirst() {
            #expect((rule["action"] as? [String: String])?["type"] == "ignore-previous-rules")
        }
    }

    @Test(arguments: [
        "https://www.jw.org/es/x", "https://jw.org/", "https://wol.jw.org/a",
        "https://b.jw-cdn.org/apis/x", "https://cms-imgp.jw-cdn.org/i.jpg",
    ])
    func jwHostsMatchTheAllowRules(_ url: String) {
        #expect(matches(allowFilters(types: false), url))
    }

    @Test(arguments: [
        "https://evil.com/", "https://evil-jw.org/", "https://jw.org.evil.com/",
        "https://evil.com/jw.org/", "https://evil.com/.jw.org/", "https://evil.com/?x=https://www.jw.org/",
        "https://www.jw.org.evil.com/", "https://notjw-cdn.org/", "http://www.jw.org/",
        "https://www.gstatic.com/x.js", "https://abc.edge.sdk.awswaf.com/x.js",
    ])
    func otherHostsDoNotMatchTheUnrestrictedAllowRules(_ url: String) {
        #expect(!matches(allowFilters(types: false), url))
    }

    @Test func thirdPartyAllowancesAreTypeRestricted() {
        let typed = allowFilters(types: true)
        #expect(matches(typed, "https://www.gstatic.com/cv/js/sender/v1/cast_sender.js"))
        #expect(matches(typed, "https://323701e7ef4e.edge.sdk.awswaf.com/challenge.js"))
        #expect(!matches(typed, "https://evil.com/"))
        #expect(!matches(typed, "https://evilawswaf.com/x.js"))
        #expect(!matches(typed, "https://maps.gstatic.com/x.js"))
    }

    @Test func rulesSerializeToJSON() throws {
        let json = try ScriptureContentRules.rulesJSON()
        let parsed = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]]
        #expect(parsed?.count == ScriptureContentRules.rules().count)
    }

    @Test func webKitAcceptsTheRuleList() async throws {
        let list = try await ScriptureContentRules.compile()
        #expect(list.identifier == ScriptureContentRules.identifier)
    }

    @Test func installAddsTheListToAController() async {
        let controller = WKUserContentController()
        let installed = await ScriptureContentRules.install(into: controller)
        #expect(installed)
    }
}
