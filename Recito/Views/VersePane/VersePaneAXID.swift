//
//  VersePaneAXID.swift
//  Recito
//
//  Accessibility identifiers for the in-app verse pane, kept beside the
//  feature and namespaced under `AXID` like every other screen.
//

import Foundation

extension AXID {
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
}
