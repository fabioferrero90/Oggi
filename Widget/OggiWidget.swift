import SwiftUI
import WidgetKit
import AppIntents

struct TodayEntry: TimelineEntry {
    let date: Date
    let items: [TodoItem]
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        let today = Calendar.current.startOfDay(for: Date())
        return TodayEntry(date: Date(), items: [
            TodoItem(title: "Rispondere alle email", day: today),
            TodoItem(title: "Chiamare il commercialista", day: today),
            TodoItem(title: "Palestra", day: today, doneAt: Date()),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        let items = TodoRepository.shared.todayItems()
        completion(items.isEmpty && context.isPreview ? placeholder(in: context) : TodayEntry(date: Date(), items: items))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = TodayEntry(date: Date(), items: TodoRepository.shared.todayItems())
        // A mezzanotte le attività di "domani" diventano di oggi.
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        completion(Timeline(entries: [entry], policy: .after(midnight.addingTimeInterval(5))))
    }
}

struct OggiWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayEntry

    private var maxRows: Int {
        switch family {
        case .systemSmall: 4
        case .systemMedium: 4
        case .systemLarge: 10
        default: 16
        }
    }

    private var openCount: Int { entry.items.filter { !$0.isDone }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            header
            if entry.items.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 7) {
                    ForEach(entry.items.prefix(maxRows)) { item in
                        TodoRow(item: item, compact: family == .systemSmall)
                    }
                }
                if entry.items.count > maxRows {
                    Link(destination: OggiLink.open) {
                        Text("+\(entry.items.count - maxRows) altre")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Oggi")
                    .font(.headline)
                if family != .systemSmall {
                    Text(entry.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if openCount > 0 {
                Text("\(openCount)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Link(destination: OggiLink.add) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer(minLength: 0)
            Label("Niente in programma", systemImage: "checkmark.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Link(destination: OggiLink.add) {
                Text("Aggiungi un'attività")
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
        }
    }
}

struct TodoRow: View {
    let item: TodoItem
    let compact: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Button(intent: ToggleTodoIntent(id: item.id)) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(compact ? .body : .title3)
                    .foregroundStyle(item.isDone ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Link(destination: OggiLink.edit(item.id)) {
                Text(item.title)
                    .font(compact ? .caption : .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !item.isDone && !compact {
                Button(intent: PostponeTodoIntent(id: item.id)) {
                    Image(systemName: "arrow.turn.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Rimanda a domani")
            }
        }
    }
}

struct OggiWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OggiWidget", provider: TodayProvider()) { entry in
            OggiWidgetView(entry: entry)
        }
        .configurationDisplayName("Oggi")
        .description("Le cose da fare oggi: spuntale, rimandale a domani o aggiungine di nuove.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

@main
struct OggiWidgetBundle: WidgetBundle {
    var body: some Widget { OggiWidget() }
}
