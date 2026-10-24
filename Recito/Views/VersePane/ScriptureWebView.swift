//
//  ScriptureWebView.swift
//  Recito
//
//  A locked-down WKWebView for the verse pane: no persisted cookies or
//  history, no link previews, no swipe navigation, every navigation run
//  through `ScriptureWebPolicy`, and every subresource run through a content
//  rule list (`ScriptureContentRules`). It reports load progress as reducer
//  events and loads only once the rule list is installed.
//

import SwiftUI
import WebKit

struct ScriptureWebView: UIViewRepresentable {
    let url: URL
    let onEvent: (VersePaneState.Event) -> Void
    let openExternally: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: Self.makeConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        // Match the pane so there is no white flash in dark mode while loading.
        webView.isOpaque = false
        webView.backgroundColor = .secondarySystemGroupedBackground
        webView.scrollView.backgroundColor = .secondarySystemGroupedBackground
        #if DEBUG
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        #endif
        context.coordinator.load(url, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.load(url, in: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }

    private static func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.dataDetectorTypes = []
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        return configuration
    }
}

extension ScriptureWebView {
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: ScriptureWebView
        private var loadedURL: URL?
        private var rulesResolved = false
        private var rulesRequested = false
        private var reloadBudget = WebReloadBudget()

        init(parent: ScriptureWebView) {
            self.parent = parent
        }

        /// Loads only when the requested URL actually changed, and only after
        /// the content rules are installed (or failed to compile, in which
        /// case navigation policy alone applies).
        func load(_ url: URL, in webView: WKWebView) {
            guard url != loadedURL else { return }
            loadedURL = url
            reloadBudget = WebReloadBudget()
            if rulesResolved {
                webView.load(URLRequest(url: url))
            } else {
                installRules(in: webView)
            }
        }

        private func installRules(in webView: WKWebView) {
            guard !rulesRequested else { return }
            rulesRequested = true
            let controller = webView.configuration.userContentController
            Task { [weak self, weak webView] in
                await ScriptureContentRules.install(into: controller)
                guard let self, let webView else { return }
                self.rulesResolved = true
                if let url = self.loadedURL { webView.load(URLRequest(url: url)) }
            }
        }

        // MARK: Policy

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            // A nil target frame is a new-window request; treat it as top level.
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            let isUserInitiated = navigationAction.navigationType == .linkActivated
            switch ScriptureWebPolicy.decision(
                for: url, isMainFrame: isMainFrame, isUserInitiated: isUserInitiated
            ) {
            case .allow:
                decisionHandler(.allow)
            case .openExternally:
                decisionHandler(.cancel)
                parent.openExternally(url)
            case .cancel:
                decisionHandler(.cancel)
                if isMainFrame { parent.onEvent(.failed(.blocked)) }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            // Anything the web view can't render would otherwise become a
            // download or a blank page.
            guard navigationResponse.canShowMIMEType else {
                decisionHandler(.cancel)
                if navigationResponse.isForMainFrame { parent.onEvent(.failed(.blocked)) }
                return
            }
            if navigationResponse.isForMainFrame,
               let http = navigationResponse.response as? HTTPURLResponse,
               let failure = VersePaneFailure.classify(httpStatus: http.statusCode) {
                decisionHandler(.cancel)
                parent.onEvent(.failed(failure))
                return
            }
            decisionHandler(.allow)
        }

        // MARK: Progress

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.onEvent(.startedLoading)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onEvent(.finishedLoading)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            report(error)
        }

        /// The web content process died (memory pressure). Reload the verse a
        /// couple of times, then show an error instead of looping.
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            guard let url = loadedURL, let next = reloadBudget.consuming() else {
                parent.onEvent(.failed(.other))
                return
            }
            reloadBudget = next
            webView.load(URLRequest(url: url))
        }

        private func report(_ error: Error) {
            guard let failure = VersePaneFailure.classify(error) else { return }
            parent.onEvent(.failed(failure))
        }

        // MARK: New windows

        /// `target="_blank"` links: an allowed page replaces the current one;
        /// everything else was already routed by the action policy above.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url,
               ScriptureWebPolicy.decision(for: url, isMainFrame: true, isUserInitiated: false) == .allow {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
