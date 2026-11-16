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

### `dev` — Aufgabe implementieren (mit Subagenten)

Setzt eine fertige Spezifikation Ende-zu-Ende um. Der Skill arbeitet als
**Orchestrator** und gibt die Arbeit an **Subagenten** ab: Sie bauen den Code,
schreiben Tests und prüfen alles im Browser. Jeder Subagent startet mit
frischem Kontext, erledigt genau eine Aufgabe und liefert nur eine kurze
Zusammenfassung zurück. So bleibt der Hauptkontext schlank.

- **Eingabe:** der Pfad zur Spezifikationsdatei (z. B.
  `specs/{name}_specification.md`).
- **Ablauf:** Kontext sammeln (Recherche per Subagent) → Arbeitsphasen planen
  → Subagenten für Backend, Frontend und Tests starten, unabhängige Phasen
  parallel → Verifikations-Schleife mit dem `verifier`-Subagenten, bis alle
  Checks grün sind → committen.
- **Ergebnis:** implementierter, getesteter und verifizierter Code sowie eine
  `specs/{name}_progress.md` mit dem Fortschritt.

`dev` startest du selbst mit `/dev`. Der Agent ruft ihn nicht von sich aus
auf, weil der Skill Code schreibt und committet.

### `verifier` — Subagent für die Verifikation

Ein schreibgeschützter QA-Subagent. Er führt Tests, Lint, Type-Check und
Browser-Checks aus, repariert aber nichts, sondern meldet alle Fehler als
kurze Liste. `dev` startet ihn in jeder Runde der Verifikations-Schleife neu.
Fehlt er im Projekt, nimmt `dev` einen allgemeinen Subagenten.

## Empfohlener Workflow

```
Idee  ──/spec──▶  Spezifikation  ──/dev──▶  fertige, getestete Implementierung
```

1. `spec` ausführen, um aus einer Idee eine Spezifikation zu machen.
2. `dev` mit der erzeugten Spezifikationsdatei ausführen, um sie umzusetzen.

## Voraussetzungen

- **Claude Code** oder **Codex** in einer aktuellen Version. Subagenten sind
  in beiden eingebaut; du musst nichts extra aktivieren.
- **Node.js 22.20 oder neuer**, wenn du per `npx skills` installierst.
- Eine **Kontext-Datei** im Projekt (`CLAUDE.md`, `AGENTS.md` o. ä.) mit
  Architektur, Tech-Stack und Konventionen.
- Für die Browser-Checks von `dev` ein Browser-Automatisierungstool, z. B.
  Playwright.

## Installation

### Variante 1: `npx skills`

Im Projektordner ausführen:

```bash
npx skills add dinooo13/rheinwerk-starter-skills
```

Der Befehl fragt, welche Skills und welche Agenten-Tools (z. B. Claude Code,
Codex) du willst. Er installiert nur die **Skills**. Den `verifier`-Subagenten
kopierst du bei Bedarf wie in Variante 2; ohne ihn nutzt `dev` einen
allgemeinen Subagenten.

### Variante 2: `git clone` und kopieren

```bash
# im Ordner neben deinem Projekt
git clone https://github.com/dinooo13/rheinwerk-starter-skills.git
cd dein-projekt

# Claude Code: Skills und Subagent
mkdir -p .claude
cp -R ../rheinwerk-starter-skills/.claude/skills ../rheinwerk-starter-skills/.claude/agents .claude/

# Codex: Skills und Subagent
mkdir -p .agents .codex
cp -R ../rheinwerk-starter-skills/.agents/skills .agents/
cp -R ../rheinwerk-starter-skills/.codex/agents .codex/
```

Starte danach eine neue Session, damit die Skills und der Subagent geladen
werden.

## Verzeichnisstruktur

Die Skills liegen in zwei Ordnern, damit sie von unterschiedlichen
Agent-Tools gefunden werden:

```
.claude/skills/        # Skills für Claude Code
├── spec/SKILL.md
└── dev/SKILL.md
.claude/agents/        # Subagent für Claude Code
└── verifier.md

.agents/skills/        # Skills für Codex und andere Tools (Agent-Skills-Standard)
├── spec/SKILL.md
└── dev/SKILL.md
.codex/agents/         # Subagent für Codex
└── verifier.toml
```

Beide Skill-Ordner enthalten denselben Inhalt, ebenso die beiden
`verifier`-Dateien.

## Verwendung

In Claude Code rufst du die Skills über ihren Namen als Slash-Command auf:

```
/spec <aufgaben-beschreibung-oder-datei>
/dev  <spezifikations-datei>
```

In Codex erwähnst du sie mit `$`, z. B. `$spec` oder `$dev`, und hängst die
Beschreibung bzw. den Pfad an.

## Hinweise

- Die Skills treffen **keine** fest verdrahteten Technologie-Annahmen. Stelle
  sicher, dass dein Projekt eine Kontext-Datei (`CLAUDE.md`, `AGENTS.md` o. ä.)
  mit Architektur, Tech-Stack und Konventionen besitzt — daraus leiten die
  Skills ihre Empfehlungen und Vorgehensweisen ab.
- Spezifikationen, Brainstorming-Protokolle und Fortschrittsdateien werden im
  Ordner `specs/` deines Projekts abgelegt.
- Frühere Versionen von `dev` nutzten Agent Teams. Das ist in Claude Code
  experimentell und standardmäßig aus. Subagenten laufen ohne Zusatz-Setup in
  Claude Code und Codex.
