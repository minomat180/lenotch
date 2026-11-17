import AppKit
import SwiftUI

/// Shows SwiftUI views in regular windows. The app runs as a menu bar
/// accessory, so windows have to be brought to the front explicitly.
final class WindowPresenter {
    private var windows: [String: NSWindow] = [:]
    private var closeObservers: [String: NSObjectProtocol] = [:]

    /// `floating` keeps the window above others, e.g. while permission prompts come and go.
    func show<Content: View>(id: String, title: String, floating: Bool = false, content: () -> Content) {
        if let window = windows[id] {
            bringToFront(window)
            return
        }
        // The window follows its content's size, but not through Auto Layout
        // (`sizingOptions = .preferredContentSize`): with the macOS 26 SDK every window
        // resize invalidates the hosting view's safe area corners, which asks for another
        // constraints pass, which resizes the window again, until AppKit throws (on
        // onboarding's Get Started). Resizing on the next run loop turn breaks the cycle.
        // Fork: also in fork/overlay/, so upstream syncs keep it; drop it there once
        // upstream fixes the crash.
        weak var sizedWindow: NSWindow?
        let controller = NSHostingController(rootView: content()
            .fixedSize()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                DispatchQueue.main.async { sizedWindow?.fitContent(size) }
            })
        controller.sizingOptions = []
        let window = NSWindow(contentViewController: controller)
        sizedWindow = window
        window.title = title
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.fitContent(controller.sizeThatFits(in: .zero))
        window.center()
        if floating { window.level = .floating }
        windows[id] = window
        // Release the window and its SwiftUI views when it's closed.
        closeObservers[id] = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if let observer = self.closeObservers.removeValue(forKey: id) {
                NotificationCenter.default.removeObserver(observer)
            }
            self.windows[id] = nil
            DispatchQueue.main.async { window.contentViewController = nil }
        }
        bringToFront(window)
    }

    /// Keeps every open window above other apps (or back to normal), e.g. around a
    /// permission prompt; bringing them back to the front when released.
    func setFloating(_ floating: Bool) {
        for (id, window) in windows {
            // The setup window always floats.
            window.level = floating || id == "onboarding" ? .floating : .normal
            if !floating { bringToFront(window) }
        }
    }

    func close(id: String) {
        windows[id]?.close()
    }

    private func bringToFront(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private extension NSWindow {
    /// Sizes the window so `size` fits below the title bar, keeping its top edge in place.
    func fitContent(_ size: CGSize) {
        var newFrame = frameRect(forContentRect: CGRect(origin: .zero, size: size))
        newFrame.origin = CGPoint(x: frame.minX, y: frame.maxY - newFrame.height)
        guard newFrame != frame else { return }
        setFrame(newFrame, display: true)
    }
}
