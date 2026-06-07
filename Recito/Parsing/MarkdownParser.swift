//
//  MarkdownParser.swift
//  Recito
//
//  Parses one source text into both reading models. The source is tokenized
//  into blocks (headings / list items / paragraphs); ScriptSegmenter builds the
//  prose model and OutlineBuilder builds the outline model from the same blocks.
//

import Foundation

/// A coarse Markdown block. Inline emphasis markers are already stripped.
enum BlockKind: Equatable {
    case heading(level: Int)
    case listItem(indent: Int)
    case paragraph
}

struct Block: Equatable {
    let kind: BlockKind
    /// Display text: Markdown links reduced to their label, emphasis stripped.
    let text: String
    /// Citations detected from the raw text (links tagged + carry their URL).
    let citations: [ScriptureCitation]
}

enum MarkdownParser {

    /// Parse source into the combined document model.
    static func parse(_ source: String) -> ParsedDocument {
        let blocks = tokenize(source)
        let sections = ScriptSegmenter.segment(blocks)
        let outline = OutlineBuilder.build(blocks)

        var refs: [CitationRef] = []
        for section in sections {
            for citation in section.citations {
                refs.append(CitationRef(citation: citation, sectionIndex: section.index))
            }
        }
        return ParsedDocument(scriptSections: sections, outlineNodes: outline, allCitations: refs)
    }

    // MARK: - Tokenizing

    static func tokenize(_ source: String) -> [Block] {
        var blocks: [Block] = []
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            guard !paragraphBuffer.isEmpty else { return }
            let raw = paragraphBuffer.joined(separator: " ")
            if let block = makeBlock(kind: .paragraph, raw: raw) { blocks.append(block) }
            paragraphBuffer.removeAll()
        }

        for rawLine in source.components(separatedBy: .newlines) {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                continue
            }
            if let heading = headingMatch(trimmed) {
                flushParagraph()
                if let block = makeBlock(kind: .heading(level: heading.level), raw: heading.text) {
                    blocks.append(block)
                }
                continue
            }
            if let item = listMatch(rawLine) {
                flushParagraph()
                if let block = makeBlock(kind: .listItem(indent: item.indent), raw: item.text) {
                    blocks.append(block)
                }
                continue
            }
            paragraphBuffer.append(trimmed)
        }
        flushParagraph()
        return blocks
    }

    /// Build a block from raw text: clean display text + citations (which carry
    /// link state). Returns nil if the text is empty after cleaning.
    private static func makeBlock(kind: BlockKind, raw: String) -> Block? {
        let display = clean(raw)
        guard !display.isEmpty else { return nil }
        return Block(kind: kind, text: display, citations: ScriptureDetector.detect(inRaw: raw))
    }

    /// Display cleanup: reduce Markdown links to labels, strip emphasis.
    private static func clean(_ text: String) -> String {
        stripInlineMarkers(ScriptureDetector.stripLinks(text))
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Line helpers

    /// Strip Markdown structure from a single line (heading hashes, list marker,
    /// inline emphasis). Used for card thumbnail previews.
    static func stripMarkers(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if let heading = headingMatch(trimmed) { return clean(heading.text) }
        if let item = listMatch(line) { return clean(item.text) }
        return clean(trimmed)
    }

    private static func headingMatch(_ trimmed: String) -> (level: Int, text: String)? {
        var hashes = 0
        for ch in trimmed {
            if ch == "#" { hashes += 1 } else { break }
        }
        guard (1...6).contains(hashes) else { return nil }
        let rest = trimmed.dropFirst(hashes)
        guard rest.first == " " else { return nil }
        return (hashes, rest.trimmingCharacters(in: .whitespaces))
    }

    private static let listRegex = try! NSRegularExpression(
        pattern: #"^(\s*)([-*+]|\d+[.)])\s+(.*)$"#
    )

    private static func listMatch(_ line: String) -> (indent: Int, text: String)? {
        let ns = line as NSString
        guard let m = listRegex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 4 else { return nil }
        let indentString = ns.substring(with: m.range(at: 1))
        let indent = indentString.reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
        let text = ns.substring(with: m.range(at: 3))
        return (indent, text)
    }

    private static func stripInlineMarkers(_ s: String) -> String {
        var text = s
        for token in ["**", "__", "~~", "*", "_", "`"] {
            text = text.replacingOccurrences(of: token, with: "")
        }
        return text
    }
}
