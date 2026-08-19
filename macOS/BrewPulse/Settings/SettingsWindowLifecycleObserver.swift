import AppKit
import SwiftUI

struct SettingsWindowLifecycleObserver: NSViewRepresentable {
    let windowDidOpen: () -> Void
    let windowDidClose: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            windowDidOpen: windowDidOpen,
            windowDidClose: windowDidClose
        )
    }

    func makeNSView(context: Context) -> WindowAttachmentView {
        let view = WindowAttachmentView()
        view.windowDidChange = context.coordinator.observe
        return view
    }

    func updateNSView(_ nsView: WindowAttachmentView, context: Context) {
        context.coordinator.windowDidOpen = windowDidOpen
        context.coordinator.windowDidClose = windowDidClose
    }

    static func dismantleNSView(
        _ nsView: WindowAttachmentView,
        coordinator: Coordinator
    ) {
        nsView.windowDidChange = nil
        coordinator.stopObserving(notifyClosed: true)
    }
}

extension SettingsWindowLifecycleObserver {
    final class Coordinator: NSObject {
        var windowDidOpen: () -> Void
        var windowDidClose: () -> Void

        private weak var observedWindow: NSWindow?

        init(
            windowDidOpen: @escaping () -> Void,
            windowDidClose: @escaping () -> Void
        ) {
            self.windowDidOpen = windowDidOpen
            self.windowDidClose = windowDidClose
        }

        func observe(_ window: NSWindow?) {
            guard observedWindow !== window else { return }

            stopObserving(notifyClosed: observedWindow != nil)
            observedWindow = window

            guard let window else { return }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowWillClose),
                name: NSWindow.willCloseNotification,
                object: window
            )
            windowDidOpen()
        }

        func stopObserving(notifyClosed: Bool) {
            guard let observedWindow else { return }

            NotificationCenter.default.removeObserver(
                self,
                name: NSWindow.willCloseNotification,
                object: observedWindow
            )
            self.observedWindow = nil

            if notifyClosed {
                windowDidClose()
            }
        }

        @objc private func windowWillClose() {
            stopObserving(notifyClosed: true)
        }
    }
}

extension SettingsWindowLifecycleObserver {
    final class WindowAttachmentView: NSView {
        var windowDidChange: ((NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            windowDidChange?(window)
        }
    }
}
