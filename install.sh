#!/usr/bin/env bash
# omarchy-update-app-under-cursor — installer
#
# Installs the update-under-cursor script to ~/.local/bin and registers the
# SUPER + right-click binding in ~/.config/hypr/bindings.lua. Idempotent:
# running it again is safe.

set -euo pipefail

SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/omarchy-update-app-under-cursor"
BIN_DIR="${HOME}/.local/bin"
BIN_PATH="${BIN_DIR}/omarchy-update-app-under-cursor"
BINDINGS="${HOME}/.config/hypr/bindings.lua"

BEGIN="-- >> omarchy-update-app-under-cursor"
END="-- << omarchy-update-app-under-cursor"
BLOCK="-- >> omarchy-update-app-under-cursor
-- SUPER + right-click updates the app under the cursor (previously: resize window)
hl.unbind(\"SUPER + mouse:273\")
o.bind(\"SUPER + mouse:273\", \"Update app under cursor\", \"omarchy-update-app-under-cursor\")
-- << omarchy-update-app-under-cursor"

if [[ ! -f $SCRIPT_SRC ]]; then
  echo "error: $SCRIPT_SRC not found" >&2
  exit 1
fi

install -Dm755 "$SCRIPT_SRC" "$BIN_PATH"
echo "installed $BIN_PATH"

if [[ -f $BINDINGS ]]; then
  if grep -Fq -- "$BEGIN" "$BINDINGS"; then
    echo "binding already registered, skipping"
  else
    printf '\n%s\n' "$BLOCK" >>"$BINDINGS"
    echo "registered SUPER + mouse:273 in $BINDINGS"
  fi
else
  echo "warning: $BINDINGS not found; add the binding manually:"
  printf '%s\n' "$BLOCK"
fi

echo "reloading Hyprland..."
if hyprctl reload >/dev/null 2>&1; then
  sleep 1
  errors="$(hyprctl configerrors 2>/dev/null || true)"
  if [[ -n $errors ]]; then
    echo "WARNING: Hyprland reported config errors:"
    echo "$errors"
  else
    echo "Hyprland reloaded cleanly."
  fi
else
  echo "note: hyprctl not available here (not inside a Hyprland session?); reload manually with: hyprctl reload"
fi

echo
echo "done — hold SUPER and right-click any window to update its app."
