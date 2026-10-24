//
//  AccessibilityID.swift
//  Recito
//
//  Single source of truth for accessibility identifiers, shared by views and UI
//  tests. Scheme: `screen.element[.qualifier]`.
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
    }

    enum Pacing {
        static let root = "sheet.pacing.root"
        static let custom = "sheet.pacing.custom"
        static let stepper = "sheet.pacing.stepper"
        static let done = "sheet.pacing.done"
        static let cancel = "sheet.pacing.cancel"
        static func preset(_ minutes: Int) -> String { "sheet.pacing.preset.\(minutes)" }
    }

    enum Text {
        static let root = "sheet.text.root"
    }

    enum Import {
        static let root = "sheet.import.root"
        static let text = "sheet.import.text"
        static let title = "sheet.import.title"
        static let create = "sheet.import.create"
        static let cancel = "sheet.import.cancel"
        static let linkVault = "sheet.import.linkVault"
    }

    enum Edit {
        static let root = "sheet.edit.root"
        static let text = "sheet.edit.text"
        static let save = "sheet.edit.save"
    }
}
