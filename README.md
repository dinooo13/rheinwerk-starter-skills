# Rheinwerk Starter Skills — „Coding mit KI"

Starter-Skills für den **Rheinwerk Spotlight** Vortrag „Coding mit KI".

Dieses Repository enthält zwei einsatzbereite Agent-Skills, die einen
durchgängigen Workflow abbilden: von der ersten Idee bis zur fertig
implementierten und getesteten Aufgabe. Die Skills sind bewusst
**technologie-unabhängig** gehalten — sie lesen die Konventionen deines
Projekts (z. B. aus `CLAUDE.md` oder `AGENTS.md`) aus und passen sich an
deinen Tech-Stack an.

## Die Skills

### `spec` — Aufgabe brainstormen & spezifizieren

Verwandelt eine grobe Aufgabe oder Feature-Idee durch eine interaktive
Frage-und-Antwort-Runde in eine vollständige Spezifikation.

- **Eingabe:** eine kurze Aufgabenbeschreibung, eine Feature-Idee, eine
  Ticket-/Issue-Nummer oder eine Datei aus `specs/`.
- **Ablauf:** Der Skill stellt pro Runde mehrere Fragen mit empfohlenen
  Antwortoptionen (inkl. kurzer Begründung und ggf. ASCII-Skizzen),
  protokolliert jede Runde in einer Brainstorming-Datei und schreibt am Ende
  eine fertige Spezifikation.
- **Ergebnis:**
  - `specs/{name}_brainstorming.md` — das vollständige Frage-Protokoll
  - `specs/{name}_specification.md` — die fertige Spezifikation

### `dev` — Aufgabe implementieren (Team-Modus)

Setzt eine fertige Spezifikation Ende-zu-Ende um. Der Skill agiert als
**Team-Lead** und koordiniert spezialisierte Agenten, die den Code bauen,
Tests schreiben und alles im Browser verifizieren.

- **Eingabe:** der Pfad zur Spezifikationsdatei (z. B.
  `specs/{name}_specification.md`).
- **Ablauf:** Kontext sammeln → Arbeitsphasen planen → Abhängigkeiten und
  Aufgaben anlegen → Agenten (Backend, Frontend, Tests, Verifikation) starten
  → Verifikations-Schleife bis alle Checks grün sind → committen.
- **Ergebnis:** implementierter, getesteter und verifizierter Code sowie eine
  `specs/{name}_progress.md` mit dem Fortschritt.

## Empfohlener Workflow

```
Idee  ──/spec──▶  Spezifikation  ──/dev──▶  fertige, getestete Implementierung
```

1. `spec` ausführen, um aus einer Idee eine Spezifikation zu machen.
2. `dev` mit der erzeugten Spezifikationsdatei ausführen, um sie umzusetzen.

## Verzeichnisstruktur

Die Skills liegen in zwei Ordnern, damit sie von unterschiedlichen
Agent-Tools gefunden werden:

```
.claude/skills/        # für Claude Code
├── spec/SKILL.md
└── dev/SKILL.md

.agents/skills/        # tool-übergreifende Agent-Konvention
├── spec/SKILL.md
└── dev/SKILL.md
```

Beide Ordner enthalten denselben Skill-Inhalt.

## Verwendung in Claude Code

Die Skills werden über ihren Namen als Slash-Command aufgerufen:

```
/spec <aufgaben-beschreibung-oder-datei>
/dev  <spezifikations-datei>
```

## Hinweise

- Die Skills treffen **keine** fest verdrahteten Technologie-Annahmen. Stelle
  sicher, dass dein Projekt eine Kontext-Datei (`CLAUDE.md`, `AGENTS.md` o. ä.)
  mit Architektur, Tech-Stack und Konventionen besitzt — daraus leiten die
  Skills ihre Empfehlungen und Vorgehensweisen ab.
- Spezifikationen, Brainstorming-Protokolle und Fortschrittsdateien werden im
  Ordner `specs/` deines Projekts abgelegt.
