import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @Binding var fileURL: URL?
    @State private var renderer = MarkdownRenderer()
    @State private var fileWatcher = FileWatcher()
    @State private var renderResult: (html: URL, allowAccess: URL)?
    @State private var renderVersion: Int = 0

    var body: some View {
        Group {
            if let result = renderResult {
                MarkdownWebView(fileURL: result.html, allowAccess: result.allowAccess) { url in
                    fileURL = url
                }
                .id(renderVersion)
            } else {
                DropZoneView { url in
                    fileURL = url
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: fileURL) { _, newURL in
            if let url = newURL {
                loadFile(url)
            }
        }
        .onAppear {
            if let url = fileURL {
                loadFile(url)
            }
        }
    }

    private func loadFile(_ url: URL) {
        renderResult = renderer.render(fileAt: url)
        renderVersion += 1

        fileWatcher.watch(url: url) { [renderer] in
            MainActor.assumeIsolated {
                renderResult = renderer.render(fileAt: url)
                renderVersion += 1
            }
        }
    }
}

// Native AppKit view for the empty state drop zone
struct DropZoneView: NSViewRepresentable {
    let onDrop: (URL) -> Void

    func makeNSView(context: Context) -> DropZoneNSView {
        let view = DropZoneNSView()
        view.onDrop = onDrop
        return view
    }

    func updateNSView(_ nsView: DropZoneNSView, context: Context) {
        nsView.onDrop = onDrop
    }
}

class DropZoneNSView: NSView {
    var onDrop: ((URL) -> Void)?
    private static let validExtensions: Set<String> = ["md", "markdown", "mdx", "mdown"]

    private let titleField: NSTextField = {
        let field = NSTextField(labelWithString: "Marker")
        field.font = NSFont.systemFont(ofSize: 32, weight: .light)
        field.textColor = NSColor.white.withAlphaComponent(0.6)
        field.alignment = .center
        return field
    }()

    private let subtitleField: NSTextField = {
        let field = NSTextField(labelWithString: "Drop a .md file or press \u{2318}O")
        field.font = NSFont.systemFont(ofSize: 14)
        field.textColor = NSColor.white.withAlphaComponent(0.3)
        field.alignment = .center
        return field
    }()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 0.102, green: 0.102, blue: 0.180, alpha: 1.0).cgColor

        let stack = NSStackView(views: [titleField, subtitleField])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard extractURL(from: sender) != nil else { return [] }
        return .copy
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let url = extractURL(from: sender) else { return false }
        DispatchQueue.main.async { [weak self] in
            self?.onDrop?(url)
        }
        return true
    }

    private func extractURL(from info: any NSDraggingInfo) -> URL? {
        guard let items = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], let url = items.first else { return nil }
        guard Self.validExtensions.contains(url.pathExtension.lowercased()) else { return nil }
        return url
    }
}
