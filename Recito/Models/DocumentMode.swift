//
//  DocumentMode.swift
//  Recito
//
//  The two reading modes derived from one imported source.
//

import Foundation

enum DocumentMode: String, Codable, CaseIterable, Identifiable {
    case script
    case outline

    var id: String { rawValue }

    /// Human label as shown in the mode tag ("Script" / "Outline").
    var label: String {
        switch self {
        case .script: return "Script"
        case .outline: return "Outline"
        }
    }

    /// SF Symbol used on the mode tag.
    var symbol: String {
        switch self {
        case .script: return "paragraphsign"
        case .outline: return "list.bullet"
        }
    }
}
