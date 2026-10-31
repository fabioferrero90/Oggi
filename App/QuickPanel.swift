import SwiftUI
import AppKit

/// Pannello fluttuante in stile Spotlight, aperto dai link del widget.
final class QuickPanel: NSObject, NSWindowDelegate {
    static let shared = QuickPanel()
    private var panel: NSPanel?

    func showAdd() { present(QuickAddView(editing: nil, close: close)) }
    func showEdit(_ item: TodoItem) { present(QuickAddView(editing: item, close: close)) }
    func showList() { present(ContentView()) }

    private func present<V: View>(_ view: V) {
        panel?.close()
        let hosting = NSHostingView(rootView: view.environmentObject(TodoStore.shared))
        hosting.safeAreaRegions = []
        let panel = KeyPanel(contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
                             styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        let effect = NSVisualEffectView()
        effect.material = .popover
        effect.state = .active
        effect.blendingMode = .behindWindow
        hosting.translatesAutoresizingMaskIntoConstraints = false
        effect.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: effect.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: effect.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: effect.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: effect.bottomAnchor),
        ])
        panel.contentView = effect
        panel.setContentSize(hosting.fittingSize)

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2,
                                         y: frame.maxY - frame.height * 0.28 - panel.frame.height / 2))
        }
        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.close()
        panel = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        // Il calendario apre un popover che diventa finestra key: chiudiamo solo se l'utente è andato altrove.
        DispatchQueue.main.async {
            if !NSApp.isActive || NSApp.keyWindow == nil { self.close() }
        }
    }
}

private final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { QuickPanel.shared.close() }
}

struct QuickAddView: View {
    @EnvironmentObject private var store: TodoStore
    let editing: TodoItem?
    let close: () -> Void

    @State private var title = ""
    @State private var day = Calendar.current.startOfDay(for: Date())
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: editing == nil ? "plus.circle.fill" : "pencil.circle.fill")
                    .font(.title)
                    .foregroundStyle(.tint)
                TextField(editing == nil ? "Cosa devi fare?" : "Titolo", text: $title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.title2)
                    .focused($focused)
                    .onSubmit(save)
            }

            HStack(spacing: 8) {
                DayChooser(day: $day)
                Spacer()
                if let editing {
                    iconButton(editing.isDone ? "arrow.uturn.backward.circle" : "checkmark.circle",
                               help: editing.isDone ? "Segna come da fare" : "Completata") {
                        store.toggle(editing.id); close()
                    }
                    iconButton("trash", help: "Elimina") { store.delete(editing.id); close() }
                }
                Text("↩ salva · esc chiudi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .controlSize(.small)
        }
        .padding(16)
        .frame(width: 460)
        .onAppear {
            title = editing?.title ?? ""
            if let editing { day = max(editing.day, Calendar.current.startOfDay(for: Date())) }
            focused = true
        }
    }

    private func save() {
        if let editing {
            store.rename(editing.id, to: title)
            if day != editing.day { store.setDay(editing.id, to: day) }
        } else {
            store.add(title, on: day)
        }
        close()
    }

    private func iconButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body)
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(help)
    }
}
