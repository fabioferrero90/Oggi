import SwiftUI
import ServiceManagement

/// Lista completa: si apre dalla barra dei menu, dal pannello rapido e nella sidebar.
struct ContentView: View {
    @EnvironmentObject private var store: TodoStore
    @ObservedObject private var sidebarController = SidebarController.shared
    var sidebar = false
    @State private var newTitle = ""
    @State private var newDay = Calendar.current.startOfDay(for: Date())
    @State private var showUpcoming = true
    @FocusState private var addFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            addField
                .padding(.horizontal, 10)
                .padding(.bottom, 6)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if store.today.isEmpty {
                        Text("Nothing planned for today.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(store.today) { item in
                        TodoEditableRow(item: item, isUpcoming: false)
                    }

                    if !store.upcoming.isEmpty {
                        DisclosureGroup(isExpanded: $showUpcoming) {
                            ForEach(store.upcoming) { item in
                                TodoEditableRow(item: item, isUpcoming: true)
                            }
                        } label: {
                            Text("Upcoming · \(store.upcoming.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.top, 10)
                    }
                }
                .padding(8)
            }
            .frame(minHeight: 120, maxHeight: sidebar ? .infinity : 420)

            Divider()
            footer
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .frame(width: sidebar ? nil : 340)
        .frame(maxWidth: sidebar ? .infinity : nil, maxHeight: sidebar ? .infinity : nil, alignment: .top)
        .onAppear {
            store.reload()
            if !sidebar { addFocused = true }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Today").font(.title3.weight(.semibold))
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            if store.openToday > 0 {
                Text("\(store.openToday) to do")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var addField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.tint)
                TextField("New task…", text: $newTitle, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($addFocused)
                    .onSubmit { submit(on: newDay) }
                Button("") { submit(on: store.tomorrowDate) }
                    .keyboardShortcut(.return, modifiers: .command)
                    .hidden()
                    .frame(width: 0)
            }
            HStack {
                DayChooser(day: $newDay)
                Spacer()
                Text("⌘↩ tomorrow")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private func submit(on day: Date) {
        store.add(newTitle, on: day)
        newTitle = ""
        newDay = store.todayDate
        addFocused = true
    }

    @ViewBuilder private var footer: some View {
        if sidebar {
            HStack(spacing: 10) {
                Picker("", selection: $sidebarController.edge) {
                    Image(systemName: "rectangle.lefthalf.inset.filled").tag(SidebarController.Edge.left)
                    Image(systemName: "rectangle.righthalf.inset.filled").tag(SidebarController.Edge.right)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .help("Screen edge")
                Toggle("Above windows", isOn: $sidebarController.onTop)
                    .toggleStyle(.checkbox)
                Spacer()
                Button { sidebarController.isVisible = false } label: { Image(systemName: "xmark") }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Close sidebar")
            }
            .font(.caption)
            .controlSize(.small)
        } else {
            HStack {
                LaunchAtLoginToggle()
                Toggle("Sidebar", isOn: $sidebarController.isVisible)
                    .toggleStyle(.checkbox)
                    .help("Show the full-height list on the edge of the screen")
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
    }
}

struct TodoEditableRow: View {
    @EnvironmentObject private var store: TodoStore
    let item: TodoItem
    let isUpcoming: Bool
    @State private var title = ""
    @State private var hovering = false
    @State private var showCalendar = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Button { store.toggle(item.id) } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isDone ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
            .buttonStyle(.plain)
            .help(item.isDone ? "Mark as not done" : "Mark as done")

            TextField("", text: $title, axis: .vertical)
                .textFieldStyle(.plain)
                .strikethrough(item.isDone)
                .foregroundStyle(item.isDone ? .secondary : .primary)
                .focused($focused)
                .onSubmit { commit() }
                .onChange(of: focused) { _, isFocused in if !isFocused { commit() } }

            if isUpcoming {
                Text(item.day.dayLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if hovering || focused || showCalendar {
                HStack(spacing: 2) {
                    if isUpcoming {
                        iconButton("arrow.uturn.backward", help: "Move to today") { store.setDay(item.id, to: store.todayDate) }
                    } else if !item.isDone {
                        iconButton("arrow.turn.up.right", help: "Postpone to tomorrow") { store.postpone(item.id) }
                    }
                    if !item.isDone {
                        iconButton("calendar", help: "Pick a date") { showCalendar.toggle() }
                            .popover(isPresented: $showCalendar, arrowEdge: .bottom) {
                                DatePicker("", selection: Binding(
                                    get: { max(item.day, store.todayDate) },
                                    set: { store.setDay(item.id, to: $0); showCalendar = false }
                                ), in: store.todayDate..., displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .padding(10)
                            }
                    }
                    iconButton("trash", help: "Delete") { store.delete(item.id) }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(hovering ? AnyShapeStyle(.quaternary.opacity(0.6)) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 6))
        .onHover { hovering = $0 }
        .onAppear { title = item.title }
        .onChange(of: item.title) { _, new in title = new }
    }

    private func commit() {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            title = item.title
        } else if title != item.title {
            store.rename(item.id, to: title)
        }
    }

    private func iconButton(_ symbol: String, help: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(help)
    }
}

struct LaunchAtLoginToggle: View {
    @State private var enabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle("Open at login", isOn: $enabled)
            .toggleStyle(.checkbox)
            .onChange(of: enabled) { _, on in
                do {
                    if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                } catch {
                    enabled = SMAppService.mainApp.status == .enabled
                }
            }
    }
}
