#!/usr/bin/env bash
# Stop-Hook: Wenn Claude den Turn beenden will, laufen die schnellen Gates.
# Rot  -> {"decision": "block", "reason": ...}: Claude arbeitet weiter und repariert.
# Grün -> keine Ausgabe, Claude hört auf.
# Läuft nur, wenn sich seit dem letzten Lauf Dateien geändert haben.
#
# Schleifenschutz: Ist stop_hook_active true, arbeitet Claude schon wegen eines
# Stop-Hooks weiter. Dann blocken wir nicht noch einmal, sondern melden rote Gates
# nur noch dem Menschen (systemMessage), und Claude darf aufhören.
# Format: https://code.claude.com/docs/en/hooks#stop
# Abhängigkeiten: bash, git. jq ist optional.

# <ANPASSEN: Gate-Befehle, schnell (Sekunden, kein e2e), ein Befehl pro Zeile, z. B. "npm run lint">
# Solange die Liste leer ist, tut der Hook nichts.
GATES=(
  # "npm run lint"
  # "npm test"
)

# <ANPASSEN: optional: Bedingung, ohne die die Gates nicht laufen können, z. B. [ -d node_modules ]>
READY_CHECK="true"

set -uo pipefail
input="$(cat)"
[ "${#GATES[@]}" -eq 0 ] && exit 0

json_get() { # $1 = Feldname auf oberster Ebene
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null
  else
    printf '%s' "$input" | tr -d '\n' \
      | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\).*/\1/p"
  fi
}

active="$(json_get stop_hook_active)"

cwd="$(json_get cwd)"
repo_root="$(git -C "${cwd:-${CLAUDE_PROJECT_DIR:-$PWD}}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$repo_root" || exit 0
eval "$READY_CHECK" || exit 0

# Fingerabdruck: HEAD, geänderte und neue (nicht ignorierte) Dateien.
fingerprint() {
  {
    git rev-parse HEAD 2>/dev/null
    git diff HEAD --binary 2>/dev/null
    git ls-files --others --exclude-standard -z 2>/dev/null \
      | while IFS= read -r -d '' f; do printf '%s ' "$f"; git hash-object -- "$f" 2>/dev/null; done
  } | git hash-object --stdin
}
still_red() { # zweiter Stopp in Folge: nicht mehr blocken, nur dem Menschen melden
  msg="gates-on-stop: nach dem Reparaturversuch immer noch rot: $1"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg m "$msg" '{systemMessage: $m}'
    exit 0
  fi
  printf '%s\n' "$msg" >&2
  exit 1 # nicht blockierender Fehler: der Mensch sieht die Meldung
}

# Zustand: Zeile 1 Fingerabdruck, Zeile 2 die roten Gates des letzten Laufs.
state_file="$(git rev-parse --git-path claude-gates-on-stop)"
current="$(fingerprint)"
if [ "$current" = "$(sed -n 1p "$state_file" 2>/dev/null)" ]; then
  last_failed="$(sed -n 2p "$state_file")"
  [ -n "$last_failed" ] && [ "$active" = "true" ] && still_red "$last_failed"
  exit 0
fi

failed=""
log=""
for gate in "${GATES[@]}"; do
  out="$(bash -c "$gate" 2>&1)"
  if [ $? -ne 0 ]; then
    failed="${failed:+$failed, }$gate"
    log="$log
--- $gate (letzte Zeilen) ---
$(printf '%s\n' "$out" | sed $'s/\x1b\\[[0-9;]*m//g' | tail -n 40)"
  fi
done
printf '%s\n%s\n' "$current" "$failed" > "$state_file"

[ -z "$failed" ] && exit 0
[ "$active" = "true" ] && still_red "$failed"

reason="Not done: the gates are red ($failed). Fix the cause, do not skip or weaken tests, then end your turn again.$log"
if command -v jq >/dev/null 2>&1; then
  jq -n --arg r "$reason" --arg m "gates-on-stop: $failed rot" \
    '{decision: "block", reason: $r, systemMessage: $m}'
  exit 0
fi
# Ohne jq: Exit-Code 2 blockt ebenfalls, stderr wird zum Grund für Claude.
printf '%s\n' "$reason" >&2
exit 2
