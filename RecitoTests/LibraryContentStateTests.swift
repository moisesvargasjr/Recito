import Testing
@testable import Recito

@MainActor
struct LibraryContentStateTests {
    @Test func showsGridWhenAnythingIsVisible() {
        #expect(LibraryContentState.resolve(displayCount: 3, totalCount: 3, searchText: "") == .grid)
        #expect(LibraryContentState.resolve(displayCount: 1, totalCount: 5, searchText: "rom") == .grid)
    }

    @Test func emptyLibrary() {
        #expect(LibraryContentState.resolve(displayCount: 0, totalCount: 0, searchText: "") == .noTalks)
        #expect(LibraryContentState.resolve(displayCount: 0, totalCount: 0, searchText: "   ") == .noTalks)
    }

    @Test func everythingHidden() {
        #expect(LibraryContentState.resolve(displayCount: 0, totalCount: 2, searchText: "") == .allHidden)
    }

    @Test func searchWithoutMatchesWinsAndTrimsQuery() {
        #expect(LibraryContentState.resolve(displayCount: 0, totalCount: 4, searchText: " faith ")
            == .noResults(query: "faith"))
        #expect(LibraryContentState.resolve(displayCount: 0, totalCount: 0, searchText: "x")
            == .noResults(query: "x"))
    }
}
