//
//  VaultNotesParsingTests.swift
//  RecitoTests
//
//  Vault notes carry material that is *about* the talk — frontmatter and an
//  editorial blockquote. It must not end up under the speaker's eyes.
//

import Testing
@testable import Recito

struct VaultNotesParsingTests {

    @Test func leadingEditorialBlockquoteIsDropped() {
        let source = """
        > Source: Apple Notes · "181 - ¿Faltará menos de lo que usted cree?" · Migrated: 2026-04-15

        # 181 — ¿Faltará menos de lo que usted cree?

        En algunos meses celebraremos una ocasión muy especial.
        """
        let doc = MarkdownParser.parse(source)
        #expect(!doc.scriptSections.contains { $0.text.contains("Apple Notes") })
        #expect(doc.scriptSections.first?.text == "181 — ¿Faltará menos de lo que usted cree?")
    }

    @Test func multiParagraphLeadingNoteIsDropped() {
        let source = """
        > Rebalanced variant of the original script — same voice, cut to land closer to S-12 timing.
        >
        > Note (lint 2026-07-28): the original is not in the vault.

        # 12 — A Dios le importa

        Buenas tardes a todos.
        """
        let doc = MarkdownParser.parse(source)
        #expect(!doc.scriptSections.contains { $0.text.contains("Rebalanced") })
        #expect(!doc.scriptSections.contains { $0.text.contains("lint") })
        #expect(doc.scriptSections.first?.text == "12 — A Dios le importa")
    }

    @Test func yamlFrontmatterIsDropped() {
        let source = """
        ---
        type: synthesis
        status: active
        ---

        # Talk craft

        Body.
        """
        let doc = MarkdownParser.parse(source)
        #expect(!doc.scriptSections.contains { $0.text.contains("synthesis") })
        #expect(doc.scriptSections.first?.text == "Talk craft")
    }

    @Test func aQuotationLaterInTheTalkIsKept() {
        // Only the *leading* note is editorial. A quote in the body is content
        // the speaker may well read aloud — keep it, minus the marker.
        let source = """
        # El consejo

        Consideremos lo que dijo el apóstol.

        > Los consejos son como hongos.

        Y eso nos enseña algo.
        """
        let doc = MarkdownParser.parse(source)
        let texts = doc.scriptSections.map(\.text)
        #expect(texts.contains("Los consejos son como hongos."))
        #expect(!texts.contains { $0.hasPrefix(">") })
    }

    @Test func headingTitleIsNilForProseOnlyNotes() {
        #expect(MarkdownParser.headingTitle(from: "Hay un dicho que escuché.") == nil)
        #expect(MarkdownParser.headingTitle(from: "# A title\n\nbody") == "A title")
    }

    @Test func previewSkipsTheEditorialNote() {
        let talk = Talk(
            title: "t",
            sourceText: "> Source: Apple Notes · Migrated\n\n# Real title\n\nBody."
        )
        #expect(talk.previewLines().first == "Real title")
    }
}
