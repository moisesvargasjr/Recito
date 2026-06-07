//
//  BibleBookCatalog.swift
//  Recito
//
//  Bilingual (English + Spanish / Reina-Valera) Bible book table that drives
//  scripture detection. Recognizing an explicit book token is what lets the
//  detector accept "Ps. 37:7" / "Salmo 83:18" while rejecting bare number pairs
//  like the "12:30" on the timer.
//
//  The list is intentionally data, not logic — extend it freely.
//

import Foundation

struct BibleBook {
    /// Lowercase canonical key, e.g. "psalms".
    let canonical: String
    /// Compact chip label, e.g. "Ps.", "John", "2 Tim.".
    let displayShort: String
    /// All recognizable spellings (EN + ES, full names + abbreviations), as
    /// written. Normalization (accent-fold, lowercase, strip dots) happens in
    /// the detector, so entries here may keep their natural form.
    let names: [String]
}

enum BibleBookCatalog {
    static let books: [BibleBook] = [
        // — Pentateuch —
        BibleBook(canonical: "genesis", displayShort: "Gen.", names: ["Genesis", "Gen", "Génesis", "Gén"]),
        BibleBook(canonical: "exodus", displayShort: "Ex.", names: ["Exodus", "Ex", "Exo", "Éxodo", "Exodo", "Éx"]),
        BibleBook(canonical: "leviticus", displayShort: "Lev.", names: ["Leviticus", "Lev", "Levítico", "Levitico", "Lv"]),
        BibleBook(canonical: "numbers", displayShort: "Num.", names: ["Numbers", "Num", "Números", "Numeros", "Nm"]),
        BibleBook(canonical: "deuteronomy", displayShort: "Deut.", names: ["Deuteronomy", "Deut", "Deuteronomio", "Dt"]),
        // — History —
        BibleBook(canonical: "joshua", displayShort: "Josh.", names: ["Joshua", "Josh", "Josué", "Josue", "Jos"]),
        BibleBook(canonical: "judges", displayShort: "Judg.", names: ["Judges", "Judg", "Jueces", "Jue"]),
        BibleBook(canonical: "ruth", displayShort: "Ruth", names: ["Ruth", "Rut"]),
        BibleBook(canonical: "1samuel", displayShort: "1 Sam.", names: ["1 Samuel", "1 Sam", "1 Sm", "1 S"]),
        BibleBook(canonical: "2samuel", displayShort: "2 Sam.", names: ["2 Samuel", "2 Sam", "2 Sm", "2 S"]),
        BibleBook(canonical: "1kings", displayShort: "1 Ki.", names: ["1 Kings", "1 Ki", "1 Reyes", "1 Re", "1 R"]),
        BibleBook(canonical: "2kings", displayShort: "2 Ki.", names: ["2 Kings", "2 Ki", "2 Reyes", "2 Re", "2 R"]),
        BibleBook(canonical: "1chronicles", displayShort: "1 Chron.", names: ["1 Chronicles", "1 Chron", "1 Chr", "1 Crónicas", "1 Cronicas", "1 Cron", "1 Cr"]),
        BibleBook(canonical: "2chronicles", displayShort: "2 Chron.", names: ["2 Chronicles", "2 Chron", "2 Chr", "2 Crónicas", "2 Cronicas", "2 Cron", "2 Cr"]),
        BibleBook(canonical: "ezra", displayShort: "Ezra", names: ["Ezra", "Esdras", "Esd"]),
        BibleBook(canonical: "nehemiah", displayShort: "Neh.", names: ["Nehemiah", "Neh", "Nehemías", "Nehemias", "Ne"]),
        BibleBook(canonical: "esther", displayShort: "Est.", names: ["Esther", "Est", "Ester"]),
        // — Poetry / Wisdom —
        BibleBook(canonical: "job", displayShort: "Job", names: ["Job"]),
        BibleBook(canonical: "psalms", displayShort: "Ps.", names: ["Psalms", "Psalm", "Ps", "Psa", "Salmos", "Salmo", "Sal", "Sl"]),
        BibleBook(canonical: "proverbs", displayShort: "Prov.", names: ["Proverbs", "Prov", "Prv", "Proverbios", "Pr"]),
        BibleBook(canonical: "ecclesiastes", displayShort: "Eccl.", names: ["Ecclesiastes", "Eccl", "Ecc", "Eclesiastés", "Eclesiastes", "Ecl"]),
        BibleBook(canonical: "songofsolomon", displayShort: "Song", names: ["Song of Solomon", "Song of Songs", "Song", "Cantares", "Cantar de los Cantares", "Cant", "Cnt"]),
        // — Major Prophets —
        BibleBook(canonical: "isaiah", displayShort: "Isa.", names: ["Isaiah", "Isa", "Isaías", "Isaias", "Is"]),
        BibleBook(canonical: "jeremiah", displayShort: "Jer.", names: ["Jeremiah", "Jer", "Jeremías", "Jeremias", "Jr"]),
        BibleBook(canonical: "lamentations", displayShort: "Lam.", names: ["Lamentations", "Lam", "Lamentaciones", "Lm"]),
        BibleBook(canonical: "ezekiel", displayShort: "Ezek.", names: ["Ezekiel", "Ezek", "Eze", "Ezequiel", "Ez"]),
        BibleBook(canonical: "daniel", displayShort: "Dan.", names: ["Daniel", "Dan", "Dn"]),
        // — Minor Prophets —
        BibleBook(canonical: "hosea", displayShort: "Hos.", names: ["Hosea", "Hos", "Oseas", "Os"]),
        BibleBook(canonical: "joel", displayShort: "Joel", names: ["Joel", "Jl"]),
        BibleBook(canonical: "amos", displayShort: "Amos", names: ["Amos", "Am"]),
        BibleBook(canonical: "obadiah", displayShort: "Obad.", names: ["Obadiah", "Obad", "Abdías", "Abdias", "Abd"]),
        BibleBook(canonical: "jonah", displayShort: "Jonah", names: ["Jonah", "Jon", "Jonás", "Jonas"]),
        BibleBook(canonical: "micah", displayShort: "Mic.", names: ["Micah", "Mic", "Miqueas", "Miq"]),
        BibleBook(canonical: "nahum", displayShort: "Nah.", names: ["Nahum", "Nah", "Nahúm", "Nah"]),
        BibleBook(canonical: "habakkuk", displayShort: "Hab.", names: ["Habakkuk", "Hab", "Habacuc"]),
        BibleBook(canonical: "zephaniah", displayShort: "Zeph.", names: ["Zephaniah", "Zeph", "Sofonías", "Sofonias", "Sof"]),
        BibleBook(canonical: "haggai", displayShort: "Hag.", names: ["Haggai", "Hag", "Hageo", "Hag"]),
        BibleBook(canonical: "zechariah", displayShort: "Zech.", names: ["Zechariah", "Zech", "Zac", "Zacarías", "Zacarias"]),
        BibleBook(canonical: "malachi", displayShort: "Mal.", names: ["Malachi", "Mal", "Malaquías", "Malaquias"]),
        // — Gospels / Acts —
        BibleBook(canonical: "matthew", displayShort: "Matt.", names: ["Matthew", "Matt", "Mat", "Mateo", "Mt"]),
        BibleBook(canonical: "mark", displayShort: "Mark", names: ["Mark", "Mar", "Marcos", "Mr", "Mc"]),
        BibleBook(canonical: "luke", displayShort: "Luke", names: ["Luke", "Luk", "Lucas", "Lc", "Lu"]),
        BibleBook(canonical: "john", displayShort: "John", names: ["John", "Joh", "Jhn", "Juan", "Jn"]),
        BibleBook(canonical: "acts", displayShort: "Acts", names: ["Acts", "Act", "Hechos", "Hch", "Hech"]),
        // — Pauline Epistles —
        BibleBook(canonical: "romans", displayShort: "Rom.", names: ["Romans", "Rom", "Romanos", "Ro", "Rm"]),
        BibleBook(canonical: "1corinthians", displayShort: "1 Cor.", names: ["1 Corinthians", "1 Cor", "1 Co", "1 Corintios"]),
        BibleBook(canonical: "2corinthians", displayShort: "2 Cor.", names: ["2 Corinthians", "2 Cor", "2 Co", "2 Corintios"]),
        BibleBook(canonical: "galatians", displayShort: "Gal.", names: ["Galatians", "Gal", "Gálatas", "Galatas", "Ga"]),
        BibleBook(canonical: "ephesians", displayShort: "Eph.", names: ["Ephesians", "Eph", "Efesios", "Ef"]),
        BibleBook(canonical: "philippians", displayShort: "Phil.", names: ["Philippians", "Phil", "Php", "Filipenses", "Fil", "Flp"]),
        BibleBook(canonical: "colossians", displayShort: "Col.", names: ["Colossians", "Col", "Colosenses"]),
        BibleBook(canonical: "1thessalonians", displayShort: "1 Thess.", names: ["1 Thessalonians", "1 Thess", "1 Th", "1 Tesalonicenses", "1 Tes", "1 Ts"]),
        BibleBook(canonical: "2thessalonians", displayShort: "2 Thess.", names: ["2 Thessalonians", "2 Thess", "2 Th", "2 Tesalonicenses", "2 Tes", "2 Ts"]),
        BibleBook(canonical: "1timothy", displayShort: "1 Tim.", names: ["1 Timothy", "1 Tim", "1 Ti", "1 Timoteo", "1 Tm"]),
        BibleBook(canonical: "2timothy", displayShort: "2 Tim.", names: ["2 Timothy", "2 Tim", "2 Ti", "2 Timoteo", "2 Tm"]),
        BibleBook(canonical: "titus", displayShort: "Titus", names: ["Titus", "Tit", "Tito", "Tit"]),
        BibleBook(canonical: "philemon", displayShort: "Philem.", names: ["Philemon", "Philem", "Phlm", "Filemón", "Filemon", "Flm"]),
        // — General Epistles / Revelation —
        BibleBook(canonical: "hebrews", displayShort: "Heb.", names: ["Hebrews", "Heb", "Hebreos"]),
        BibleBook(canonical: "james", displayShort: "Jas.", names: ["James", "Jas", "Jam", "Santiago", "Stg", "Sant"]),
        BibleBook(canonical: "1peter", displayShort: "1 Pet.", names: ["1 Peter", "1 Pet", "1 Pe", "1 Pedro", "1 P"]),
        BibleBook(canonical: "2peter", displayShort: "2 Pet.", names: ["2 Peter", "2 Pet", "2 Pe", "2 Pedro", "2 P"]),
        BibleBook(canonical: "1john", displayShort: "1 John", names: ["1 John", "1 Joh", "1 Jn", "1 Juan"]),
        BibleBook(canonical: "2john", displayShort: "2 John", names: ["2 John", "2 Joh", "2 Jn", "2 Juan"]),
        BibleBook(canonical: "3john", displayShort: "3 John", names: ["3 John", "3 Joh", "3 Jn", "3 Juan"]),
        BibleBook(canonical: "jude", displayShort: "Jude", names: ["Jude", "Judas", "Jud"]),
        BibleBook(canonical: "revelation", displayShort: "Rev.", names: ["Revelation", "Rev", "Apocalipsis", "Apoc", "Ap"]),
    ]

    /// Normalize a token for matching: lowercase, accent-fold, strip periods,
    /// and collapse internal whitespace.
    static func normalize(_ token: String) -> String {
        token
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .split(whereSeparator: { $0 == " " || $0 == "\t" })
            .joined(separator: " ")
    }

    /// Lookup from normalized spelling → book.
    static let normalizedLookup: [String: BibleBook] = {
        var map: [String: BibleBook] = [:]
        for book in books {
            for name in book.names {
                map[normalize(name)] = book
            }
        }
        return map
    }()

    /// Canonical book number (1 = Genesis … 66 = Revelation), from list order.
    static func bookNumber(for canonical: String) -> Int? {
        guard let index = books.firstIndex(where: { $0.canonical == canonical }) else { return nil }
        return index + 1
    }
}
