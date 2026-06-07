//
//  OutlineNode.swift
//  Recito
//
//  One row of the Outline reading model. Level 0 = a numbered main point;
//  level 1 = an indented sub-bullet (rendered with a dash). Nodes are stored
//  flat in display order, sharing an index space with the reader cursor.
//

import Foundation

struct OutlineNode: Identifiable, Equatable {
    let index: Int
    /// "1", "2", … for level-0 points; nil for sub-bullets (shown as "—").
    let number: String?
    let text: String
    /// 0 = main point, 1 = sub-bullet.
    let level: Int
    let citations: [ScriptureCitation]

    var id: Int { index }
    var isSubBullet: Bool { level > 0 }
}
