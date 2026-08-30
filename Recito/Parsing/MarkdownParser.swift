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
        let source = stripLeadingNotes(source)

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
            paragraphBuffer.append(stripQuoteMarker(trimmed))
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

    // MARK: - Leading notes

    /// Vault notes open with material that is *about* the talk rather than part
    /// of it: YAML frontmatter, and an editorial blockquote ("Source: Apple
    /// Notes...", "Rebalanced variant of..."). Both are dropped so the talk
    /// starts on its first spoken line. Blockquotes later in the document are
    /// kept — those are quoted passages the speaker may well read aloud.
    static func stripLeadingNotes(_ source: String) -> String {
        var lines = source.components(separatedBy: .newlines)

        // Frontmatter: a leading `---` fence through its closing `---`.
        var cursor = 0
        while cursor < lines.count, lines[cursor].trimmingCharacters(in: .whitespaces).isEmpty {
            cursor += 1
        }
        if cursor < lines.count, isFence(lines[cursor]) {
            var scan = cursor + 1
            while scan < lines.count, !isFence(lines[scan]) { scan += 1 }
            if scan < lines.count { lines.removeFirst(scan + 1) }
        }

        // Editorial blockquote: leading `>` lines, plus blank lines around them,
        // up to the first line of real content.
        var drop = 0
        var sawQuote = false
        var index = 0
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                index += 1
                continue
            }
            guard isQuoteLine(trimmed) else { break }
            sawQuote = true
            index += 1
            drop = index
        }
        if sawQuote { lines.removeFirst(drop) }

        while let first = lines.first, first.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeFirst()
        }
        return lines.joined(separator: "\n")
    }

    /// The document's first heading, if it opens with one. Vault talks title
    /// themselves from this and fall back to their filename — a truncated first
    /// sentence makes a far worse library card than the name of the note.
    static func headingTitle(from source: String) -> String? {
        for line in stripLeadingNotes(source).components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            guard let heading = headingMatch(trimmed) else { return nil }
            let text = clean(heading.text)
            return text.isEmpty ? nil : text
        }
        return nil
    }

    private static func isFence(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces) == "---"
    }

    private static func isQuoteLine(_ trimmed: String) -> Bool {
        trimmed.hasPrefix(">")
    }

    /// Drop the `>` marker(s) from a quoted line, keeping the quoted text.
    static func stripQuoteMarker(_ trimmed: String) -> String {
        var text = Substring(trimmed)
        while text.first == ">" {
            text = text.dropFirst()
            while text.first == " " { text = text.dropFirst() }
        }
        return String(text)
    }
}
