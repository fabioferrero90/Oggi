import SwiftUI
import AppKit

@main
struct OggiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @ObservedObject private var store = TodoStore.shared

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
        } label: {
            Image(systemName: store.openToday > 0 ? "checklist" : "checklist.checked")
            if store.openToday > 0 { Text("\(store.openToday)") }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        SidebarController.shared.apply()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first, url.scheme == "oggi" else { return }
        switch url.host {
        case "add":
            QuickPanel.shared.showAdd()
        case "edit":
            let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "id" }?.value
                .flatMap(UUID.init(uuidString:))
            if let id, let item = TodoStore.shared.items.first(where: { $0.id == id }) {
                QuickPanel.shared.showEdit(item)
            } else {
                QuickPanel.shared.showList()
            }
        default:
            QuickPanel.shared.showList()
        }
    }
}

/// Stato osservabile dell'app: rilegge l'archivio quando il widget lo modifica.
final class TodoStore: ObservableObject {
    static let shared = TodoStore()
    private let repo = TodoRepository.shared

    @Published private(set) var items: [TodoItem] = []

    var today: [TodoItem] { repo.todayItems(from: items) }
    var upcoming: [TodoItem] { repo.upcomingItems(from: items) }
    var openToday: Int { today.filter { !$0.isDone }.count }
    var todayDate: Date { repo.today }
    var tomorrowDate: Date { repo.tomorrow }

    private init() {
        reload()
        DistributedNotificationCenter.default().addObserver(
            forName: TodoRepository.didChange, object: nil, queue: .main) { [weak self] _ in self?.reload() }
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in self?.reload() }
    }

    func reload() { items = repo.load() }

    func add(_ title: String, on day: Date) { repo.add(title, on: day); reload() }
    func setDay(_ id: UUID, to day: Date) { repo.setDay(id, to: day); reload() }
    func toggle(_ id: UUID) { repo.toggle(id); reload() }
    func postpone(_ id: UUID) { repo.postpone(id); reload() }
    func rename(_ id: UUID, to title: String) { repo.rename(id, to: title); reload() }
    func delete(_ id: UUID) { repo.delete(id); reload() }
}
