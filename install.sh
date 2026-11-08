#!/usr/bin/env bash
# ==============================================================================
# Modern Desktop Suite - Automated Installer & Modular Deployer
# System: Kubuntu 26.04 LTS / KDE Plasma 6 (Wayland)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="${HOME}"
FILES_DIR="${SCRIPT_DIR}/files"

# Destination directories
PLASMOIDS_DIR="${USER_HOME}/.local/share/plasma/plasmoids"
SHELLS_DIR="${USER_HOME}/.local/share/plasma/shells/org.kde.plasma.desktop/contents/views"
THEMES_DIR="${USER_HOME}/.local/share/plasma/desktoptheme"
COLORS_DIR="${USER_HOME}/.local/share/color-schemes"
FONTS_DIR="${USER_HOME}/.local/share/fonts"
ICONS_DIR="${USER_HOME}/.local/share/icons"
KONSOLE_DIR="${USER_HOME}/.local/share/konsole"
CONFIG_DIR="${USER_HOME}/.config"
BIN_DIR="${USER_HOME}/.local/bin"
APPS_DIR="${USER_HOME}/.local/share/applications"

BACKUP_DIR="${USER_HOME}/.config/kde-desktop-backups/$(date '+%Y%m%d_%H%M%S')"

# Helpers
log() { echo -e "\033[1;34m==>\033[0m \033[1m$1\033[0m"; }
success() { echo -e "\033[1;32m✔\033[0m $1"; }
warn() { echo -e "\033[1;33m⚠\033[0m $1"; }

backup_config() {
    local target="$1"
    if [ -e "$target" ]; then
        mkdir -p "${BACKUP_DIR}"
        cp -r "$target" "${BACKUP_DIR}/" 2>/dev/null || true
    fi
}

deploy_theme() {
    log "Deploying Color Schemes and Modern Dock Themes..."
    mkdir -p "${COLORS_DIR}" "${THEMES_DIR}" "${BIN_DIR}"
    
    cp "${FILES_DIR}/color-schemes/"* "${COLORS_DIR}/"
    rm -rf "${THEMES_DIR}/modern-dock" "${THEMES_DIR}/modern-dock-light"
    cp -r "${FILES_DIR}/themes/modern-dock" "${THEMES_DIR}/"
    cp -r "${FILES_DIR}/themes/modern-dock-light" "${THEMES_DIR}/"
    
    cp "${FILES_DIR}/bin/desktop-theme" "${BIN_DIR}/desktop-theme"
    chmod +x "${BIN_DIR}/desktop-theme"
    success "Color schemes, desktop themes, and desktop-theme switcher deployed."
}

deploy_dolphin() {
    log "Deploying Dolphin Explorer Stylesheets, Wrapper, and Desktop Entry..."
    mkdir -p "${CONFIG_DIR}" "${BIN_DIR}" "${APPS_DIR}"
    
    backup_config "${CONFIG_DIR}/dolphinrc"
    backup_config "${CONFIG_DIR}/dolphin.qss"
    
    cp "${FILES_DIR}/dolphin/dolphin.qss" "${CONFIG_DIR}/dolphin.qss"
    cp "${FILES_DIR}/dolphin/dolphin-light.qss" "${CONFIG_DIR}/dolphin-light.qss"
    cp "${FILES_DIR}/dolphin/dolphin-dark.qss" "${CONFIG_DIR}/dolphin-dark.qss"
    cp "${FILES_DIR}/dolphin/dolphinrc" "${CONFIG_DIR}/dolphinrc"
    
    cp "${FILES_DIR}/bin/dolphin" "${BIN_DIR}/dolphin"
    chmod +x "${BIN_DIR}/dolphin"
    
    cp "${FILES_DIR}/applications/org.kde.dolphin.desktop" "${APPS_DIR}/org.kde.dolphin.desktop"
    chmod +x "${APPS_DIR}/org.kde.dolphin.desktop"
    update-desktop-database "${APPS_DIR}" 2>/dev/null || true
    success "Dolphin QSS (KUrlNavigator & selection contrast fixes) deployed."
}

deploy_konsole() {
    log "Deploying Konsole Profiles and JetBrains Mono Nerd Font..."
    mkdir -p "${KONSOLE_DIR}" "${CONFIG_DIR}" "${FONTS_DIR}/JetBrainsMono"
    
    backup_config "${CONFIG_DIR}/konsolerc"
    
    cp "${FILES_DIR}/konsole/ModernDark.colorscheme" "${KONSOLE_DIR}/"
    cp "${FILES_DIR}/konsole/ModernLight.colorscheme" "${KONSOLE_DIR}/"
    cp "${FILES_DIR}/konsole/ModernDark.profile" "${KONSOLE_DIR}/"
    cp "${FILES_DIR}/konsole/ModernLight.profile" "${KONSOLE_DIR}/"
    cp "${FILES_DIR}/konsole/konsolerc" "${CONFIG_DIR}/konsolerc"
    
    if [ -d "${FILES_DIR}/fonts/JetBrainsMono" ]; then
        cp "${FILES_DIR}/fonts/JetBrainsMono/"*.ttf "${FONTS_DIR}/JetBrainsMono/" 2>/dev/null || true
        fc-cache -f "${FONTS_DIR}" 2>/dev/null || true
    fi
    success "Konsole profiles and JetBrains Mono font deployed."
}

deploy_fonts() {
    log "Deploying Modern Typography Suite (Plus Jakarta Sans, Manrope, Switzer, Inter)..."
    mkdir -p "${FONTS_DIR}" "${BIN_DIR}"
    
    if [ -d "${FILES_DIR}/fonts" ]; then
        cp -r "${FILES_DIR}/fonts/"* "${FONTS_DIR}/" 2>/dev/null || true
        fc-cache -f "${FONTS_DIR}" 2>/dev/null || true
    fi
    
    if [ -f "${FILES_DIR}/scripts/desktop-font-switcher" ]; then
        cp "${FILES_DIR}/scripts/desktop-font-switcher" "${BIN_DIR}/desktop-font-switcher"
        chmod +x "${BIN_DIR}/desktop-font-switcher"
        ln -sf "${BIN_DIR}/desktop-font-switcher" "${BIN_DIR}/switch-font"
    fi
    success "Typography suite and desktop-font-switcher CLI active."
}

deploy_kwin() {
    log "Deploying KWin Window Rules (Quarter Snapping, TabBox Big Icons, Soft Shadows, Animations)..."
    mkdir -p "${CONFIG_DIR}"
    
    backup_config "${CONFIG_DIR}/kwinrc"
    backup_config "${CONFIG_DIR}/breezerc"
    backup_config "${CONFIG_DIR}/krunnerrc"
    backup_config "${CONFIG_DIR}/kaccessrc"
    backup_config "${CONFIG_DIR}/plasmaparc"
    
    cp "${FILES_DIR}/kwin/kwinrc" "${CONFIG_DIR}/kwinrc"
    cp "${FILES_DIR}/kwin/breezerc" "${CONFIG_DIR}/breezerc"
    cp "${FILES_DIR}/configs/krunnerrc" "${CONFIG_DIR}/krunnerrc"
    cp "${FILES_DIR}/configs/kaccessrc" "${CONFIG_DIR}/kaccessrc"
    cp "${FILES_DIR}/configs/plasmaparc" "${CONFIG_DIR}/plasmaparc"
    
    # Instant window animations (0.5x) & Ocean audio feedback
    kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0.5
    kwriteconfig6 --file kdeglobals --group Sounds --key Enable true
    kwriteconfig6 --file kdeglobals --group Sounds --key Theme ocean
    
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
    krunner --replace >/dev/null 2>&1 &
    success "KWin snapping, TabBox Big Icons, floating KRunner, and 0.5x animations active."
}

deploy_cursor() {
    log "Deploying Bibata Modern Ice Cursor Theme..."
    mkdir -p "${ICONS_DIR}" "${USER_HOME}/.icons/default"
    
    if [ -d "${FILES_DIR}/cursor/Bibata-Modern-Ice" ]; then
        cp -r "${FILES_DIR}/cursor/Bibata-Modern-Ice" "${ICONS_DIR}/"
    fi
    cp "${FILES_DIR}/cursor/icons-default/index.theme" "${USER_HOME}/.icons/default/index.theme"
    
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "Bibata-Modern-Ice"
    kwriteconfig6 --file kdeglobals --group Mouse --key cursorTheme "Bibata-Modern-Ice"
    success "Bibata Modern Ice cursor deployed and active."
}

deploy_gtk() {
    log "Deploying GTK 3/4 & GNOME Interface Portal Synchronization..."
    mkdir -p "${CONFIG_DIR}/gtk-3.0" "${CONFIG_DIR}/gtk-4.0"
    
    cp "${FILES_DIR}/gtk/gtk-3.0/settings.ini" "${CONFIG_DIR}/gtk-3.0/settings.ini"
    cp "${FILES_DIR}/gtk/gtk-4.0/settings.ini" "${CONFIG_DIR}/gtk-4.0/settings.ini"
    
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark' >/dev/null 2>&1 || true
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' >/dev/null 2>&1 || true
    fi
    success "GTK 3/4 settings and GNOME portal synchronized."
}

deploy_lockscreen() {
    log "Deploying Lock Screen Wallpaper Synchronization..."
    mkdir -p "${CONFIG_DIR}"
    backup_config "${CONFIG_DIR}/kscreenlockerrc"
    cp "${FILES_DIR}/lockscreen/kscreenlockerrc" "${CONFIG_DIR}/kscreenlockerrc"
    success "Lock screen wallpaper configured."
}

deploy_shell() {
    log "Deploying Shell Panel.qml (Dynamic Island Pill & Flush Bottom Dock)..."
    mkdir -p "${SHELLS_DIR}"
    backup_config "${SHELLS_DIR}/Panel.qml"
    cp "${FILES_DIR}/shell/org.kde.plasma.desktop/contents/views/Panel.qml" "${SHELLS_DIR}/Panel.qml"
    success "Shell Panel.qml deployed."
}

deploy_plasmoids() {
    log "Deploying Plasmoids (KdeControlStation, DockPin, DynamicIsland)..."
    mkdir -p "${PLASMOIDS_DIR}"
    
    rm -rf "${PLASMOIDS_DIR}/KdeControlStation"
    cp -r "${FILES_DIR}/plasmoids/KdeControlStation" "${PLASMOIDS_DIR}/"
    
    if [ -d "${FILES_DIR}/plasmoids/org.kde.plasma.dockpin" ]; then
        rm -rf "${PLASMOIDS_DIR}/org.kde.plasma.dockpin"
        cp -r "${FILES_DIR}/plasmoids/org.kde.plasma.dockpin" "${PLASMOIDS_DIR}/"
    fi
    
    if [ -d "${FILES_DIR}/plasmoids/com.manu028.dynamicisland" ]; then
        rm -rf "${PLASMOIDS_DIR}/com.manu028.dynamicisland"
        cp -r "${FILES_DIR}/plasmoids/com.manu028.dynamicisland" "${PLASMOIDS_DIR}/"
    fi
    success "Plasmoids deployed."
}

restart_plasma() {
    log "Restarting Plasma Shell to reload QML components..."
    systemctl --user restart plasma-plasmashell.service 2>/dev/null || (kquitapp6 plasmashell 2>/dev/null && kstart plasmashell 2>/dev/null) || true
    success "Plasma Shell refreshed."
}

# ------------------------------------------------------------------------------
# Dispatcher
# ------------------------------------------------------------------------------
echo "=========================================================="
echo " Modern Desktop Suite Deployment Tool (KDE Plasma 6)"
echo "=========================================================="

if [ $# -eq 0 ] || [[ "$*" =~ "--all" ]]; then
    deploy_fonts
    deploy_theme
    deploy_dolphin
    deploy_konsole
    deploy_kwin
    deploy_cursor
    deploy_gtk
    deploy_lockscreen
    deploy_shell
    deploy_plasmoids
    restart_plasma
    echo "=========================================================="
    success "Full suite successfully deployed!"
    echo "=========================================================="
    exit 0
fi

for arg in "$@"; do
    case "$arg" in
        --fonts)      deploy_fonts ;;
        --theme)      deploy_theme ;;
        --dolphin)    deploy_dolphin ;;
        --konsole)    deploy_konsole ;;
        --kwin)       deploy_kwin ;;
        --cursor)     deploy_cursor ;;
        --gtk)        deploy_gtk ;;
        --lockscreen) deploy_lockscreen ;;
        --shell)      deploy_shell ;;
        --plasmoids)  deploy_plasmoids ;;
        --restart)    restart_plasma ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTION]"
            echo "Options:"
            echo "  --all         Deploy all components and restart plasma (default)"
            echo "  --fonts       Deploy Typography Suite (Plus Jakarta Sans, Manrope, Switzer, Inter) and switcher"
            echo "  --theme       Deploy color schemes, desktop themes, and desktop-theme switcher"
            echo "  --dolphin     Deploy Dolphin QSS stylesheets, wrapper, and desktop entry"
            echo "  --konsole     Deploy Konsole profiles, colorschemes, and JetBrains Mono"
            echo "  --kwin        Deploy KWin quarter snapping and soft shadows"
            echo "  --cursor      Deploy Bibata Modern Ice cursor and X11 inheritance"
            echo "  --gtk         Deploy GTK 3/4 settings and GNOME interface portal"
            echo "  --lockscreen  Deploy lock screen wallpaper configuration"
            echo "  --shell       Deploy Panel.qml dynamic island and bottom dock"
            echo "  --plasmoids   Deploy Control Station and DockPin plasmoids"
            echo "  --restart     Restart plasmashell process"
            exit 0
            ;;
        *)
            warn "Unknown option: $arg"
            ;;
    esac
done

echo "=========================================================="
success "Selected operations completed!"
echo "=========================================================="
