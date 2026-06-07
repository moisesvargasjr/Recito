//
//  ScriptSegmenter.swift
//  Recito
//
//  Builds the Script (prose) reading model: every block becomes a paragraph
//  Section in document order, with scripture citations attached.
//

import Foundation

enum ScriptSegmenter {
    static func segment(_ blocks: [Block]) -> [ScriptSection] {
        blocks.enumerated().map { index, block in
            let isHeading: Bool
            if case .heading = block.kind { isHeading = true } else { isHeading = false }
            return ScriptSection(
                index: index,
                text: block.text,
                citations: block.citations,
                isHeading: isHeading
            )
        }
    }
}
