//
//  AXID.swift
//  RecitoUITests
//
//  Mirror of the app's accessibility identifiers. The UI-test target cannot
//  import app code, so this file MUST carry the same strings as:
//    Recito/App/AccessibilityID.swift
//    Recito/Views/Reader/ReaderAXID.swift
//    Recito/Views/VersePane/VersePaneAXID.swift
//    Recito/Views/Library/LibraryAccessibilityIDs.swift
//    Recito/Views/Sheets/SheetAccessibilityIDs.swift
//  scripts/check-axid-parity.sh fails when the two sides drift.
//

import Foundation

enum AXID {
    enum Library {
        static let root = "library.root"
        static let grid = "library.grid"
        static let importTile = "library.importTile"
        static let importButton = "library.importButton"
        static let settingsButton = "library.settingsButton"
        static let showHiddenToggle = "library.showHiddenToggle"
        static let searchField = "library.searchField"
        static func card(_ id: String) -> String { "library.card.\(id)" }
        static let overflowMenu = "library.overflowMenu"
        static let emptyState = "library.emptyState"
        static let emptyStateImport = "library.emptyState.import"
    }

    enum Reader {
        static let root = "reader.root"
        static let close = "reader.close"
        static let followMode = "reader.followMode"
        static let followModeAuto = "reader.followMode.auto"
        static let followModeVoice = "reader.followMode.voice"
        static let modeToggle = "reader.modeToggle"
        static let aa = "reader.aa"
        static let textSmaller = "reader.textSmaller"
        static let textLarger = "reader.textLarger"
        static let prev = "reader.prev"
        static let play = "reader.play"
        static let next = "reader.next"
        static let timer = "reader.timer"
        static let paceBar = "reader.paceBar"
        static let cueChip = "reader.cueChip"
        static let backToCurrent = "reader.backToCurrent"
        static let transportPanel = "reader.transportPanel"
        static let voiceStatus = "reader.voiceStatus"
        static func paragraph(_ index: Int) -> String { "reader.paragraph.\(index)" }
        static func outlineRow(_ index: Int) -> String { "reader.outlineRow.\(index)" }
        static let resume = "reader.resume"
        static let scriptureHold = "reader.scriptureHold"
        static let listening = "reader.listening"
        static let transportPanelDone = "reader.transportPanel.done"
        static let transportTimer = "reader.transportPanel.timer"
        static let voiceDebug = "reader.voiceDebug"
    }

    enum VersePane {
        static let root = "reader.versePane"
        static let title = "reader.versePane.title"
        static let done = "reader.versePane.done"
        static let openInJWLibrary = "reader.versePane.openInJWLibrary"
        static let web = "reader.versePane.web"
        static let loading = "reader.versePane.loading"
        static let error = "reader.versePane.error"
        static let retry = "reader.versePane.retry"
        static let errorOpenInJWLibrary = "reader.versePane.error.openInJWLibrary"
    }

    enum Pacing {
        static let root = "sheet.pacing.root"
        static let custom = "sheet.pacing.custom"
        static let stepper = "sheet.pacing.stepper"
        static let done = "sheet.pacing.done"
        static let cancel = "sheet.pacing.cancel"
        static func preset(_ minutes: Int) -> String { "sheet.pacing.preset.\(minutes)" }
        static let preview = "sheet.pacing.preview"
    }

    enum Text {
        static let root = "sheet.text.root"
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

    enum Import {
        static let root = "sheet.import.root"
        static let text = "sheet.import.text"
        static let title = "sheet.import.title"
        static let create = "sheet.import.create"
        static let cancel = "sheet.import.cancel"
        static let linkVault = "sheet.import.linkVault"
        static let mode = "sheet.import.mode"
        static let markdownFile = "sheet.import.markdownFile"
        static let filesApp = "sheet.import.filesApp"
        static let keyboardDone = "sheet.import.keyboardDone"
    }

    enum Edit {
        static let root = "sheet.edit.root"
        static let text = "sheet.edit.text"
        static let save = "sheet.edit.save"
        static let title = "sheet.edit.title"
        static let mode = "sheet.edit.mode"
        static let cancel = "sheet.edit.cancel"
        static let keyboardDone = "sheet.edit.keyboardDone"
    }
}
