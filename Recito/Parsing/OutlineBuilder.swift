//
//  OutlineBuilder.swift
//  Recito
//
//  Builds the Outline reading model from the same blocks. Headings and
//  top-level list items become numbered points; indented list items become
//  sub-bullets. A pure-prose document (no headings/bullets) falls back to one
//  numbered point per paragraph so Outline mode still works.
//

import Foundation

enum OutlineBuilder {
    /// Leading-space count at or above which a list item is a sub-bullet.
    static let subIndentThreshold = 2

    static func build(_ blocks: [Block]) -> [OutlineNode] {
        let hasStructure = blocks.contains { block in
            switch block.kind {
            case .heading, .listItem: return true
            case .paragraph: return false
            }
        }

        var nodes: [OutlineNode] = []
        var pointNumber = 0

        func add(_ block: Block, level: Int) {
            let number: String?
            if level == 0 {
                pointNumber += 1
                number = "\(pointNumber)"
            } else {
                number = nil
            }
            nodes.append(
                OutlineNode(
                    index: nodes.count,
                    number: number,
                    text: block.text,
                    level: level,
                    citations: block.citations
                )
            )
        }

        if hasStructure {
            for block in blocks {
                switch block.kind {
                case .heading:
                    add(block, level: 0)
                case .listItem(let indent):
                    add(block, level: indent >= subIndentThreshold ? 1 : 0)
                case .paragraph:
                    continue // prose is not shown in outline mode
                }
            }
        } else {
            for block in blocks {
                add(block, level: 0)
            }
        }

        return nodes
    }
}
