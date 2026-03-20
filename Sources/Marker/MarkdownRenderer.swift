import Foundation

@MainActor
@Observable
final class MarkdownRenderer {
    private var templateHTML: String?
    private var resourcesBaseURL: URL?

    private func loadTemplate() -> String {
        if let cached = templateHTML { return cached }

        guard let url = Bundle.module.url(forResource: "template", withExtension: "html", subdirectory: "Resources") else {
            return "<html><body><p>Error: template.html not found in bundle</p></body></html>"
        }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return "<html><body><p>Error: could not read template.html</p></body></html>"
        }

        // Resources base is the directory containing template.html
        resourcesBaseURL = url.deletingLastPathComponent()
        templateHTML = content
        return content
    }

    /// Returns (htmlFileURL, allowReadAccessURL) for loading via WKWebView.loadFileURL
    func render(fileAt url: URL) -> (html: URL, allowAccess: URL)? {
        guard let markdown = try? String(contentsOf: url, encoding: .utf8) else { return nil }

        let escaped = escapeForJS(markdown)
        let template = loadTemplate()

        let base = resourcesBaseURL?.absoluteString ?? ""
        var html = template.replacingOccurrences(of: "__MARKDOWN_CONTENT__", with: escaped)
        html = html.replacingOccurrences(of: "__RESOURCES_BASE__", with: base)

        // Write to temp file so WKWebView can load via file:// with proper access
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("Marker", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let tempFile = tempDir.appendingPathComponent("preview.html")
        try? html.write(to: tempFile, atomically: true, encoding: .utf8)

        // Grant read access to / so WKWebView can reach the temp file, bundle resources, and markdown images
        return (html: tempFile, allowAccess: URL(fileURLWithPath: "/"))
    }

    private func escapeForJS(_ string: String) -> String {
        var result = "\""
        for char in string {
            switch char {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.append(char)
            }
        }
        result += "\""
        return result
    }
}
