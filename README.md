<p align="center">
  <img src="docs/icon.png" width="160" alt="Icona di Oggi">
</p>

<h1 align="center">Oggi</h1>

<p align="center">Una todo list per macOS che vive sulla scrivania: widget interattivo, barra dei menu e sidebar a tutta altezza.</p>

---

## Cosa fa

Oggi mostra le cose da fare **oggi** e permette di gestirle senza aprire nessuna finestra.

- **Widget interattivo** (piccolo, medio, grande, extra-large): completi un'attività con un clic sul cerchio, la rimandi a domani con ↪, apri il titolo per modificarlo e aggiungi nuove attività con ＋.
- **Barra dei menu**: l'icona ✓ mostra quante attività restano; dentro trovi la lista completa con modifica dei titoli, rimando, cambio data ed eliminazione.
- **Sidebar**: la stessa lista a tutta altezza, ancorata al bordo sinistro o destro dello schermo. Di default sta sotto le finestre come un widget, oppure sempre in primo piano. La larghezza si cambia trascinando il bordo.
- **Aggiunta rapida**: un pannello in stile Spotlight per scrivere un'attività e scegliere quando farla.
- **Date**: ogni attività ha un giorno (Oggi, Domani o una data dal calendario). Le attività future stanno in "Prossimi giorni" e passano da sole in "Oggi" quando arriva il giorno; quelle arretrate restano in "Oggi" finché non le chiudi.

### Scorciatoie

| Dove | Tasto | Azione |
| --- | --- | --- |
| Campo di aggiunta | ↩ | Aggiunge nel giorno scelto |
| Campo di aggiunta (barra dei menu) | ⌘↩ | Aggiunge per domani |
| Titoli | ⌥↩ | Va a capo dentro il titolo |
| Pannello rapido | esc | Chiude |

## Requisiti

- macOS 14 Sonoma o successivo (i widget interattivi richiedono macOS 14)
- Xcode 26 o successivo (l'icona usa il formato Icon Composer)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Un account sviluppatore Apple: widget e App Group richiedono la firma del codice

## Compilare e installare

Il progetto Xcode non è nel repository: si genera da `project.yml`.

```bash
xcodegen generate
```

```bash
xcodebuild -project Oggi.xcodeproj -scheme Oggi -configuration Release -derivedDataPath build -allowProvisioningUpdates build
```

```bash
rm -rf /Applications/Oggi.app && cp -R build/Build/Products/Release/Oggi.app /Applications/ && open /Applications/Oggi.app
```

Poi aggiungi il widget: clic destro sulla scrivania → **Modifica widget…** → cerca **Oggi**.

> Se usi un altro account sviluppatore, cambia `DEVELOPMENT_TEAM` in `project.yml` e il prefisso dell'App Group (`8R256TB48E.com.fabioferrero.oggi`) sia in `project.yml` sia in `Shared/TodoRepository.swift`.

### Se il widget non compare nella galleria

Lascia una sola copia dell'app installata (quella in `/Applications`), poi riavvia il servizio dei widget:

```bash
killall chronod NotificationCenter
```

## Struttura

```
App/        App della barra dei menu: lista, sidebar, pannello rapido, icona
Widget/     Estensione WidgetKit
Shared/     Modello dati e App Intents, condivisi tra app e widget
Scripts/    Generatore dei livelli dell'icona
docs/       Immagini per il README
project.yml Definizione del progetto per XcodeGen
```

**Dati.** Le attività sono salvate in un file JSON (`todos.json`) nel contenitore dell'App Group, condiviso tra app e widget. Ogni modifica ricarica il widget e avvisa l'app con una notifica distribuita, così tutte le viste restano allineate. Le attività completate restano visibili fino a fine giornata e vengono rimosse dopo una settimana.

**Widget.** I pulsanti usano App Intents (`ToggleTodoIntent`, `PostponeTodoIntent`) e agiscono senza aprire l'app. Titoli e ＋ aprono link `oggi://` che l'app gestisce:

| Link | Effetto |
| --- | --- |
| `oggi://add` | Pannello di aggiunta rapida |
| `oggi://edit?id=<uuid>` | Pannello di modifica dell'attività |
| `oggi://open` | Lista completa |

## Icona

L'icona è un file Icon Composer (`App/AppIcon.icon`) con due livelli: lo sfondo all'alba e la spunta bianca. Per rigenerare i livelli dopo averli modificati:

```bash
swift Scripts/make-icon.swift App/AppIcon.icon/Assets docs/icon.png
```
