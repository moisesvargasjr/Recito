//
//  WebReloadBudgetTests.swift
//  RecitoTests
//

import Testing
@testable import Recito

struct WebReloadBudgetTests {
    @Test func allowsExactlyTheDefaultLimitOfReloads() {
        var budget: WebReloadBudget? = WebReloadBudget()
        var reloads = 0
        while let current = budget {
            budget = current.consuming()
            if budget != nil { reloads += 1 }
        }
        #expect(reloads == WebReloadBudget.defaultLimit)
    }

    @Test func emptyBudgetRefuses() {
        #expect(WebReloadBudget(remaining: 0).consuming() == nil)
    }

    @Test func negativeRemainingIsClampedToEmpty() {
        #expect(WebReloadBudget(remaining: -3).remaining == 0)
    }
}
