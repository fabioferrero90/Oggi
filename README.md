<p align="center">
  <img src="docs/icon.png" width="160" alt="Oggi icon">
</p>

<h1 align="center">Oggi</h1>

<p align="center">A macOS to-do list that lives on your desktop: an interactive widget, a menu bar list and a full-height sidebar.</p>

---

*Oggi* is Italian for "today". The app shows what you need to do **today** and lets you manage it without opening any window.

## Features

- **Interactive widget** (small, medium, large, extra large): click the circle to complete a task, ↪ to postpone it to tomorrow, the title to edit it, and ＋ to add a new one.
- **Menu bar**: the ✓ icon shows how many tasks are left; click it for the full list, where you can edit titles, postpone, change dates and delete.
- **Sidebar**: the same list at full screen height, docked to the left or right edge. By default it sits below your windows like a widget; it can also stay on top. Drag its inner edge to change the width.
- **Quick add**: a Spotlight-style panel to type a task and choose when to do it.
- **Dates**: every task has a day (Today, Tomorrow or any date from the calendar). Future tasks are listed under "Upcoming" and move into "Today" on their day; overdue tasks stay in "Today" until you close them.
- **Languages**: English by default, Italian when the system language is Italian.

### Shortcuts

| Where | Key | Action |
| --- | --- | --- |
| Add field | ↩ | Add on the selected day |
| Add field (menu bar) | ⌘↩ | Add for tomorrow |
| Titles | ⌥↩ | Insert a line break |
| Quick add panel | esc | Close |

## Requirements

- macOS 14 Sonoma or later (interactive widgets need macOS 14)
- Xcode 26 or later (the icon uses the Icon Composer format)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- An Apple developer account: widgets and App Groups require code signing

## Build and install

The Xcode project is not checked in: generate it from `project.yml`.

```bash
xcodegen generate
```

```bash
xcodebuild -project Oggi.xcodeproj -scheme Oggi -configuration Release -derivedDataPath build -allowProvisioningUpdates build
```

```bash
rm -rf /Applications/Oggi.app && cp -R build/Build/Products/Release/Oggi.app /Applications/ && open /Applications/Oggi.app
```

Then add the widget: right-click the desktop → **Edit Widgets…** → search for **Oggi**.

> To build with your own developer account, change `DEVELOPMENT_TEAM` in `project.yml` and the App Group prefix (`8R256TB48E.com.fabioferrero.oggi`) in both `project.yml` and `Shared/TodoRepository.swift`.

### If the widget doesn't show up in the gallery

Keep a single copy of the app installed (the one in `/Applications`), then restart the widget service:

```bash
killall chronod NotificationCenter
```

## Project structure

```
App/        Menu bar app: list, sidebar, quick add panel, icon
Widget/     WidgetKit extension
Shared/     Data model, App Intents and translations, shared by app and widget
Scripts/    Icon layer generator
docs/       README images
project.yml XcodeGen project definition
```

**Data.** Tasks are stored in a JSON file (`todos.json`) in the App Group container shared by the app and the widget. Every change reloads the widget and notifies the app through a distributed notification, so all views stay in sync. Completed tasks stay visible until the end of the day and are removed after a week.

**Widget.** The buttons use App Intents (`ToggleTodoIntent`, `PostponeTodoIntent`) and work without opening the app. Titles and ＋ open `oggi://` links handled by the app:

| Link | Opens |
| --- | --- |
| `oggi://add` | Quick add panel |
| `oggi://edit?id=<uuid>` | Edit panel for that task |
| `oggi://open` | Full list |

**Localization.** Source strings are in English; Italian translations live in the string catalog `Shared/Localizable.xcstrings`. To add a language, add its translations to the catalog and its code to `CFBundleLocalizations` in `project.yml`.

## Icon

The icon is an Icon Composer file (`App/AppIcon.icon`) with two layers: a sunrise background and a white check mark. To regenerate the layers after editing them:

```bash
swift Scripts/make-icon.swift App/AppIcon.icon/Assets docs/icon.png
```
