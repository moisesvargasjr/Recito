//
//  TimeFormat.swift
//  Recito
//
//  Clock formatting for timers ("12:30", "30:00").
//

import Foundation

extension TimeInterval {
    /// Minutes:seconds, e.g. 750 → "12:30".
    var clockString: String {
        let total = Int(rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
