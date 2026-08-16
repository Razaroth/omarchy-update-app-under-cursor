#!/usr/bin/env bash
# omarchy-update-app-under-cursor — uninstaller
#
# Removes the script from ~/.local/bin and removes the SUPER + right-click
# binding block from ~/.config/hypr/bindings.lua (restoring the default
# resize-window behavior), then reloads Hyprland.

set -euo pipefail

BIN_PATH="${HOME}/.local/bin/omarchy-update-app-under-cursor"
BINDINGS="${HOME}/.config/hypr/bindings.lua"
BEGIN="-- >> omarchy-update-app-under-cursor"
END="-- << omarchy-update-app-under-cursor"

rm -f "$BIN_PATH"
echo "removed $BIN_PATH"

if [[ -f $BINDINGS ]]; then
  if grep -Fq -- "$BEGIN" "$BINDINGS"; then
    tmp="$(mktemp)"
    awk -v b="$BEGIN" -v e="$END" '
      $0 == b { skip = 1; next }
      $0 == e { skip = 0; next }
      !skip
    ' "$BINDINGS" >"$tmp" && mv "$tmp" "$BINDINGS"
    echo "removed binding block from $BINDINGS (SUPER + right-click restored to resize)"
  else
    echo "no managed binding block found in $BINDINGS, skipping"
  fi
fi

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

echo "uninstalled."
