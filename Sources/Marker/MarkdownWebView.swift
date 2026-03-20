import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let fileURL: URL       // temp HTML file
    let allowAccess: URL   // directory to grant file:// access to
    var onFileDrop: ((URL) -> Void)?

    func makeNSView(context: Context) -> MarkerWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = MarkerWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = true
        webView.onFileDrop = onFileDrop

        context.coordinator.webView = webView
        context.coordinator.keyboardHandler.install(webView: webView)

        webView.loadFileURL(fileURL, allowingReadAccessTo: allowAccess)
        context.coordinator.currentFile = fileURL.absoluteString

        return webView
    }

    func updateNSView(_ webView: MarkerWebView, context: Context) {
        webView.onFileDrop = onFileDrop

        let key = fileURL.absoluteString + "?\(fileURL.contentModificationDate)"
        if context.coordinator.currentFile != key {
            context.coordinator.currentFile = key
            webView.loadFileURL(fileURL, allowingReadAccessTo: allowAccess)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    class Coordinator {
        var webView: WKWebView?
        var currentFile: String = ""
        let keyboardHandler = KeyboardHandler()

        deinit {
            keyboardHandler.uninstall()
        }
    }
}

private extension URL {
    var contentModificationDate: TimeInterval {
        (try? resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate?.timeIntervalSince1970) ?? 0
    }
}

// WKWebView subclass that intercepts .md file drops
class MarkerWebView: WKWebView {
    var onFileDrop: ((URL) -> Void)?
    private static let validExtensions: Set<String> = ["md", "markdown", "mdx", "mdown"]

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if extractMarkdownURL(from: sender) != nil {
            return .copy
        }
        return super.draggingEntered(sender)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        if let url = extractMarkdownURL(from: sender) {
            DispatchQueue.main.async { [weak self] in
                self?.onFileDrop?(url)
            }
            return true
        }
        return super.performDragOperation(sender)
    }

    private func extractMarkdownURL(from info: any NSDraggingInfo) -> URL? {
        guard let items = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], let url = items.first else { return nil }
        guard Self.validExtensions.contains(url.pathExtension.lowercased()) else { return nil }
        return url
    }
}
