import SwiftUI
import Testing
@testable import Recito

@MainActor
struct BalancedColumnsTests {
    @Test func narrowSheetWrapsSixChipsToThreeByTwo() {
        // Cover display sheet: 466 pt minus 2 × 24 pt padding.
        #expect(BalancedColumns.count(itemCount: 6, availableWidth: 418, minItemWidth: 76, spacing: 8) == 3)
    }

    @Test func wideSheetKeepsOneRow() {
        #expect(BalancedColumns.count(itemCount: 6, availableWidth: 621, minItemWidth: 76, spacing: 8) == 6)
    }

    @Test func veryNarrowFallsBackToBalancedRows() {
        // Only 2 fit → 3 rows of 2.
        #expect(BalancedColumns.count(itemCount: 6, availableWidth: 170, minItemWidth: 76, spacing: 8) == 2)
        // Only 1 fits.
        #expect(BalancedColumns.count(itemCount: 6, availableWidth: 50, minItemWidth: 76, spacing: 8) == 1)
    }

    @Test func balancesUnevenCounts() {
        // 7 items, 5 fit → 2 rows → 4 columns (4 + 3) rather than 5 + 2.
        #expect(BalancedColumns.count(itemCount: 7, availableWidth: 418, minItemWidth: 76, spacing: 8) == 4)
    }

    @Test func emptyAndInvalidInputsAreSafe() {
        #expect(BalancedColumns.count(itemCount: 0, availableWidth: 400, minItemWidth: 76, spacing: 8) == 1)
        #expect(BalancedColumns.count(itemCount: 3, availableWidth: .infinity, minItemWidth: 76, spacing: 8) == 3)
        #expect(BalancedColumns.count(itemCount: 3, availableWidth: 400, minItemWidth: 0, spacing: 8) == 3)
    }
}
