#!/usr/bin/env bash
# apply_layout.sh - Apply Modern Desktop Suite layout via Plasma 6 Scripting
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYOUT_JS="${SCRIPT_DIR}/setup_desktop_layout.js"

if [ ! -f "$LAYOUT_JS" ]; then
    echo "Error: Layout JS script not found at $LAYOUT_JS" >&2
    exit 1
fi

echo "==> Applying Modern Desktop Layout via Plasma Scripting..."
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$LAYOUT_JS")"

echo "==> Reloading Plasma Shell..."
systemctl --user restart plasma-plasmashell.service || (kquitapp6 plasmashell && kstart plasmashell)

echo "==> Modern Desktop Suite successfully applied!"
