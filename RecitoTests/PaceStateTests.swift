//
//  PaceStateTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

struct PaceStateTests {
    @Test func zeroIsOnPaceAndEmpty() {
        #expect(PaceState.zero.status == .onPace)
        #expect(PaceState.zero.remaining == 0)
        #expect(PaceState.zero.projectedTotal == nil)
    }

    @Test func behindBeyondTolerance() {
        let p = PaceState.make(youFill: 0.2, elapsed: 50, timeLimit: 100)
        #expect(p.status == .behind)
        #expect(p.shouldBe == 0.5)
    }

    @Test func aheadBeyondTolerance() {
        #expect(PaceState.make(youFill: 0.8, elapsed: 50, timeLimit: 100).status == .ahead)
    }

    @Test func withinToleranceIsOnPace() {
        #expect(PaceState.make(youFill: 0.52, elapsed: 50, timeLimit: 100).status == .onPace)
        #expect(PaceState.make(youFill: 0.48, elapsed: 50, timeLimit: 100).status == .onPace)
    }

    @Test func justOutsideToleranceFlips() {
        #expect(PaceState.make(youFill: 0.54, elapsed: 50, timeLimit: 100).status == .ahead)
        #expect(PaceState.make(youFill: 0.46, elapsed: 50, timeLimit: 100).status == .behind)
    }

    @Test func customToleranceIsHonoured() {
        #expect(PaceState.make(youFill: 0.6, elapsed: 50, timeLimit: 100, tolerance: 0.2).status == .onPace)
        #expect(PaceState.make(youFill: 0.6, elapsed: 50, timeLimit: 100, tolerance: 0).status == .ahead)
    }

    @Test func inputsAreClamped() {
        let p = PaceState.make(youFill: 5, elapsed: 500, timeLimit: 100)
        #expect(p.youFill == 1)
        #expect(p.shouldBe == 1)
        let q = PaceState.make(youFill: -1, elapsed: -5, timeLimit: 100)
        #expect(q.youFill == 0)
        #expect(q.shouldBe == 0)
    }

    @Test func zeroTimeLimitHasNoShouldBe() {
        let p = PaceState.make(youFill: 0.5, elapsed: 10, timeLimit: 0)
        #expect(p.shouldBe == 0)
        #expect(p.status == .ahead)
        #expect(p.remaining == 0)
    }

    @Test func remainingNeverGoesNegative() {
        #expect(PaceState.make(youFill: 0, elapsed: 30, timeLimit: 100).remaining == 70)
        #expect(PaceState.make(youFill: 0, elapsed: 130, timeLimit: 100).remaining == 0)
    }

    @Test func percentThroughRounds() {
        #expect(PaceState.make(youFill: 0.584, elapsed: 0, timeLimit: 100).percentThrough == 58)
        #expect(PaceState.make(youFill: 0.585, elapsed: 0, timeLimit: 100).percentThrough == 59)
        #expect(PaceState.make(youFill: 1, elapsed: 0, timeLimit: 100).percentThrough == 100)
    }

    @Test func projectionNeedsEnoughProgressAndTime() {
        #expect(PaceState.make(youFill: 0, elapsed: 60, timeLimit: 100).projectedTotal == nil)
        #expect(PaceState.make(youFill: 0.05, elapsed: 60, timeLimit: 100).projectedTotal == nil)
        #expect(PaceState.make(youFill: 0.5, elapsed: 5, timeLimit: 100).projectedTotal == nil)
        #expect(PaceState.make(youFill: 0.5, elapsed: 0, timeLimit: 100).projectedTotal == nil)
    }

    @Test func projectionExtrapolatesTheCurrentRate() throws {
        let total = try #require(PaceState.make(youFill: 0.25, elapsed: 30, timeLimit: 100).projectedTotal)
        #expect(abs(total - 120) < 1e-9)
    }

    @Test func statusLabels() {
        #expect(PaceStatus.behind.label == "Behind")
        #expect(PaceStatus.onPace.label == "On pace")
        #expect(PaceStatus.ahead.label == "Ahead")
    }
}
