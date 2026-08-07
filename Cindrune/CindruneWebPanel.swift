import SwiftUI
import WebKit

/// The panel that shows remote content.
///
/// The top safe area is respected by the *frame* the panel is given, not by
/// contentInset: `.never` always draws under the notch, and `.automatic` only
/// insets scrollable content. The settings below are belt-and-suspenders for
/// the sheet case, and keep the safe-area band opaque so it never flashes white.
struct CindruneWebPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.isOpaque = true
        webView.backgroundColor = .black
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    /// Must stay empty. Loading here would reload on every SwiftUI re-render.
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
