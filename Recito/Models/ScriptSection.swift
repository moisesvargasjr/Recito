//
//  ScriptSection.swift
//  Recito
//
//  One unit of the Script (prose) reading model: a paragraph in document order,
//  with any scripture citations detected within it. (Named ScriptSection to
//  avoid colliding with SwiftUI's `Section`.)
//

import Foundation

struct ScriptSection: Identifiable, Equatable {
    let index: Int
    let text: String
    let citations: [ScriptureCitation]
    /// A heading is a section label the speaker uses to break up the script —
    /// shown for orientation but not read aloud (skipped by the highlight).
    var isHeading: Bool = false

    var id: Int { index }
}
