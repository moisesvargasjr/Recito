//
//  ReaderAXID.swift
//  Recito
//
//  Reader identifiers added with the verse pane and the toolbar rework. They
//  extend AXID.Reader (App/AccessibilityID.swift) so UI tests keep one lookup
//  table; fold them into that file when it is next edited.
//

import Foundation

extension AXID.Reader {
    static let resume = "reader.resume"
    static let scriptureHold = "reader.scriptureHold"
    static let listening = "reader.listening"
    static let transportPanelDone = "reader.transportPanel.done"
    static let transportTimer = "reader.transportPanel.timer"
    static let versePane = "reader.versePane"
    static let versePaneDone = "reader.versePane.done"
    static let voiceDebug = "reader.voiceDebug"
}
