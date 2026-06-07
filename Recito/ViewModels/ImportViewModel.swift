//
//  ImportViewModel.swift
//  Recito
//
//  Turns pasted/imported text into a new Talk. Mode is auto-detected: headings
//  or bullets → outline; pure prose → script (the user can switch later).
//

import Foundation
import Combine

final class ImportViewModel: ObservableObject {
    @Published var pasteText: String = ""
    @Published var fileImporterPresented = false

    var canAdd: Bool {
        !pasteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func makeTalk(defaultTimeLimit: TimeInterval, mode: DocumentMode) -> Talk? {
        let trimmed = pasteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Talk(
            title: Self.deriveTitle(from: trimmed),
            sourceText: trimmed,
            preferredMode: mode,
            timeLimit: defaultTimeLimit
        )
    }

    func loadFile(at url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            pasteText = text
        } else if let data = try? Data(contentsOf: url),
                  let text = String(data: data, encoding: .utf8) {
            pasteText = text
        }
    }

    // MARK: - Helpers

    static func deriveTitle(from source: String) -> String {
        for line in source.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let clean = MarkdownParser.stripMarkers(trimmed)
            return String(clean.prefix(60)).trimmingCharacters(in: .whitespaces)
        }
        return "Untitled talk"
    }

    static func detectMode(from source: String) -> DocumentMode {
        // Headings are neutral (scripts use them as section breaks). Default to
        // outline only when bullets dominate over prose paragraphs.
        let blocks = MarkdownParser.tokenize(source)
        var paragraphs = 0
        var listItems = 0
        for block in blocks {
            switch block.kind {
            case .paragraph: paragraphs += 1
            case .listItem: listItems += 1
            case .heading: break
            }
        }
        return listItems > paragraphs ? .outline : .script
    }
}
