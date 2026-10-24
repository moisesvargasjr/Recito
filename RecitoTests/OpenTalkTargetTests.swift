import Foundation
import Testing
@testable import Recito

@MainActor
struct OpenTalkTargetTests {
    private let first = Talk(id: UITestFixture.talkID(1), title: "One", sourceText: "a")
    private let second = Talk(id: UITestFixture.talkID(2), title: "Two", sourceText: "b")

    @Test func matchesUppercaseID() {
        let id = UITestFixture.talkID(2).uuidString
        #expect(OpenTalkTarget.talk(matching: id, in: [first, second])?.id == second.id)
    }

    @Test func matchesLowercaseAndPaddedID() {
        let id = "  " + UITestFixture.talkID(1).uuidString.lowercased() + "\n"
        #expect(OpenTalkTarget.talk(matching: id, in: [first, second])?.id == first.id)
    }

    @Test func noMatchForUnknownMalformedOrMissingID() {
        #expect(OpenTalkTarget.talk(matching: UITestFixture.talkID(9).uuidString, in: [first, second]) == nil)
        #expect(OpenTalkTarget.talk(matching: "not-a-uuid", in: [first, second]) == nil)
        #expect(OpenTalkTarget.talk(matching: nil, in: [first, second]) == nil)
        #expect(OpenTalkTarget.talk(matching: UITestFixture.talkID(1).uuidString, in: []) == nil)
    }
}
