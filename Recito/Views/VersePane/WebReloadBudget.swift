//
//  WebReloadBudget.swift
//  Recito
//
//  A cap on automatic recovery from web-content process crashes, so a page
//  that kills its process every time can't reload in a loop.
//

nonisolated struct WebReloadBudget: Equatable, Sendable {
    static let defaultLimit = 2

    let remaining: Int

    init(remaining: Int = WebReloadBudget.defaultLimit) {
        self.remaining = max(0, remaining)
    }

    /// The budget after one reload, or nil when none is left.
    func consuming() -> WebReloadBudget? {
        remaining > 0 ? WebReloadBudget(remaining: remaining - 1) : nil
    }
}
