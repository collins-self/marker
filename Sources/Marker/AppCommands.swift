import SwiftUI
import UniformTypeIdentifiers

struct AppCommands: Commands {
    @Binding var fileURL: URL?

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                openFile()
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()
        }

        CommandGroup(replacing: .undoRedo) {}
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            UTType(filenameExtension: "mdx") ?? .plainText,
            UTType(filenameExtension: "mdown") ?? .plainText,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a Markdown file"

        if panel.runModal() == .OK, let url = panel.url {
            fileURL = url
        }
    }
}
