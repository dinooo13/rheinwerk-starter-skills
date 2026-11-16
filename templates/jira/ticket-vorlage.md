# Jira: Ticket-Vorlage für /spec

Jira-Vorlagen liegen nicht im Repo, sondern im Projekt (Admin: Vorgangstyp und Felder).
Diese Datei beschreibt, welche Felder ein Ticket braucht, damit `/spec` damit arbeiten kann.

| Feld | Jira-Feld | Pflicht | Inhalt |
|------|-----------|---------|--------|
| Titel | Zusammenfassung (`summary`) | ja | Was sich für wen ändert, ein Satz |
| Problem | Beschreibung (`description`), Abschnitt „Problem“ | ja | Was fehlt oder stört, und für wen |
| Akzeptanzkriterien | eigenes Feld <ANPASSEN: Jira-Feld für Akzeptanzkriterien, z. B. `customfield_10050`> oder Abschnitt in der Beschreibung | ja | Checkliste oder Given/When/Then, prüfbar durch Mensch oder Test |
| Lösungsidee | Beschreibung, Abschnitt „Lösungsidee“ | nein | Grobe Richtung |
| Risiken | Beschreibung, Abschnitt „Risiken“ | nein | Schema, Migrationen, betroffene Bereiche |

**Definition of Ready:** ohne prüfbare Akzeptanzkriterien kein `/spec`. Wer ein eigenes Feld
nutzt, macht es im Feldkonfigurationsschema zur Pflicht.

**Lesen:** `acli jira workitem view KEY-123 --fields '*all' --json`. Ohne `'*all'` fehlen
Kommentare und Custom Fields, also oft die Akzeptanzkriterien. Wer es schlanker will:
`--fields summary,description,comment,<AC-Feld>`.
Trag den Befehl im `spec`-Skill unter Settings ein.

**Verknüpfen:** Branch `feat/KEY-123-<slug>`, PR/MR-Titel mit `KEY-123`, im Text `Relates to KEY-123`.
Mit der Jira-Integration für GitHub oder GitLab erscheint der PR dann am Ticket.

**Nach dem Draft-PR/MR:** Ist die Pipeline grün, setzt `/verify` den Status und kommentiert:
`acli jira workitem transition --key KEY-123 --status "In Review" --yes` und
`acli jira workitem comment create --key KEY-123 --body "…"`. Den Statusnamen eures
Workflows trägst du im `verify`-Skill unter Settings ein.

## Beschreibung zum Einfügen

Die vier Überschriften im Jira-Editor als Überschrift setzen, den Rest als Liste.

```text
Problem
Was fehlt oder stört, und für wen?

Akzeptanzkriterien
- [ ] Given ..., When ..., Then ...
- [ ] Schwere Fälle: leere Listen, Fehler, Neuladen, alte Daten, mobile Breite

Lösungsidee (optional)

Risiken (optional)
```
