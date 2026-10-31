import AppIntents
import Foundation

struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Completa attività"
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
    static var title: LocalizedStringResource = "Rimanda a domani"
    static var isDiscoverable = false

    @Parameter(title: "ID") var id: String

    init() {}
    init(id: UUID) { self.id = id.uuidString }

    func perform() async throws -> some IntentResult {
        if let uuid = UUID(uuidString: id) { TodoRepository.shared.postpone(uuid) }
        return .result()
    }
}
