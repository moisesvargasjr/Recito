//
//  TimeFormattingTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

struct TimeFormattingTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (59.0, "0:59"),
        (60.0, "1:00"),
        (750.0, "12:30"),
        (3599.0, "59:59"),
        (3600.0, "60:00"),
        (5400.0, "90:00"),
        (36000.0, "600:00"),
    ])
    func formatsMinutesAndSeconds(seconds: Double, expected: String) {
        #expect(seconds.clockString == expected)
    }

    @Test func roundsToTheNearestSecond() {
        #expect(59.4.clockString == "0:59")
        #expect(59.6.clockString == "1:00")
    }

    @Test func negativeValuesDoNotCrash() {
        // Documents current behaviour: sign is carried on both fields.
        #expect((-5.0).clockString == "0:-5")
        #expect((-65.0).clockString == "-1:-5")
    }
}
