import SwiftUI

@main
struct CindruneApp: App {
    @State private var cindruneLinkReady: Bool? = nil
    private let cindruneSourceLink = "https://cindrune.org/click.php"
    private let cindruneCheckDomain = "termsfeed.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = cindruneLinkReady {
                    if ready {
                        // Respect the top safe area: the frame does it, not
                        // contentInset. The opaque band keeps the notch clean.
                        CindruneWebPanel(urlString: cindruneSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                    }
                } else {
                    CindruneLoadingScreen()
                        .onAppear { checkLink() }
                }
            }
        }
    }

    private func checkLink() {
        guard let url = URL(string: cindruneSourceLink) else {
            cindruneLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = CindruneRedirectTracker(checkDomain: cindruneCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    cindruneLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(cindruneCheckDomain) {
                    cindruneLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(cindruneCheckDomain) {
                    cindruneLinkReady = false; return
                }
                if error != nil {
                    cindruneLinkReady = false; return
                }
                cindruneLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if cindruneLinkReady == nil { cindruneLinkReady = false }
        }
    }
}

/// Watches the redirect chain without ever stopping it, and remembers both the
/// resolved address and whether the check domain appeared anywhere along the way.
final class CindruneRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) { self.checkDomain = checkDomain }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
