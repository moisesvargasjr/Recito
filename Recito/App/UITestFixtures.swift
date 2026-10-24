//
//  UITestFixtures.swift
//  Recito
//
//  DEBUG-only library contents selected by `-seed <fixture>`. Talk IDs are
//  deterministic (`talkID(n)` = n-th talk of the fixture, 1-based) so UI tests
//  can open one with `-openTalk` and address its card via AXID.
//

#if DEBUG
import Foundation

extension UITestFixture {
    /// Stable ID of the `number`-th talk (1-based) in any fixture.
    static func talkID(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!
    }

    var talks: [Talk] {
        switch self {
        case .samples: return Self.samplesTalks
        case .empty: return []
        case .longScript: return [Self.longScriptTalk]
        case .outline: return [Self.outlineTalk]
        case .many: return Self.manyTalks
        case .mixedHidden: return Self.mixedHiddenTalks
        }
    }

    // MARK: - Builders

    private static let epoch = Date(timeIntervalSince1970: 1_750_000_000)

    private static func make(
        _ number: Int,
        title: String,
        text: String,
        mode: DocumentMode = .script,
        minutes: Int = 30,
        source: TalkSource = .local,
        isHidden: Bool = false
    ) -> Talk {
        let stamp = epoch.addingTimeInterval(-Double(number) * 3_600)
        return Talk(
            id: talkID(number),
            title: title,
            sourceText: text,
            preferredMode: mode,
            timeLimit: TimeInterval(minutes * 60),
            createdAt: stamp,
            lastOpenedAt: stamp,
            source: source,
            isHidden: isHidden
        )
    }

    private static var samplesTalks: [Talk] {
        SampleTalks.all.enumerated().map { offset, sample in
            Talk(
                id: talkID(offset + 1),
                title: sample.title,
                sourceText: sample.sourceText,
                preferredMode: sample.preferredMode,
                timeLimit: sample.timeLimit,
                createdAt: sample.createdAt,
                lastOpenedAt: sample.lastOpenedAt
            )
        }
    }

    /// 60 paragraphs, 3 headings, 2 Markdown-linked citations (paragraphs 15 and 40).
    private static var longScriptTalk: Talk {
        var lines: [String] = []
        for number in 1...60 {
            if [1, 21, 41].contains(number) {
                lines.append("# Part \(number / 20 + 1)")
            }
            lines.append(paragraph(number))
        }
        return make(1, title: "Long Script Fixture", text: lines.joined(separator: "\n\n"))
    }

    private static func paragraph(_ number: Int) -> String {
        let base = "Paragraph \(number) keeps the reader moving steadily down the page, giving the "
            + "speaker enough words to scroll through at a measured and comfortable pace."
        switch number {
        case 15: return base + " As [Ps. 37:7](https://example.com/ps37-7) reminds us, patience is active."
        case 40: return base + " Consider [Heb. 11:1](https://example.com/heb11-1) and what faith builds."
        default: return base
        }
    }

    /// 12 nodes: 6 points, each with one sub-bullet; one linked citation.
    private static var outlineTalk: Talk {
        var lines: [String] = []
        for point in 1...6 {
            lines.append("\(point). Main point number \(point)")
            if point == 3 {
                lines.append("   - [Heb. 11:1](https://example.com/heb11-1) the assured expectation")
            } else {
                lines.append("   - Supporting idea for point \(point)")
            }
        }
        return make(1, title: "Outline Fixture", text: lines.joined(separator: "\n"), mode: .outline)
    }

    private static var manyTalks: [Talk] {
        (1...14).map { number in
            let isOutline = number.isMultiple(of: 3)
            let text = isOutline
                ? "1. Opening thought \(number)\n   - Detail\n2. Closing thought \(number)"
                : "First paragraph of talk \(number).\n\nSecond paragraph of talk \(number)."
            return make(
                number,
                title: String(format: "Talk %02d", number),
                text: text,
                mode: isOutline ? .outline : .script,
                minutes: 10 + number
            )
        }
    }

    /// Five vault-mirrored talks; the 2nd and 4th are hidden.
    private static var mixedHiddenTalks: [Talk] {
        (1...5).map { number in
            make(
                number,
                title: "Vault Note \(number)",
                text: "Body of vault note \(number).\n\nMore text.",
                source: .vault(relativePath: "talks/note-\(number).md"),
                isHidden: number == 2 || number == 4
            )
        }
    }
}
#endif
