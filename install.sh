#!/usr/bin/env bash
# ==============================================================================
# Modern Desktop Suite - Automated Installer & Deployer
# Works on fresh Kubuntu / KDE Plasma 6 installations.
# Can run via Ansible Playbook OR native Shell Installer mode.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="${HOME}"
PLASMOIDS_DIR="${USER_HOME}/.local/share/plasma/plasmoids"
SHELLS_DIR="${USER_HOME}/.local/share/plasma/shells/org.kde.plasma.desktop/contents/views"
THEMES_DIR="${USER_HOME}/.local/share/plasma/desktoptheme"
CONFIG_DIR="${USER_HOME}/.config"

echo "=========================================================="
echo " Modern Desktop Suite Installer for KDE Plasma 6"
echo "=========================================================="

# Check if ansible-playbook is installed
if command -v ansible-playbook &>/dev/null; then
    echo "==> Ansible detected! Running Ansible Playbook (desktop.yml)..."
    ansible-playbook -i "${SCRIPT_DIR}/inventory.ini" "${SCRIPT_DIR}/desktop.yml" "$@"
    exit 0
fi

echo "==> Ansible is not installed. Proceeding with Native Shell Installer mode..."

# 1. Ensure Directories
echo "==> Creating user directories..."
mkdir -p "${PLASMOIDS_DIR}"
mkdir -p "${SHELLS_DIR}"
mkdir -p "${THEMES_DIR}"
mkdir -p "${CONFIG_DIR}"
mkdir -p "${USER_HOME}/.local/share/fonts"
mkdir -p "${USER_HOME}/.local/bin"

# 1b. Deploy Modern UI Fonts & Switcher Tool
echo "==> Deploying typography suite (Switzer, Plus Jakarta Sans, Manrope, Satoshi)..."
cp -r "${SCRIPT_DIR}/files/fonts/"* "${USER_HOME}/.local/share/fonts/"
fc-cache -f "${USER_HOME}/.local/share/fonts" 2>/dev/null || true

cp "${SCRIPT_DIR}/files/scripts/desktop-font-switcher" "${USER_HOME}/.local/bin/desktop-font-switcher"
chmod +x "${USER_HOME}/.local/bin/desktop-font-switcher"
ln -sf "${USER_HOME}/.local/bin/desktop-font-switcher" "${USER_HOME}/.local/bin/switch-font"

# Deploy Dolphin Clean UI configs
if [ -f "${SCRIPT_DIR}/files/configs/dolphinrc" ]; then
    cp "${SCRIPT_DIR}/files/configs/dolphinrc" "${CONFIG_DIR}/dolphinrc"
fi
if [ -f "${SCRIPT_DIR}/files/configs/user-places.xbel" ]; then
    cp "${SCRIPT_DIR}/files/configs/user-places.xbel" "${USER_HOME}/.local/share/user-places.xbel"
fi

# Apply Switzer
"${USER_HOME}/.local/bin/desktop-font-switcher" switzer || true

# 2. Deploy Custom Plasmoids
echo "==> Deploying custom plasmoids..."
# Dock Pin (Halved 16px, 0px flush right, on-top mode)
rm -rf "${PLASMOIDS_DIR}/org.kde.plasma.dockpin"
cp -r "${SCRIPT_DIR}/files/plasmoids/org.kde.plasma.dockpin" "${PLASMOIDS_DIR}/"

# KDE Control Station (Option 3 with Plasma 6 compatibility & dark card)
rm -rf "${PLASMOIDS_DIR}/KdeControlStation"
cp -r "${SCRIPT_DIR}/files/plasmoids/KdeControlStation" "${PLASMOIDS_DIR}/"

# Dynamic Island (Option 2 community alternative)
rm -rf "${PLASMOIDS_DIR}/com.manu028.dynamicisland"
cp -r "${SCRIPT_DIR}/files/plasmoids/com.manu028.dynamicisland" "${PLASMOIDS_DIR}/"

# 3. Deploy Shell Modifications (Zero-padding Panel.qml)
echo "==> Deploying custom Panel.qml (zero floating horizontal padding)..."
cp "${SCRIPT_DIR}/files/shell/org.kde.plasma.desktop/contents/views/Panel.qml" "${SHELLS_DIR}/Panel.qml"

# 4. Deploy Custom Desktop Theme (Blur-Free Opaque SVG Borders)
echo "==> Deploying modern-dock desktop theme..."

# Deploy Color Schemes (ModernDark, ModernLight)
mkdir -p "${USER_HOME}/.local/share/color-schemes"
cp -r "${SCRIPT_DIR}/files/color-schemes/"* "${USER_HOME}/.local/share/color-schemes/" 2>/dev/null || true

# Deploy modern-dock-light theme
rm -rf "${THEMES_DIR}/modern-dock-light"
cp -r "${SCRIPT_DIR}/files/themes/modern-dock-light" "${THEMES_DIR}/"

# Deploy Theme Switcher and Desktop Toggle
cp "${SCRIPT_DIR}/files/bin/desktop-theme" "${USER_HOME}/.local/bin/desktop-theme"
chmod +x "${USER_HOME}/.local/bin/desktop-theme"
mkdir -p "${USER_HOME}/.local/share/applications"
cp "${SCRIPT_DIR}/files/applications/theme-toggle.desktop" "${USER_HOME}/.local/share/applications/"
chmod +x "${USER_HOME}/.local/share/applications/theme-toggle.desktop"

# Deploy Dolphin QSS and wrapper
cp "${SCRIPT_DIR}/files/configs/dolphin-dark.qss" "${CONFIG_DIR}/dolphin-dark.qss" 2>/dev/null || true
cp "${SCRIPT_DIR}/files/configs/dolphin-light.qss" "${CONFIG_DIR}/dolphin-light.qss" 2>/dev/null || true
cp "${SCRIPT_DIR}/files/configs/dolphin.qss" "${CONFIG_DIR}/dolphin.qss" 2>/dev/null || true
if [ -f "${SCRIPT_DIR}/files/bin/dolphin" ]; then
    cp "${SCRIPT_DIR}/files/bin/dolphin" "${USER_HOME}/.local/bin/dolphin"
    chmod +x "${USER_HOME}/.local/bin/dolphin"
fi

rm -rf "${THEMES_DIR}/modern-dock"
cp -r "${SCRIPT_DIR}/files/themes/modern-dock" "${THEMES_DIR}/"

# 5. Disable Dynamic Blur and Contrast Effects for 60fps Smooth Transitions
echo "==> Configuring blur-free 60fps transitions..."
if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file plasmarc --group Blur --key Enabled "false"
    kwriteconfig6 --file plasmarc --group ContrastEffect --key Enabled "false"
    kwriteconfig6 --file plasmarc --group AdaptiveTransparency --key Enabled "false"
fi

# Stop redundant legacy services if running
systemctl --user stop modern-desktop.service 2>/dev/null || true
systemctl --user disable modern-desktop.service 2>/dev/null || true

# Optional: Deploy Python standalone service (Option 4) if explicitly flagged
if [[ " $* " =~ " --with-python-service " ]]; then
    echo "==> Deploying custom Python desktop suite (Option 4)..."
    mkdir -p "${USER_HOME}/.local/share/modern-desktop"
    mkdir -p "${CONFIG_DIR}/systemd/user"
    cp "${SCRIPT_DIR}/python-services/"*.py "${USER_HOME}/.local/share/modern-desktop/"
    cp "${SCRIPT_DIR}/python-services/start_desktop.sh" "${USER_HOME}/.local/share/modern-desktop/"
    cp "${SCRIPT_DIR}/python-services/modern-desktop.service" "${CONFIG_DIR}/systemd/user/"
    systemctl --user daemon-reload
    systemctl --user enable --now modern-desktop.service
fi

# 6. Apply Desktop Layout via Plasma Scripting
echo "==> Applying desktop layout via Plasma D-Bus Scripting..."
if [ -f "${SCRIPT_DIR}/files/scripts/setup_desktop_layout.js" ]; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
        "$(cat "${SCRIPT_DIR}/files/scripts/setup_desktop_layout.js")" || true
fi

# 7. Restart Plasma Shell to refresh
echo "==> Refreshing Plasma Shell..."
systemctl --user restart plasma-plasmashell.service 2>/dev/null || (kquitapp6 plasmashell 2>/dev/null && kstart plasmashell 2>/dev/null) || true

echo "=========================================================="
echo " Installation Complete!"
echo " Top-Center Capsule: Digital Clock + KDE Control Station"
echo " Bottom Dock: Pinned Launchers + Flush 0px Halved Activator"
echo "=========================================================="
