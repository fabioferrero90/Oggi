import SwiftUI
import AppKit

/// Lista a tutta altezza ancorata a un bordo dello schermo. Di default vive al livello
/// della scrivania, come i widget; opzionalmente resta sopra le altre finestre.
final class SidebarController: NSObject, ObservableObject, NSWindowDelegate {
    enum Edge: String { case left, right }

    static let shared = SidebarController()

    @Published var isVisible: Bool {
        didSet { defaults.set(isVisible, forKey: Keys.visible); apply() }
    }
    @Published var edge: Edge {
        didSet { defaults.set(edge.rawValue, forKey: Keys.edge); layout() }
    }
    @Published var onTop: Bool {
        didSet { defaults.set(onTop, forKey: Keys.onTop); applyLevel() }
    }

    private enum Keys {
        static let visible = "sidebar.visible"
        static let edge = "sidebar.edge"
        static let onTop = "sidebar.onTop"
        static let width = "sidebar.width"
    }

    private let defaults = UserDefaults.standard
    private let margin: CGFloat = 8
    private var width: CGFloat
    private var panel: NSPanel?
    private var isLayingOut = false

    private override init() {
        isVisible = defaults.bool(forKey: Keys.visible)
        edge = Edge(rawValue: defaults.string(forKey: Keys.edge) ?? "") ?? .right
        onTop = defaults.bool(forKey: Keys.onTop)
        let saved = defaults.double(forKey: Keys.width)
        width = saved > 0 ? saved : 320
        super.init()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.layout() }
    }

    func apply() {
        if isVisible { show() } else { hide() }
    }

    private func show() {
        if panel == nil { panel = makePanel() }
        applyLevel()
        layout()
        panel?.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func makePanel() -> NSPanel {
        let panel = SidebarPanel(contentRect: .zero,
                                 styleMask: [.borderless, .resizable, .nonactivatingPanel],
                                 backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        panel.minSize = NSSize(width: 260, height: 300)
        panel.maxSize = NSSize(width: 560, height: CGFloat.greatestFiniteMagnitude)
        panel.delegate = self

        let effect = NSVisualEffectView()
        effect.material = .sidebar
        effect.state = .active
        effect.blendingMode = .behindWindow
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 14
        effect.layer?.masksToBounds = true

        let hosting = NSHostingView(rootView: ContentView(sidebar: true).environmentObject(TodoStore.shared))
        hosting.safeAreaRegions = []
        hosting.translatesAutoresizingMaskIntoConstraints = false
        effect.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: effect.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: effect.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: effect.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: effect.bottomAnchor),
        ])
        panel.contentView = effect
        return panel
    }

    private func applyLevel() {
        panel?.level = onTop
            ? .floating
            : NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
    }

    /// Altezza piena dello spazio utile (sotto la barra dei menu, sopra il Dock) sul bordo scelto.
    private func layout() {
        guard let panel, let screen = NSScreen.screens.first else { return }
        let area = screen.visibleFrame
        let x = edge == .left ? area.minX + margin : area.maxX - width - margin
        isLayingOut = true
        panel.setFrame(NSRect(x: x, y: area.minY + margin, width: width, height: area.height - margin * 2),
                       display: true)
        isLayingOut = false
    }

    func windowDidResize(_ notification: Notification) {
        guard !isLayingOut, let panel else { return }
        width = panel.frame.width
        defaults.set(Double(width), forKey: Keys.width)
        layout()
    }
}

private final class SidebarPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
