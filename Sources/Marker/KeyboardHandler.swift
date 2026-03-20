import AppKit
import WebKit

final class KeyboardHandler: @unchecked Sendable {
    private var monitor: Any?
    private var gPending = false
    weak var webView: WKWebView?

    func install(webView: WKWebView) {
        self.webView = webView
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let wv = self.webView else { return event }

            // Don't capture if a text field has focus (nonisolated is safe — event monitors run on main thread)
            nonisolated(unsafe) let ev = event
            let isTextInput = MainActor.assumeIsolated {
                ev.window?.firstResponder is NSTextView
            }
            if isTextInput { return event }

            // Ignore events with command modifier (let system handle Cmd+O, Cmd+W, etc.)
            if event.modifierFlags.contains(.command) { return event }

            guard let chars = event.charactersIgnoringModifiers else { return event }

            switch chars {
            case "j":
                MainActor.assumeIsolated {
                    wv.evaluateJavaScript("window.scrollBy({top: 60, behavior: 'smooth'})")
                }
                return nil
            case "k":
                MainActor.assumeIsolated {
                    wv.evaluateJavaScript("window.scrollBy({top: -60, behavior: 'smooth'})")
                }
                return nil
            case "d":
                MainActor.assumeIsolated {
                    wv.evaluateJavaScript("window.scrollBy({top: window.innerHeight/2, behavior: 'smooth'})")
                }
                return nil
            case "u":
                MainActor.assumeIsolated {
                    wv.evaluateJavaScript("window.scrollBy({top: -window.innerHeight/2, behavior: 'smooth'})")
                }
                return nil
            case "G":
                if !self.gPending {
                    MainActor.assumeIsolated {
                        wv.evaluateJavaScript("window.scrollTo({top: document.body.scrollHeight, behavior: 'smooth'})")
                    }
                }
                self.gPending = false
                return nil
            case "g":
                if self.gPending {
                    MainActor.assumeIsolated {
                        wv.evaluateJavaScript("window.scrollTo({top: 0, behavior: 'smooth'})")
                    }
                    self.gPending = false
                } else {
                    self.gPending = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.gPending = false
                    }
                }
                return nil
            case " ":
                let direction = event.modifierFlags.contains(.shift) ? "-window.innerHeight" : "window.innerHeight"
                MainActor.assumeIsolated {
                    wv.evaluateJavaScript("window.scrollBy({top: \(direction), behavior: 'smooth'})")
                }
                return nil
            default:
                return event
            }
        }
    }

    func uninstall() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
