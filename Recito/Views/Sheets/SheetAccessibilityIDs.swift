//
//  SheetAccessibilityIDs.swift
//  Recito
//
//  Sheet control identifiers added alongside the sheets that use them. Same
//  scheme as AXID (`sheet.<name>.element`); candidates to fold into AXID.
//

import Foundation

extension AXID.Pacing {
    static let preview = "sheet.pacing.preview"
}

extension AXID.Text {
    static let typeface = "sheet.text.typeface"
    static let textSize = "sheet.text.textSize"
    static let lineSpacing = "sheet.text.lineSpacing"
    static let boldText = "sheet.text.boldText"
    static let theme = "sheet.text.theme"
    static let keepAwake = "sheet.text.keepAwake"
    static let recognitionLanguage = "sheet.text.recognitionLanguage"
    static let autoOpenScripture = "sheet.text.autoOpenScripture"
    static let scriptureDestination = "sheet.text.scriptureDestination"
    static let voiceDebug = "sheet.text.voiceDebug"
    static let done = "sheet.text.done"
}

extension AXID.Import {
    static let mode = "sheet.import.mode"
    static let markdownFile = "sheet.import.markdownFile"
    static let filesApp = "sheet.import.filesApp"
    static let keyboardDone = "sheet.import.keyboardDone"
}

extension AXID.Edit {
    static let title = "sheet.edit.title"
    static let mode = "sheet.edit.mode"
    static let cancel = "sheet.edit.cancel"
    static let keyboardDone = "sheet.edit.keyboardDone"
}
