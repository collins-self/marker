# Marker

A lightweight, keyboard-driven Markdown viewer for macOS. Dark theme, live reload, vim-style navigation, no Electron.

## Features

- **Live reload** -- watches the file for changes and re-renders instantly
- **Vim-style navigation** -- `j`/`k` scroll, `d`/`u` half-page, `gg`/`G` top/bottom, `Space`/`Shift+Space` page
- **Drag and drop** -- drop a `.md` file onto the window to open it
- **GFM** -- tables, task lists, strikethrough, autolinks
- **Code highlighting** -- syntax highlighting via highlight.js
- **Mermaid diagrams** -- fenced `mermaid` blocks render as diagrams
- **KaTeX math** -- inline `$...$` and display `$$...$$` math expressions
- **Native macOS** -- SwiftUI + WKWebView, ~1MB binary, no runtime dependencies

## Requirements

- macOS 14+
- Swift 6.0+ (Xcode 16+)

## Install

```sh
git clone https://github.com/collins-self/marker.git
cd Marker
make bundle
sudo make install
```

This installs `Marker.app` to `/Applications` and the `marker` CLI to `/usr/local/bin`.

## Usage

```sh
# Open a file
marker README.md

# Open the app (then drag a file or press Cmd+O)
marker
```

Or open `Marker.app` from Launchpad / Spotlight and drag a markdown file onto the window.

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `j` / `k` | Scroll down / up |
| `d` / `u` | Half-page down / up |
| `Space` / `Shift+Space` | Page down / up |
| `g g` | Scroll to top |
| `G` | Scroll to bottom |
| `Cmd+O` | Open file |
| `Cmd+W` | Close window |

## Development

```sh
# Debug build + run
make run

# Release build only
make release

# Build .app bundle (in .build/Marker.app)
make bundle

# Clean
make clean
```

## Supported File Types

`.md`, `.markdown`, `.mdx`, `.mdown`

## License

MIT
