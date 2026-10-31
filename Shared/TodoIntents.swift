import AppIntents
import Foundation

struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete task"
    static var isDiscoverable = false

    @Parameter(title: "ID") var id: String

    init() {}
    init(id: UUID) { self.id = id.uuidString }

    func perform() async throws -> some IntentResult {
        if let uuid = UUID(uuidString: id) { TodoRepository.shared.toggle(uuid) }
        return .result()
    }
}

struct PostponeTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Postpone to tomorrow"
    static var isDiscoverable = false

    @Parameter(title: "ID") var id: String

    init() {}
    init(id: UUID) { self.id = id.uuidString }

    func perform() async throws -> some IntentResult {
        if let uuid = UUID(uuidString: id) { TodoRepository.shared.postpone(uuid) }
        return .result()
    }
}
