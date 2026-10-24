//
//  ModelAndSeamTests.swift
//  RecitoTests
//
//  Small value types and the production implementations of the reader seams.
//

import Testing
import Foundation
import Combine
@testable import Recito

@MainActor
struct ModelTests {
    @Test func documentModeMetadata() {
        #expect(DocumentMode.script.label == "Script")
        #expect(DocumentMode.outline.label == "Outline")
        #expect(DocumentMode.script.symbol == "paragraphsign")
        #expect(DocumentMode.outline.symbol == "list.bullet")
        #expect(DocumentMode.outline.id == "outline")
        #expect(DocumentMode.allCases.count == 2)
    }

    @Test func parsedDocumentNextCitationSkipsBareMentionsAndWraps() {
        let doc = MarkdownParser.parse("A [Ps. 1:1](https://x).\n\nSee Ps. 2:2.\n\nC [Ps. 3:3](https://y).\n\nD")
        #expect(doc.nextCitation(fromSection: 1)?.displayShort == "Ps. 3:3")
        #expect(doc.nextCitation(fromSection: 3)?.displayShort == "Ps. 1:1")
        #expect(ParsedDocument.empty.nextCitation(fromSection: 0) == nil)
    }

    @Test func citationActivationAndID() {
        let bare = ScriptureCitation(
            rawText: "Ps. 37:7-9", bookCanonical: "psalms", chapter: 37, verseStart: 7,
            verseEnd: 9, displayShort: "Ps. 37:7-9"
        )
        #expect(bare.id == "psalms 37:7-9")
        #expect(!bare.isLinked)
        let url = URL(string: "https://example.com")
        let active = bare.activated(url: url)
        #expect(active.isLinked)
        #expect(active.url == url)
        #expect(!bare.isLinked)
    }

    @Test func talkLabelsAndPreview() {
        let talk = TalkFactory.talk(text: "<!-- note -->\n\n# Title\n\n- a\n\nBody", timeLimit: 900)
        #expect(talk.timeLimitLabel == "15 min")
        #expect(talk.previewLines(2).count <= 2)
        #expect(!talk.previewLines().isEmpty)
    }

    @Test func legacyTalkJSONDecodesAsLocalAndVisible() throws {
        let json = """
        {"id":"\(UUID().uuidString)","title":"Old","sourceText":"x","preferredMode":"script",
         "timeLimit":60,"createdAt":0,"lastOpenedAt":0}
        """
        let talk = try JSONDecoder().decode(Talk.self, from: Data(json.utf8))
        #expect(talk.source == .local)
        #expect(!talk.isHidden)
    }

    @Test func talkSourceAccessors() {
        #expect(!TalkSource.local.isVault)
        #expect(TalkSource.local.relativePath == nil)
        #expect(TalkSource.vault(relativePath: "a/b.md").relativePath == "a/b.md")
    }

    @Test func readingAnchorIsValueEqual() {
        #expect(ReadingAnchor(sectionIndex: 1, fraction: 0.5) == ReadingAnchor(sectionIndex: 1, fraction: 0.5))
        #expect(ReadingAnchor(sectionIndex: 1, fraction: 0.5) != ReadingAnchor(sectionIndex: 2, fraction: 0.5))
    }

    @Test func accessibilityIDsAreStableAndParameterised() {
        #expect(AXID.Library.root == "library.root")
        #expect(AXID.Library.card("abc") == "library.card.abc")
        #expect(AXID.Reader.paragraph(3) == "reader.paragraph.3")
        #expect(AXID.Reader.outlineRow(2) == "reader.outlineRow.2")
        #expect(AXID.Pacing.preset(30) == "sheet.pacing.preset.30")
        #expect(AXID.Text.root == "sheet.text.root")
        #expect(AXID.Import.create == "sheet.import.create")
        #expect(AXID.Edit.save == "sheet.edit.save")
    }
}

@MainActor
struct NoOpSpeechAndEngineTests {
    @Test func noOpSpeechSourceIsUnavailable() async throws {
        let source = NoOpSpeechSource()
        #expect(!source.isAvailable)
        #expect(await source.requestAuthorization() == false)
        try await source.start(localeIdentifier: "en-US", onWord: { _ in }, onLevel: { _ in }, onStatus: { _ in }, onError: { _ in })
        source.stop()
    }

    @Test func noOpAlignmentEngineNeverMoves() {
        let engine = NoOpAlignmentEngine()
        #expect(engine.currentGlobalIndex == -1)
        #expect(engine.consume(RecognizedWord(text: "hi", timestamp: 0)) == nil)
        #expect(engine.position(forGlobalIndex: 3) == nil)
        #expect(engine.position(forFractionalGlobalIndex: 3.5) == nil)
        engine.reset(to: 4)
        #expect(engine.currentGlobalIndex == -1)
    }
}

@MainActor
struct ProductionSeamTests {
    @Test func defaultDependenciesUseLiveImplementations() {
        let deps = ReaderDependencies.live
        #expect(deps.ticker is TimerTicker)
        #expect(deps.scheduler is MainQueueScheduler)
        #expect(deps.chromeHideDelay == ReaderDependencies.defaultChromeHideDelay)
        #expect(deps.alignmentFactory([]).currentGlobalIndex == -1)
    }

    @Test func timerTickerDeliversTicksUntilCancelled() async {
        let ticker = TimerTicker()
        var received = 0
        let handle = await withCheckedContinuation { (continuation: CheckedContinuation<Cancellable, Never>) in
            var resumed = false
            var token: Cancellable?
            token = ticker.start(interval: 0.001) { dt in
                received += 1
                #expect(dt == 0.001)
                if !resumed, received >= 2, let token {
                    resumed = true
                    continuation.resume(returning: token)
                }
            }
        }
        handle.cancel()
        let frozen = received
        #expect(frozen >= 2)
    }

    @Test func mainQueueSchedulerRunsWorkOnce() async {
        let scheduler = MainQueueScheduler()
        var handle: Cancellable?
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            // The handle must stay alive: dropping an AnyCancellable cancels the work.
            handle = scheduler.schedule(after: 0.001) { continuation.resume() }
        }
        handle?.cancel()
    }

    @Test func mainQueueSchedulerCancelPreventsWork() async {
        let scheduler = MainQueueScheduler()
        var ran = false
        let handle = scheduler.schedule(after: 0.001) { ran = true }
        handle.cancel()
        // A later item on the same serial queue runs after the cancelled one's deadline.
        var later: Cancellable?
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            later = scheduler.schedule(after: 0.05) { continuation.resume() }
        }
        later?.cancel()
        #expect(!ran)
    }
}
