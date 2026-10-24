//
//  AppEnvironment.swift
//  Recito
//
//  Builds the app's long-lived objects from a LaunchConfiguration. Production
//  launches get the live store and dependencies. UI-test launches (DEBUG only)
//  get an isolated UserDefaults suite and a temp-directory library, optionally
//  wiped (`-reset`) and seeded from a fixture, so tests never touch real data.
//

import SwiftUI

enum AppEnvironment {
    static let uiTestSuiteName = "recito.uitest"
    static let talksFilename = "talks.json"

    static var defaultStorageRoot: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("recito-uitest", isDirectory: true)
    }

    /// `suiteName` / `storageRoot` are parameters so tests can isolate themselves.
    static func make(
        _ config: LaunchConfiguration,
        suiteName: String = uiTestSuiteName,
        storageRoot: URL = defaultStorageRoot
    ) -> (TalkStore, DisplaySettings, ReaderDependencies) {
        let deps = dependencies(for: config)
        #if DEBUG
        if config.isUITest {
            let (store, settings) = makeUITestState(config, suiteName: suiteName, storageRoot: storageRoot)
            return (store, settings, deps)
        }
        #endif
        return (TalkStore.live(), DisplaySettings(), deps)
    }

    /// Reader collaborators for this launch: live clocks, with the speech source
    /// and chrome delay chosen by the configuration.
    static func dependencies(for config: LaunchConfiguration) -> ReaderDependencies {
        var deps = ReaderDependencies.live
        deps.chromeHideDelay = config.chromeHideDelay
        switch config.speech {
        case .unavailable:
            deps.speechSourceFactory = { NoOpSpeechSource() }
        case .fake:
            #if DEBUG
            let words = config.fakeSpeechWords
            deps.speechSourceFactory = { FakeSpeechSource(script: words) }
            #endif
        case .live:
            break
        }
        return deps
    }

    #if DEBUG
    private static func makeUITestState(
        _ config: LaunchConfiguration,
        suiteName: String,
        storageRoot: URL
    ) -> (TalkStore, DisplaySettings) {
        let defaults = UserDefaults(suiteName: suiteName) ?? {
            assertionFailure("Could not open UI-test defaults suite \(suiteName)")
            return UserDefaults.standard
        }()
        if config.resetState {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: storageRoot)
        }
        let persistence = JSONTalkPersistence(directory: storageRoot, filename: talksFilename)
        let store = TalkStore(persistence: persistence, vault: VaultFolder(defaults: defaults))
        seedIfFirstRun(store, defaults: defaults, fixture: config.fixture ?? .samples)

        let settings = DisplaySettings(defaults: defaults)
        if let theme = config.theme { settings.theme = theme }
        return (store, settings)
    }

    /// Seed once per state: later launches without `-reset` keep what the test
    /// created, and an `empty` fixture is not refilled with samples.
    private static func seedIfFirstRun(_ store: TalkStore, defaults: UserDefaults, fixture: UITestFixture) {
        guard !defaults.bool(forKey: TalkStore.didSeedKey) else { return }
        store.seed(fixture.talks)
        defaults.set(true, forKey: TalkStore.didSeedKey)
    }
    #endif
}

// MARK: - Environment plumbing

private struct ReaderDependenciesKey: EnvironmentKey {
    static var defaultValue: ReaderDependencies { .live }
}

private struct OpenTalkIDKey: EnvironmentKey {
    static var defaultValue: String? { nil }
}

extension EnvironmentValues {
    /// Clock/speech collaborators handed to each ReaderViewModel.
    var readerDependencies: ReaderDependencies {
        get { self[ReaderDependenciesKey.self] }
        set { self[ReaderDependenciesKey.self] = newValue }
    }

    /// `-openTalk` target: the library opens this talk's reader at launch.
    var openTalkID: String? {
        get { self[OpenTalkIDKey.self] }
        set { self[OpenTalkIDKey.self] = newValue }
    }
}
