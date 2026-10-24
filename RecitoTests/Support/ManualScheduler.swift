//
//  ManualScheduler.swift
//  RecitoTests
//
//  A ReaderScheduler that holds work until the test runs it.
//

import Combine
import Foundation
@testable import Recito

@MainActor
final class ManualScheduler: ReaderScheduler {
    struct Item {
        let delay: TimeInterval
        let work: () -> Void
        var isDone = false
    }

    private(set) var items: [Item] = []

    /// Work that has been scheduled and neither cancelled nor run.
    var pending: [Item] { items.filter { !$0.isDone } }

    func schedule(after delay: TimeInterval, work: @escaping () -> Void) -> Cancellable {
        let index = items.count
        items.append(Item(delay: delay, work: work))
        return AnyCancellable { [weak self] in
            MainActor.assumeIsolated { self?.items[index].isDone = true }
        }
    }

    /// Run (and consume) every pending item.
    func runPending() {
        let due = pending
        for index in items.indices { items[index].isDone = true }
        due.forEach { $0.work() }
    }
}
