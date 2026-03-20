import Foundation

@MainActor
@Observable
final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    func watch(url: URL, onChange: @escaping @MainActor () -> Void) {
        stop()

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler {
            MainActor.assumeIsolated {
                let flags = source.data

                if flags.contains(.delete) || flags.contains(.rename) {
                    // File replaced (atomic save) — re-establish watch
                    self.watch(url: url, onChange: onChange)
                }
                onChange()
            }
        }

        source.setCancelHandler { [fd = fileDescriptor] in
            close(fd)
        }

        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
    }
}
