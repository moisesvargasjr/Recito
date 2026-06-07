//
//  ScriptureLinker.swift
//  Recito
//
//  Swappable seam for deep-linking a scripture citation into an external
//  reference app. The cue chip only knows "link this citation"; which app and
//  URL scheme is an implementation detail (keeps neutral branding out of core).
//

import Foundation

protocol ScriptureLinker {
    /// The deep link for a citation, or nil if it can't be built.
    func url(for citation: ScriptureCitation) -> URL?
}
