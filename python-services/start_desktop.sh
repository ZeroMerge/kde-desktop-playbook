#!/usr/bin/env bash
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript /home/zeromerge/.local/share/kwin/scripts/modern_desktop/contents/code/main.js >/dev/null 2>&1 || true
pkill -f "python3.*bottom_dock.py" 2>/dev/null || true
pkill -f "python3.*dynamic_island.py" 2>/dev/null || true
sleep 0.5
exec python3 /home/zeromerge/.local/share/modern-desktop/dynamic_island.py
