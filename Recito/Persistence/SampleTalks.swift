//
//  SampleTalks.swift
//  Recito
//
//  First-run sample library mirroring the design mock data, with enough real
//  content (prose, outline, a scripture cue) to exercise both readers.
//

import Foundation

enum SampleTalks {
    static var all: [Talk] {
        let now = Date()
        return [
            Talk(
                title: "The Value of Patience",
                sourceText: patienceScript,
                preferredMode: .script,
                timeLimit: 30 * 60,
                createdAt: now.addingTimeInterval(-86_400),
                lastOpenedAt: now
            ),
            Talk(
                title: "Building Real Faith",
                sourceText: faithOutline,
                preferredMode: .outline,
                timeLimit: 45 * 60,
                createdAt: now.addingTimeInterval(-200_000),
                lastOpenedAt: now.addingTimeInterval(-200_000)
            ),
            Talk(
                title: "Lessons From Creation",
                sourceText: creationScript,
                preferredMode: .script,
                timeLimit: 15 * 60,
                createdAt: now.addingTimeInterval(-300_000),
                lastOpenedAt: now.addingTimeInterval(-300_000)
            ),
            Talk(
                title: "Why Honesty Matters",
                sourceText: honestyOutline,
                preferredMode: .outline,
                timeLimit: 10 * 60,
                createdAt: now.addingTimeInterval(-400_000),
                lastOpenedAt: now.addingTimeInterval(-400_000)
            ),
            Talk(
                title: "A Hope For the Future",
                sourceText: hopeScript,
                preferredMode: .script,
                timeLimit: 30 * 60,
                createdAt: now.addingTimeInterval(-500_000),
                lastOpenedAt: now.addingTimeInterval(-500_000)
            ),
        ]
    }

    private static let patienceScript = """
    Few qualities are tested as often as patience, yet few of us are taught how to build it.

    We tend to think of patience as simply waiting — but that picture is far too small.

    Real patience is active. It is the steady choice to keep doing what is right while the result is still out of sight. As [Ps. 37:7](https://www.jw.org/finder?wtlocale=S&prefer=lang&pub=nwtsty&bible=19037007) reminds us, we wait on better days while we keep doing good.

    Think of a farmer. He cannot rush the harvest, yet no one would call his season idle.

    The same is true for us. The work we do today may not show its fruit for a long time, and that is exactly when patience matters most.
    """

    private static let faithOutline = """
    # Building Real Faith

    1. Faith is built, not inherited
       - It grows through small daily decisions
       - [Heb. 11:1](https://www.jw.org/finder?wtlocale=S&prefer=lang&pub=nwtsty&bible=58011001) — the assured expectation of things hoped for
    2. Faith is tested by waiting
       - The example of Abraham
    3. Faith produces action
    4. Close: faith that holds under pressure
    """

    private static let creationScript = """
    When we look closely at the natural world, a pattern of care becomes impossible to ignore.

    From the smallest seed to the largest star, design speaks where words cannot.

    Creation invites us to slow down and pay attention to what we so often rush past.
    """

    private static let honestyOutline = """
    1. Honesty costs something in the moment
       - But it buys trust that lasts
    2. Small compromises grow
    3. Honesty with ourselves comes first
    4. Close: the freedom of a clear conscience
    """

    private static let hopeScript = """
    Everyone carries some picture of tomorrow — whether they say so or not.

    Hope is not wishful thinking; it is confidence built on good reasons.

    When the present feels heavy, a well-founded hope changes how we carry the weight.
    """
}
