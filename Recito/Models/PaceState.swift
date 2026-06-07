//
//  PaceState.swift
//  Recito
//
//  Time-pacing snapshot recomputed each tick. `youFill` is how far through the
//  script the speaker is; `shouldBe` is where an even reader would be by now.
//

import Foundation

enum PaceStatus: Equatable {
    case behind   // covering less script than time used → will run over
    case onPace   // roughly matching the clock
    case ahead    // covering more script than time used → can slow down

    var label: String {
        switch self {
        case .behind: return "Behind"
        case .onPace: return "On pace"
        case .ahead: return "Ahead"
        }
    }
}

struct PaceState: Equatable {
    /// 0...1 — fraction of the script consumed.
    let youFill: Double
    /// 0...1 — fraction of the time limit elapsed (the pace marker position).
    let shouldBe: Double
    let status: PaceStatus
    let elapsed: TimeInterval
    let timeLimit: TimeInterval

    static let zero = PaceState(youFill: 0, shouldBe: 0, status: .onPace, elapsed: 0, timeLimit: 0)

    /// Build a snapshot. Compares how far through the script you are vs. how much
    /// of the time has elapsed: behind / on pace / ahead, within a tolerance.
    static func make(
        youFill: Double,
        elapsed: TimeInterval,
        timeLimit: TimeInterval,
        tolerance: Double = 0.03
    ) -> PaceState {
        let you = min(max(youFill, 0), 1)
        let should = timeLimit > 0 ? min(max(elapsed / timeLimit, 0), 1) : 0
        let diff = you - should
        let status: PaceStatus = diff < -tolerance ? .behind : (diff > tolerance ? .ahead : .onPace)
        return PaceState(youFill: you, shouldBe: should, status: status, elapsed: elapsed, timeLimit: timeLimit)
    }

    /// Percent through the script, e.g. 58 for "~58%".
    var percentThrough: Int { Int((youFill * 100).rounded()) }

    /// Time left against the set limit.
    var remaining: TimeInterval { max(0, timeLimit - elapsed) }

    /// Estimated total talk length at the current reading rate (nil until there's
    /// enough progress to project reliably). Compare to `timeLimit` for over/under.
    var projectedTotal: TimeInterval? {
        guard youFill > 0.05, elapsed > 5 else { return nil }
        return elapsed / youFill
    }
}
