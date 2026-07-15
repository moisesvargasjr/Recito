# Recito

A teleprompter that listens. Recito is a native iOS/iPadOS app for public speakers, lecturers, and presenters who deliver prepared talks: import your script or outline, set a time limit, and read. In voice-follow mode the app tracks where you are in your script with on-device speech recognition and keeps the display in step with you — hands-free, no pedal, no fixed scroll speed.

iPad-first, iPhone supported. SwiftUI, no backend, no accounts, no third-party dependencies.

## How voice-follow works

The interesting part of Recito is the alignment pipeline: turning a noisy, lagging stream of recognized words into a smooth, trustworthy scroll position.

### 1. Speech sources (`Recito/Speech/`)

Recognition is abstracted behind a `SpeechSource` protocol with a capability ladder:

- **Tier A — iOS 26+:** `SpeechAnalyzer` + `SpeechTranscriber`, configured for volatile/fast results (lowest-latency live output; accuracy of intermediate guesses doesn't matter because positions re-confirm as finals arrive). It handles long-form audio without finalizing at pauses, downloads its language model once through the system asset catalog, and bounds the audio hand-off buffer to about two seconds so a recognizer that falls behind drops stale audio instead of accumulating memory over a long talk.
- **Tier B — earlier iOS:** `SFSpeechRecognizer` + `AVAudioEngine` with on-device recognition where the device supports it. Since `SFSpeechRecognizer` finalizes after pauses and around the one-minute mark, the audio tap stays alive and the recognition task is transparently restarted for continuous listening.
- **Tier C:** devices without usable recognition get a no-op source; the app is fully functional as a timed teleprompter and simply doesn't offer voice-follow.

### 2. Alignment engine (`ScriptAlignmentEngine`)

Pure logic, recognizer-agnostic, fully unit-tested. The script is tokenized into normalized words (lowercased, diacritics folded, punctuation stripped) tagged with their section and position; headings are excluded because they aren't spoken. The engine maintains a cursor — the last confidently matched token — and consumes one recognized word at a time:

1. If the word matches the expected next token, advance one step.
2. If it confirms a pending forward-jump candidate (matches the word right after it), commit the jump.
3. If it matches somewhere in a forward window, hold it as a candidate — a single stray or misheard word can never fling the cursor; a second consecutive word must confirm.

Matching is fuzzy (normalized Levenshtein similarity, threshold 0.72) so "patients" still matches "patience", but short words must match exactly to keep stopwords like "is" from causing false jumps. The cursor never moves backward, and it holds position through off-script asides. After a streak of misses the search window widens (16 → 90 words) to re-acquire a speaker who has run ahead. A double-tap in the reader manually re-seats the cursor if recognition falls behind.

### 3. Predictive scrolling (`ReaderViewModel`)

Recognition arrives in bursts and lags real speech by a second or two, so the display never scrolls to raw recognition output. A 60 Hz ticker glides a predicted reading position forward at the speaker's measured pace (a live exponentially-weighted words-per-second estimate), then eases it toward the recognized anchor with a ~0.28 s time constant — bursts of confirmed words can't yank the view, and the glide passes through every paragraph instead of skipping short ones. The prediction is capped at 18 words of lead over the recognizer and freezes when recognition stalls for more than 1.2 s (the speaker paused). The result is scrolling that feels continuous while staying anchored to what was actually said.

## Features

- **Two reading modes from one source.** A single Markdown/plain-text import is parsed into blocks once, then materialized as both models: **Script mode** (full prose, paragraph sections) and **Outline mode** (headings and top-level bullets as enlarged numbered points, indented items as sub-bullets). Switch anytime; a pure-prose document falls back to one outline point per paragraph. Mode is auto-detected on import.
- **Voice-follow** (script mode) in Spanish (es-ES, es-MX) and English (en-US, en-GB), selectable per the settings sheet.
- **Time-paced auto-scroll.** Scroll velocity is derived from the talk's time limit so pressing play finishes exactly on time, with a 0.5–1.5× speed slider.
- **Pacing feedback.** A slim pace bar compares the fraction of script covered against the fraction of time elapsed — behind / on pace / ahead — plus a projected finish time. Time-limit presets are configurable (10/15/30/45/60 min).
- **Preview without losing your place.** The playback position (highlighted, drives pacing) and the view position are decoupled: drag to peek ahead, and the view glides back to the live spot after a few seconds. Double-tap a paragraph to move playback there.
- **Citation cues.** Inline citations are detected in the text; ones written as Markdown links surface as an upcoming cue chip, and when the scroll reaches one, auto-scroll holds (the pace clock keeps running) so you can read the reference aloud before resuming. An optional setting opens the linked reference in its own app as you approach it.
- **Library.** Talks persist as a single JSON file in Application Support (atomic, off-main writes); search, most-recent-first sorting, and a Continue badge on the last-opened talk.
- **Import.** Paste text or bring in `.md`/`.txt` files via the Files picker; the title is derived from the first line.
- **Reading display controls.** System or serif typeface, text size, line spacing, bold, light/dark/system theme, and keep-awake — all live-updating from the Aa sheet.

## Privacy

All speech processing happens on the device. There is no cloud speech API, no backend, no account, and no analytics; the microphone and speech-recognition permission strings say exactly that. The only download is the system's on-device language model, fetched once by iOS itself. Talks live in the app's local container.

## Tech stack

- **UI:** SwiftUI (iOS/iPadOS 16.0+ deployment target), width-adaptive reader layouts for iPad and iPhone
- **Speech:** Speech framework — `SpeechAnalyzer`/`SpeechTranscriber` on iOS 26+, `SFSpeechRecognizer` fallback — with `AVAudioEngine` capture
- **State:** `ObservableObject` view models + Combine
- **Persistence:** `Codable` JSON store, `UserDefaults` for display settings
- **Testing:** Swift Testing (`@Test`/`#expect`)
- **Dependencies:** none

### Project layout

```
Recito/
  App/            Root navigation
  Models/         Talk, ParsedDocument, sections, outline nodes, pacing
  Parsing/        MarkdownParser → blocks; ScriptSegmenter + OutlineBuilder
  Speech/         SpeechSource protocol, Tier A/B/C sources, alignment engine
  ViewModels/     Reader (playback, voice-follow, pacing), library, import
  Views/          Library, script/outline readers, sheets, components
  Persistence/    JSON talk store, display settings
  DesignSystem/   Theme, typography, spacing, shadows
  Utilities/      Citation detection/linking, keep-awake, time formatting
```

## Building and running

Open `Recito.xcodeproj` in a recent Xcode (the speech layer compiles against the iOS 26 SDK, with an iOS 27-gated optimization) and run the `Recito` scheme on an iPad or iPhone. There are no packages to resolve and no configuration steps.

Voice-follow requires a device with on-device speech recognition and grants for both microphone and speech-recognition permissions; everything else works everywhere, including simulators.

## Testing

Unit tests use Swift Testing and cover the pure-logic core:

- `MarkdownParserTests` — one source producing both reading models (paragraph segmentation, headings, nested lists, prose fallback)
- `ScriptAlignmentEngineTests` — straight reading, section advancement, dropped words and filler, fuzzy misrecognition, off-script holds, single-stray-word immunity, confirmed forward jumps, no backward movement, stopword safety
- Citation detection tests — matching real citations without false positives on bare number pairs like a "12:30" time

Run them with Product → Test in Xcode, or:

```sh
xcodebuild test -project Recito.xcodeproj -scheme Recito \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'
```

UI test targets are scaffolded (`RecitoUITests`).
