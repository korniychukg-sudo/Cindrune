import SwiftUI

/// Resolves the launch address and decides what the app shows.
///
/// The work starts in `init`, not from a view lifecycle event: if `onAppear`
/// were ever missed the check would never run and no timeout would be armed,
/// leaving the loading screen up forever. Owned by a `@StateObject`, this runs
/// exactly once, the moment the scene is first built.
final class CindruneGate: ObservableObject {
    @Published private(set) var ready: Bool? = nil

    let sourceLink = "https://cindrune.org/click.php"
    private let checkDomain = "termsfeed.com"
    private let deadline: TimeInterval = 5

    init() {
        resolve()
    }

    private func settle(_ value: Bool) {
        guard ready == nil else { return }
        ready = value
    }

    private func resolve() {
        // Whatever else happens, the loading screen never outlives the deadline.
        DispatchQueue.main.asyncAfter(deadline: .now() + deadline) { [weak self] in
            self?.settle(false)
        }

        guard let url = URL(string: sourceLink) else {
            settle(false)
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = deadline
        let tracker = CindruneRedirectTracker(checkDomain: checkDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        let needle = checkDomain
        session.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if tracker.foundCheckDomain {
                    self.settle(false); return
                }
                if let resolved = tracker.resolvedURL?.absoluteString,
                   resolved.contains(needle) {
                    self.settle(false); return
                }
                if let http = response as? HTTPURLResponse,
                   let responded = http.url?.absoluteString,
                   responded.contains(needle) {
                    self.settle(false); return
                }
                if error != nil {
                    self.settle(false); return
                }
                self.settle(true)
            }
        }.resume()
        session.finishTasksAndInvalidate()
    }
}

@main
struct CindruneApp: App {
    @StateObject private var gate = CindruneGate()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = gate.ready {
                    if ready {
                        // The top safe area is respected by the frame, not by
                        // contentInset. The opaque band keeps the notch clean.
                        CindruneWebPanel(urlString: gate.sourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                    }
                } else {
                    CindruneLoadingScreen()
                }
            }
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
