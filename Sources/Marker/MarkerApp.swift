import SwiftUI
import WebKit

@main
struct MarkerApp: App {
    @State private var fileURL: URL?
    @State private var windowTitle: String = "Marker"

    init() {
        // Handle CLI args: marker /path/to/file.md
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = args[1]
            let url: URL
            if path.hasPrefix("/") {
                url = URL(fileURLWithPath: path)
            } else {
                let cwd = FileManager.default.currentDirectoryPath
                url = URL(fileURLWithPath: cwd).appendingPathComponent(path)
            }
            if FileManager.default.fileExists(atPath: url.path) {
                _fileURL = State(initialValue: url)
                _windowTitle = State(initialValue: url.lastPathComponent)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(fileURL: $fileURL)
                .frame(minWidth: 500, minHeight: 400)
                .background(Color(nsColor: NSColor(red: 0.102, green: 0.102, blue: 0.180, alpha: 1.0)))
                .onAppear {
                    NSApp.appearance = NSAppearance(named: .darkAqua)
                }
                .onOpenURL { url in
                    fileURL = url
                    windowTitle = url.lastPathComponent
                }
                .onChange(of: fileURL) { _, newURL in
                    if let url = newURL {
                        windowTitle = url.lastPathComponent
                    }
                }
                .navigationTitle(windowTitle)
        }
        .commands {
            AppCommands(fileURL: $fileURL)
        }
        .defaultSize(width: 800, height: 900)
    }
}
