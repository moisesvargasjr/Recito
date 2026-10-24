//
//  LibraryViewModelTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct LibraryViewModelTests {
    private func talk(
        _ title: String,
        body: String = "body",
        opened: TimeInterval,
        hidden: Bool = false
    ) -> Talk {
        Talk(
            title: title,
            sourceText: body,
            lastOpenedAt: Date(timeIntervalSince1970: opened),
            isHidden: hidden
        )
    }

    @Test func emptyLibraryYieldsNothing() {
        let vm = LibraryViewModel()
        #expect(vm.displayTalks(from: []).isEmpty)
        #expect(vm.recentTalkID(from: []) == nil)
        #expect(vm.hiddenCount(in: []) == 0)
    }

    @Test func sortsMostRecentlyOpenedFirst() {
        let a = talk("A", opened: 10)
        let b = talk("B", opened: 30)
        let c = talk("C", opened: 20)
        #expect(LibraryViewModel().displayTalks(from: [a, b, c]).map(\.title) == ["B", "C", "A"])
    }

    @Test func searchMatchesTitleCaseInsensitively() {
        let vm = LibraryViewModel()
        vm.searchText = "hope"
        let hit = talk("A Message of HOPE", opened: 1)
        let miss = talk("Other", opened: 2)
        #expect(vm.displayTalks(from: [hit, miss]) == [hit])
    }

    @Test func searchMatchesBody() {
        let vm = LibraryViewModel()
        vm.searchText = "kingdom"
        let hit = talk("A", body: "The Kingdom comes", opened: 1)
        let miss = talk("B", body: "nothing", opened: 2)
        #expect(vm.displayTalks(from: [hit, miss]) == [hit])
    }

    @Test func searchIsTrimmed() {
        let vm = LibraryViewModel()
        vm.searchText = "  hope \n"
        let hit = talk("Hope", opened: 1)
        #expect(vm.displayTalks(from: [hit]) == [hit])
    }

    @Test func whitespaceOnlySearchReturnsEverything() {
        let vm = LibraryViewModel()
        vm.searchText = "   "
        #expect(vm.displayTalks(from: [talk("A", opened: 1), talk("B", opened: 2)]).count == 2)
    }

    @Test func searchWithNoMatchIsEmpty() {
        let vm = LibraryViewModel()
        vm.searchText = "zzz"
        #expect(vm.displayTalks(from: [talk("A", opened: 1)]).isEmpty)
    }

    @Test func hiddenTalksAreExcludedByDefault() {
        let shown = talk("Shown", opened: 1)
        let hidden = talk("Hidden", opened: 2, hidden: true)
        #expect(LibraryViewModel().displayTalks(from: [shown, hidden]) == [shown])
    }

    @Test func hiddenTalksAppearWhenRequestedAndStaySorted() {
        let vm = LibraryViewModel()
        vm.showsHidden = true
        let shown = talk("Shown", opened: 1)
        let hidden = talk("Hidden", opened: 2, hidden: true)
        #expect(vm.displayTalks(from: [shown, hidden]) == [hidden, shown])
    }

    @Test func searchAppliesToHiddenOnlyWhenShown() {
        let vm = LibraryViewModel()
        vm.searchText = "secret"
        let hidden = talk("Secret", opened: 1, hidden: true)
        #expect(vm.displayTalks(from: [hidden]).isEmpty)
        vm.showsHidden = true
        #expect(vm.displayTalks(from: [hidden]) == [hidden])
    }

    @Test func recentTalkIsTheNewestVisibleOne() {
        let old = talk("Old", opened: 1)
        let newest = talk("New", opened: 5)
        let hiddenNewer = talk("Hidden", opened: 9, hidden: true)
        #expect(LibraryViewModel().recentTalkID(from: [old, newest, hiddenNewer]) == newest.id)
    }

    @Test func recentTalkIsNilWhenEverythingIsHidden() {
        #expect(LibraryViewModel().recentTalkID(from: [talk("H", opened: 1, hidden: true)]) == nil)
    }

    @Test func hiddenCountCountsOnlyHidden() {
        let talks = [talk("A", opened: 1), talk("B", opened: 2, hidden: true), talk("C", opened: 3, hidden: true)]
        #expect(LibraryViewModel().hiddenCount(in: talks) == 2)
    }

    @Test func defaultsAreEmptySearchAndHiddenOff() {
        let vm = LibraryViewModel()
        #expect(vm.searchText.isEmpty)
        #expect(!vm.showsHidden)
    }
}
