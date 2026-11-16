# Rheinwerk Starter Skills: Spec-Driven Development

Vorlage für den **Rheinwerk Online-Kurs Spec-Driven Development** („Spec-Driven
Development mit KI-Coding-Agenten“). Du kopierst sie in dein Firmen-Repo, füllst die
`<ANPASSEN: …>`-Stellen und hast deinen eigenen Flow:

```
Ticket ──/spec──▶ specs/<slug>.md ──Freigabe──▶ /code ──▶ /verify [--pr] ──▶ Draft-PR/MR
```

Die Skills sind stack-neutral. Alles Projektspezifische steht an markierten Stellen:
Ticket-System, Gate-Befehle, Port und Dev-URL, Branch-Schema, Freigabe-Modus.
Ein durchgespieltes Beispiel (Nuxt, GitHub) ist das Demo-Repo
[dinooo13/habit-tracker-demo](https://github.com/dinooo13/habit-tracker-demo), siehe dort
`KURS.md`.

## In 15 Minuten in dein Repo

1. **Kopieren** (im Ordner neben deinem Projekt):

   ```bash
   git clone https://github.com/dinooo13/rheinwerk-starter-skills.git
   cd dein-projekt
   S=../rheinwerk-starter-skills
   mkdir -p .claude .agents .codex
   cp -R $S/.claude/skills $S/.claude/agents $S/.claude/hooks $S/.claude/settings.json .claude/
   cp -R $S/.agents/skills .agents/          # Codex
   cp -R $S/.codex/agents .codex/            # Codex
   cp $S/AGENTS.md.template AGENTS.md
   ```

   Hast du schon eine `.claude/settings.json`, kopier sie nicht, sondern übernimm den
   `Stop`-Eintrag in deine.

2. **Anpass-Stellen finden:** `grep -rn ANPASSEN .claude .agents AGENTS.md`

3. **Ticket-System wählen.** In `spec` (Ticket lesen) und `verify` (Draft-PR/MR öffnen)
   steht GitHub als Beispiel, darunter die Zeilen für GitLab und Jira:

   | System | Ticket lesen | PR/MR öffnen | Verweis |
   |--------|--------------|--------------|---------|
   | GitHub | `gh issue view <n> --json number,title,body,comments` | `gh pr create --draft …` | `Refs #42` |
   | GitLab | `glab issue view <n> --comments` | `glab mr create --draft …` | `Refs #42` |
   | Jira | `acli jira workitem view KEY-123 --fields summary,description,comment` | `gh` oder `glab` | `Refs KEY-123` |

   Ersetze die `<ANPASSEN: Ticket-System …>`-Zeile durch deinen Befehl und lösch die
   anderen beiden.

4. **Gates eintragen:** lint, typecheck, test, e2e. Sie stehen an vier Stellen: oben in
   `.claude/hooks/gates-on-stop.sh` (nur die schnellen, ohne e2e; leer heißt: Hook aus), in `code`, in `verify`
   und in `AGENTS.md`. Halte sie gleich. Dazu Port und Dev-URL, das Branch-Schema und,
   wenn ihr anders freigebt als per Kopfzeile in der Spec, den Freigabe-Modus.

5. **`AGENTS.md` füllen:** Befehle, Architektur-Karte, harte Regeln, wo die ADRs liegen.
   Claude Code liest `AGENTS.md`, wenn es keine `CLAUDE.md` gibt (ab v2.1.277). Hast du
   schon eine `CLAUDE.md`, schreib dort `@AGENTS.md` hinein. Codex liest `AGENTS.md` immer.

6. **Ticket-Vorlage einbauen** (aus `templates/`, siehe unten), dann eine neue Session
   starten und mit `grep -rn ANPASSEN .claude .agents AGENTS.md` prüfen, dass nichts übrig ist.

Ist eine Stelle noch nicht gefüllt, fragt der Skill nach oder liest den Wert aus `AGENTS.md`.

## Was jede Datei tut

| Datei | Zweck |
|-------|-------|
| `.claude/skills/spec/SKILL.md` | `/spec <ticket \| aufgabe>`: liest Ticket, `AGENTS.md` und ADRs, lässt einen Explore-Subagenten den Code kartieren, klärt offene Punkte, schreibt `specs/<slug>.md` und **hält an**, bis ein Mensch freigibt. |
| `.claude/skills/code/SKILL.md` | `/code specs/<slug>.md`: setzt eine freigegebene Spec Task für Task um, Test zuerst (rot, grün, refactor), ein Conventional Commit pro Task, am Ende Gates grün. Nur manuell aufrufbar. |
| `.claude/skills/verify/SKILL.md` | `/verify specs/<slug>.md [--pr]`: prüft jedes Akzeptanzkriterium, führt alle Gates aus, holt ein frisches Review vom `reviewer`, geht die Kriterien im Browser durch, schreibt `specs/<slug>.verification.md`. Mit `--pr` ein Draft-PR/MR mit `Refs`. Nur manuell aufrufbar. |
| `.claude/agents/reviewer.md` | Schreibgeschützter Review-Subagent (nur `Read`, `Grep`, `Glob`, `Bash` für git). Startet ohne Kontext des Autors, liefert Befunde mit Datei, Zeile und Schwere. |
| `.claude/hooks/gates-on-stop.sh` | Stop-Hook: Will Claude den Turn beenden und hat sich etwas geändert, laufen die schnellen Gates. Rot blockt einmal; ist es nach dem Reparaturversuch (`stop_hook_active`) noch rot, blockt er nicht erneut, sondern meldet es dir. Solange `GATES` leer ist, tut er nichts. Braucht `bash` und `git`, `jq` optional. |
| `.claude/settings.json` | Registriert den Stop-Hook. |
| `AGENTS.md.template` | Gerüst für die Kontext-Datei: Gates, Dev-Server, Branches, Tickets, Architektur-Karte, harte Regeln, ADRs. |
| `.agents/skills/…` | Dieselben drei Skills für Codex (`$spec`, `$code`, `$verify`). |
| `.codex/agents/reviewer.toml` | Der `reviewer` für Codex. Read-only erzwingt Codex nur über die Sandbox der Session. |
| `templates/github/ISSUE_TEMPLATE/feature_request.yml` | Issue-Formular mit Pflichtfeld Akzeptanzkriterien → `.github/ISSUE_TEMPLATE/` |
| `templates/github/pull_request_template.md` | PR-Vorlage mit `Refs #`, Spec, Bericht, Testplan → `.github/` |
| `templates/gitlab/issue_templates/Feature.md` | Issue-Vorlage mit Akzeptanzkriterien → `.gitlab/issue_templates/` |
| `templates/gitlab/merge_request_templates/Default.md` | MR-Vorlage → `.gitlab/merge_request_templates/` |
| `templates/jira/ticket-vorlage.md` | Welche Felder ein Jira-Ticket für `/spec` braucht, wie `/spec` es liest und wie PRs verknüpft werden. |

## Codex-Spiegel synchron halten

`.agents/skills/` enthält Kopien, keine Symlinks: Symlinks gehen unter Windows und in
manchen Zip-Downloads verloren. Nach jeder Änderung an einem Claude-Skill:

```bash
for s in spec code verify; do cp .claude/skills/$s/SKILL.md .agents/skills/$s/SKILL.md; done
diff -r .claude/skills .agents/skills && echo synchron
```

Den `diff` kannst du auch in die CI hängen. Ändert sich `.claude/agents/reviewer.md`,
übernimm den Text in `developer_instructions` von `.codex/agents/reviewer.toml`.

## Hinweise

- **Umbenannt:** Der Skill `dev` heißt jetzt `code`, passend zu `/spec`, `/code`,
  `/verify` im Kurs. Statt des `verifier`-Subagenten prüft `verify` selbst und holt sich
  ein Review vom `reviewer`.
- Unter Windows braucht der Hook Git Bash oder WSL.
- Hast du unter `~/.claude/skills/` schon einen persönlichen Skill `spec`, `code` oder
  `verify`, gewinnt der persönliche über den im Projekt. Benenn ihn dann um.
- `npx skills add dinooo13/rheinwerk-starter-skills` installiert nur die Skills, nicht
  Agent, Hook und Vorlagen. Für den vollen Flow kopieren wie oben.
