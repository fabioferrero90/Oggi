import SwiftUI

extension Date {
    /// "Oggi", "Domani" oppure la data abbreviata ("lun 3 nov").
    var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) { return "Oggi" }
        if cal.isDateInTomorrow(self) { return "Domani" }
        if self < cal.startOfDay(for: Date()) { return "In ritardo" }
        return formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}

/// Scorciatoie Oggi / Domani più un calendario per scegliere qualunque data.
struct DayChooser: View {
    @Binding var day: Date
    @State private var showCalendar = false

    private var cal: Calendar { .current }
    private var today: Date { cal.startOfDay(for: Date()) }
    private var tomorrow: Date { cal.date(byAdding: .day, value: 1, to: today)! }

    var body: some View {
        HStack(spacing: 4) {
            chip("Oggi", selected: cal.isDateInToday(day)) { day = today }
            chip("Domani", selected: cal.isDateInTomorrow(day)) { day = tomorrow }
            let custom = !cal.isDateInToday(day) && !cal.isDateInTomorrow(day)
            chip(custom ? day.dayLabel : "Data…", systemImage: "calendar", selected: custom) { showCalendar.toggle() }
                .popover(isPresented: $showCalendar, arrowEdge: .bottom) {
                    DatePicker("", selection: $day, in: today..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding(10)
                        .onChange(of: day) { _, _ in showCalendar = false }
                }
        }
    }

    private func chip(_ title: String, systemImage: String? = nil, selected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.caption.weight(selected ? .semibold : .regular))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(selected ? AnyShapeStyle(.tint.opacity(0.2)) : AnyShapeStyle(.quaternary.opacity(0.6)),
                        in: Capsule())
            .foregroundStyle(selected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
