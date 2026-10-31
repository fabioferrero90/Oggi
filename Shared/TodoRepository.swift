import Foundation
import WidgetKit

struct TodoItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    /// Inizio del giorno in cui l'attività è prevista.
    var day: Date
    var doneAt: Date?
    var createdAt: Date = Date()

    var isDone: Bool { doneAt != nil }
}

enum OggiLink {
    static let add = URL(string: "oggi://add")!
    static let open = URL(string: "oggi://open")!
    static func edit(_ id: UUID) -> URL { URL(string: "oggi://edit?id=\(id.uuidString)")! }
}

/// Archivio su file JSON nel contenitore App Group, condiviso tra app e widget.
final class TodoRepository {
    static let shared = TodoRepository()
    static let appGroup = "8R256TB48E.com.fabioferrero.oggi"
    static let didChange = Notification.Name("com.fabioferrero.oggi.didChange")

    private let url: URL
    private var calendar: Calendar { .current }

    private init() {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        url = base.appendingPathComponent("todos.json")
    }

    // MARK: Lettura

    func load() -> [TodoItem] {
        guard let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([TodoItem].self, from: data) else { return [] }
        return items
    }

    var today: Date { calendar.startOfDay(for: Date()) }
    var tomorrow: Date { calendar.date(byAdding: .day, value: 1, to: today)! }

    /// Attività di oggi: quelle da fare previste per oggi o arretrate, più quelle completate oggi.
    func todayItems(from items: [TodoItem]? = nil) -> [TodoItem] {
        let all = items ?? load()
        let open = all.filter { !$0.isDone && $0.day <= today }.sorted { $0.createdAt < $1.createdAt }
        let done = all.filter { ($0.doneAt.map { $0 >= today }) ?? false }.sorted { $0.doneAt! < $1.doneAt! }
        return open + done
    }

    func upcomingItems(from items: [TodoItem]? = nil) -> [TodoItem] {
        let all = items ?? load()
        return all.filter { !$0.isDone && $0.day > today }
            .sorted { ($0.day, $0.createdAt) < ($1.day, $1.createdAt) }
    }

    // MARK: Modifica

    func add(_ title: String, on day: Date) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        mutate { $0.append(TodoItem(title: clean, day: self.calendar.startOfDay(for: day))) }
    }

    func setDay(_ id: UUID, to day: Date) {
        mutate { items in
            guard let i = items.firstIndex(where: { $0.id == id }) else { return }
            items[i].day = self.calendar.startOfDay(for: day)
        }
    }

    func toggle(_ id: UUID) {
        mutate { items in
            guard let i = items.firstIndex(where: { $0.id == id }) else { return }
            items[i].doneAt = items[i].isDone ? nil : Date()
        }
    }

    func postpone(_ id: UUID) {
        mutate { items in
            guard let i = items.firstIndex(where: { $0.id == id }) else { return }
            items[i].day = self.tomorrow
            items[i].doneAt = nil
        }
    }

    func rename(_ id: UUID, to title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        mutate { items in
            guard let i = items.firstIndex(where: { $0.id == id }) else { return }
            items[i].title = clean
        }
    }

    func delete(_ id: UUID) {
        mutate { $0.removeAll { $0.id == id } }
    }

    private func mutate(_ body: (inout [TodoItem]) -> Void) {
        var items = load()
        body(&items)
        // Le attività completate restano visibili solo il giorno in cui sono state chiuse,
        // nell'archivio le teniamo una settimana.
        let cutoff = calendar.date(byAdding: .day, value: -7, to: today)!
        items.removeAll { ($0.doneAt.map { $0 < cutoff }) ?? false }
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url, options: .atomic)
        }
        WidgetCenter.shared.reloadAllTimelines()
        DistributedNotificationCenter.default().postNotificationName(Self.didChange, object: nil, deliverImmediately: true)
    }
}
