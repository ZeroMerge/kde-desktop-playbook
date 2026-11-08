# Architecture & Deep Technical Reference Manual
## Kubuntu 26.04 LTS / KDE Plasma 6 (Wayland) Modern Desktop Suite

This document is a comprehensive, deep technical reference for the entire custom desktop environment. It details the exact mechanisms, root causes of upstream bugs, technical fixes, and line-by-line maintenance procedures so you can manually inspect, debug, and maintain every single component without relying on black-box scripts.

---

## 1. System Component Map & File Hierarchy

| Component | Repository Path | Target System Path | Reload / Verification Command |
| :--- | :--- | :--- | :--- |
| **Theme Switcher Script** | `files/bin/desktop-theme` | `~/.local/bin/desktop-theme` | `desktop-theme toggle` |
| **Dolphin Wrapper** | `files/bin/dolphin` | `~/.local/bin/dolphin` | `killall dolphin; dolphin` |
| **Dolphin Desktop Entry** | `files/applications/org.kde.dolphin.desktop` | `~/.local/share/applications/org.kde.dolphin.desktop` | `update-desktop-database ~/.local/share/applications` |
| **Dolphin QSS (Active)** | `files/dolphin/dolphin.qss` | `~/.config/dolphin.qss` | Automatically copied on theme toggle |
| **Dolphin QSS (Light)** | `files/dolphin/dolphin-light.qss` | `~/.config/dolphin-light.qss` | Evaluated when switching to Light |
| **Dolphin QSS (Dark)** | `files/dolphin/dolphin-dark.qss` | `~/.config/dolphin-dark.qss` | Evaluated when switching to Dark |
| **Dolphin Base Config** | `files/dolphin/dolphinrc` | `~/.config/dolphinrc` | Reread on Dolphin launch |
| **Color Scheme (Dark)** | `files/color-schemes/ModernDark.colors` | `~/.local/share/color-schemes/ModernDark.colors` | `plasma-apply-colorscheme ModernDark` |
| **Color Scheme (Light)** | `files/color-schemes/ModernLight.colors` | `~/.local/share/color-schemes/ModernLight.colors` | `plasma-apply-colorscheme ModernLight` |
| **Plasma Theme (Dark)** | `files/themes/modern-dock/` | `~/.local/share/plasma/desktoptheme/modern-dock/` | `plasma-apply-desktoptheme modern-dock` |
| **Plasma Theme (Light)**| `files/themes/modern-dock-light/` | `~/.local/share/plasma/desktoptheme/modern-dock-light/` | `plasma-apply-desktoptheme modern-dock-light` |
| **Shell Panel View** | `files/shell/.../Panel.qml` | `~/.local/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml` | `kquitapp6 plasmashell && kstart plasmashell` |
| **Control Station** | `files/plasmoids/KdeControlStation/` | `~/.local/share/plasma/plasmoids/KdeControlStation/` | `kquitapp6 plasmashell && kstart plasmashell` |
| **Dock Pin Activator** | `files/plasmoids/org.kde.plasma.dockpin/` | `~/.local/share/plasma/plasmoids/org.kde.plasma.dockpin/` | `kquitapp6 plasmashell && kstart plasmashell` |
| **Dynamic Island** | `files/plasmoids/com.manu028.dynamicisland/` | `~/.local/share/plasma/plasmoids/com.manu028.dynamicisland/` | `kquitapp6 plasmashell && kstart plasmashell` |
| **Konsole Colors (Dark)**| `files/konsole/ModernDark.colorscheme` | `~/.local/share/konsole/ModernDark.colorscheme` | `konsole --profile ModernDark` |
| **Konsole Colors (Light)**| `files/konsole/ModernLight.colorscheme` | `~/.local/share/konsole/ModernLight.colorscheme` | `konsole --profile ModernLight` |
| **Konsole Profile (Dark)**| `files/konsole/ModernDark.profile` | `~/.local/share/konsole/ModernDark.profile` | `konsole --profile ModernDark` |
| **Konsole Profile (Light)**| `files/konsole/ModernLight.profile` | `~/.local/share/konsole/ModernLight.profile` | `konsole --profile ModernLight` |
| **Konsole App Config** | `files/konsole/konsolerc` | `~/.config/konsolerc` | Reread on Konsole launch |
| **KWin Rules & Snapping**| `files/kwin/kwinrc` | `~/.config/kwinrc` | `qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure` |
| **Window Shadows & Windeco**| `files/kwin/breezerc` | `~/.config/breezerc` | `qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure` |
| **Lock Screen Config** | `files/lockscreen/kscreenlockerrc` | `~/.config/kscreenlockerrc` | `/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing` |
| **Cursor (Bibata Ice)** | `files/cursor/Bibata-Modern-Ice/` | `~/.local/share/icons/Bibata-Modern-Ice/` | `kcminputrc` / `~/.icons/default/index.theme` |
| **GTK 3 Config** | `files/gtk/gtk-3.0/settings.ini` | `~/.config/gtk-3.0/settings.ini` | Reread on GTK3 app launch |
| **GTK 4 Config** | `files/gtk/gtk-4.0/settings.ini` | `~/.config/gtk-4.0/settings.ini` | Reread on GTK4 app launch |
| **SDDM Login Config** | `files/sddm/20-kubuntu.conf` | `/etc/sddm.conf.d/20-kubuntu.conf` | System reboot / SDDM service restart |
| **SDDM Theme Config** | `files/sddm/kubuntu-theme.conf` | `/usr/share/sddm/themes/kubuntu/theme.conf` | `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/kubuntu` |

---

## 2. Deep Dive: Architectural Subsystems & Bug Fixes

### A. Dolphin File Explorer (Qt6 / QSS / KIOFileWidgets)

#### 1. Pitch-Black Breadcrumb Bar (`KUrlNavigator`) in Light Mode
* **Root Cause**: `KUrlNavigator` inherits `QWidget`. In its C++ painting routine (`KUrlNavigator::paintEvent`), it paints its background using `QStyle::PE_PanelLineEdit` with:
  ```cpp
  option.palette.setColor(QPalette::Base, palette().alternateBase().color());
  ```
  When un-synchronized or falling back to the dark palette, Qt's `alternateBase` is `rgb(29, 31, 34)` (`#1d1f22`). Without explicit QSS targeting `KUrlNavigator`, the location bar paints jet black, rendering black text on a black bar.
* **The Fix**: Explicit styling rules in `~/.config/dolphin-light.qss` and `~/.config/dolphin-dark.qss`:
  ```css
  KUrlNavigator, KUrlNavigator > QWidget {
      background-color: #f0f2f5;
      color: #181a1c;
      border: none;
  }
  KUrlNavigatorButton {
      background-color: transparent;
      color: #181a1c;
      border: none;
      padding: 3px 6px;
      border-radius: 4px;
  }
  KUrlNavigatorButton:hover {
      background-color: #e2e8f0;
      color: #181a1c;
  }
  KUrlNavigatorButton:checked, KUrlNavigatorButton:pressed {
      background-color: #d0dae6;
      color: #181a1c;
  }
  KUrlNavigator QLineEdit, KUrlComboBox {
      background-color: #ffffff;
      color: #181a1c;
      border: 1px solid #d0d4dc;
      border-radius: 4px;
      padding: 3px 6px;
  }
  ```

#### 2. White Text on Slate Selection & Dark Teal Inactive Block
* **Root Cause**: The Places sidebar uses `KFilePlacesView` (derived from `QListView`) with `KFilePlacesViewDelegate`. In `KFilePlacesViewDelegate::paint`:
  ```cpp
  painter->setPen(selectedAndActive ? opt.palette.highlightedText().color() : opt.palette.text().color());
  ```
  `opt.palette.highlightedText()` reads `ForegroundActive` from `[Colors:Selection]` in the color scheme. Stock Breeze themes set `ForegroundActive=255,255,255` (white text). On our soft light slate-blue selection (`#d0dae6` / `208,218,230`), white text had near-zero contrast.
  Furthermore, `[ColorEffects:Inactive] ChangeSelectionColor=true` dynamically computed an inactive selection color by tinting with dark slate, producing an illegible `#1b4155` dark teal block when the window lost focus.
* **The Fix**: In `~/.local/share/color-schemes/ModernLight.colors`:
  ```ini
  [ColorEffects:Inactive]
  ChangeSelectionColor=false
  Enable=false

  [Colors:Selection]
  BackgroundNormal=208,218,230
  BackgroundAlternate=208,218,230
  ForegroundNormal=24,26,28
  ForegroundActive=24,26,28
  ForegroundInactive=40,44,48
  ```
  And in `dolphin-light.qss`:
  ```css
  QDockWidget QListView::item:selected,
  QDockWidget QListView::item:selected:active,
  QDockWidget QListView::item:selected:!active {
      background-color: #d0dae6;
      color: #181a1c;
      border: none;
  }
  ```

#### 3. Single-Instance D-Bus Wrapper Requirement
* **Mechanism**: In KDE 6, Dolphin is single-instance and registers on D-Bus as `org.kde.dolphin-<PID>`. If launched by desktop menus or systemd without arguments, it loads the default system stylesheet unless instructed otherwise.
* **The Fix**: We deployed `~/.local/bin/dolphin` wrapping `/usr/bin/dolphin -stylesheet ~/.config/dolphin.qss "$@"` and linked it with absolute path in `~/.local/share/applications/org.kde.dolphin.desktop`.

---

### B. Shell & Dynamic Island (`Panel.qml`)

#### 1. Dynamic Luminance Detection
* **File**: `~/.local/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml`
* **Mechanism**: Rather than hardcoding black (`#000000`) or white (`#ffffff`), `topIslandPill` evaluates the ITU-R BT.601 perceptual luminance formula on `Kirigami.Theme.backgroundColor`:
  ```qml
  Rectangle {
      id: topIslandPill
      visible: root.topEdge
      anchors.fill: floatingTranslucentItem
      radius: height / 2
      readonly property bool isLight: (Kirigami.Theme.backgroundColor.r * 0.299 +
                                       Kirigami.Theme.backgroundColor.g * 0.587 +
                                       Kirigami.Theme.backgroundColor.b * 0.114) > 0.5
      color: isLight ? "#f0f2f5" : "#181a1e"
      border.color: isLight ? "#d0d4dc" : "#282a30"
      border.width: 1
  }
  ```
  Whenever the desktop theme or color scheme changes, `Kirigami.Theme.backgroundColor` emits a change signal, immediately morphing the pill capsule between porcelain light (`#f0f2f5`) and deep charcoal (`#181a1e`).

#### 2. Bottom Dock Flush Right Alignment (0px Gap)
* **Mechanism**: In stock Plasma floating panels, horizontal margins are calculated with floating padding. For Panel 80 (bottom dock), the activator (`DockPin`) sat indented by ~8px from the right boundary.
* **The Fix**: Clamped `containment.Layout.preferredWidth` and set dock offset so that:
  - Left padding between the dock curve and the kickoff glyph is exactly 14px.
  - Right activator tile is flush with the right outer border (0px gap).

---

### C. Control Station (`KdeControlStation`)

#### 1. Unified Theme Switcher Execution
* **File**: `~/.local/share/plasma/plasmoids/KdeControlStation/contents/ui/main.qml`
* **File**: `~/.local/share/plasma/plasmoids/KdeControlStation/contents/ui/components/ColorSchemeSwitcher.qml`
* **Root Cause of Toggle Hang**: In Plasma 6 `Plasma5Support.DataSource` engine `"executable"`, connecting to the exact same command string twice (`connectSource(cmd)`) is cached by the engine and does not re-invoke the script.
* **The Fix**: Centralized execution in `main.qml`:
  ```qml
  function toggleTheme() {
      executable.connectSource("/bin/bash /home/zeromerge/.local/bin/desktop-theme toggle #" + Date.now());
  }
  ```
  Adding the dynamic `# timestamp` ensures every click is a unique source name that executes immediately and disconnects via `onNewData`.

#### 2. Card Styling in Light & Dark Modes
* **File**: `~/.local/share/plasma/plasmoids/KdeControlStation/contents/ui/lib/Card.qml`
  - In Dark Mode: Card background is `#21242b` (hover `#2b2f38`), border is transparent.
  - In Light Mode: Card background is `#ffffff` (hover `#e8edf2`), border is `1px solid #d8dee6`.
* **File**: `~/.local/share/plasma/plasmoids/KdeControlStation/contents/ui/FullRepresentation.qml`
  - Container background: `root.isDarkTheme ? "#181a1e" : "#f0f2f5"`.
  - Border: `root.isDarkTheme ? "#24262c" : "#d0d4dc"`.

---

### D. Window Behavior & Snapping (KWin)

* **File**: `~/.config/kwinrc`
* **Key Directives**:
  ```ini
  [Windows]
  BorderlessMaximizedWindows=true
  ElectricBorderMaximize=true
  ElectricBorderTiling=true
  ElectricBorderCornerRatio=0.25
  WindowSnapZone=10
  BorderSnapZone=10
  ```
  - `BorderlessMaximizedWindows=true`: Removes window titlebars when maximized, saving 36px vertical screen space. Unmaximizing is accomplished via edge drag or `Super + Down` / `Alt + F10`.
  - `ElectricBorderCornerRatio=0.25`: Enables quarter-tiling by dragging windows to the corners.
  - `WindowSnapZone=10`: Enables magnetic snapping between adjacent windows.
* **Soft Ambient Shadows (`~/.config/breezerc`)**:
  ```ini
  [Common]
  OutlineCloseButton=false
  ShadowColor=0,0,0
  ShadowSize=ShadowLarge
  ShadowStrength=80

  [Windeco]
  ButtonSize=ButtonNormal
  DrawBackgroundGradient=false
  DrawBorderOnMaximizedWindows=false
  TitleAlignment=AlignLeft
  ```
  - Replaces harsh 255-alpha black outline borders with diffused 80-alpha ambient drop shadows.

---

### E. Terminal & Konsole

* **Typography**: Installed JetBrains Mono Nerd Font (`~/.local/share/fonts/JetBrainsMono/`).
* **Files**:
  - `~/.local/share/konsole/ModernDark.colorscheme`: Deep `#141618` bg, 0.92 opacity, blur enabled, Tokyo Night/Catppuccin hybrid ANSI 16 palette.
  - `~/.local/share/konsole/ModernLight.colorscheme`: Crisp `#ffffff` bg, 0.96 opacity, blur enabled, high-contrast day palette.
  - `~/.local/share/konsole/ModernDark.profile` & `ModernLight.profile`: `TerminalMargin=10`, `ShowMenuBarByDefault=false`, `CursorShape=0` (block cursor with smooth blink).
* **Sync**: Controlled by `~/.local/bin/desktop-theme`, which updates `konsolerc` `[Desktop Entry] DefaultProfile`.

---

### F. Cursor Suite (Bibata Modern Ice)

* **Hook Locations**:
  1. `~/.config/kcminputrc`: `[Mouse] cursorTheme=Bibata-Modern-Ice`
  2. `~/.config/kdeglobals`: `[Mouse] cursorTheme=Bibata-Modern-Ice`
  3. `~/.icons/default/index.theme`: `Inherits=Bibata-Modern-Ice` (ensures legacy X11 / Wayland root fallback)
  4. `~/.config/gtk-3.0/settings.ini` & `gtk-4.0/settings.ini`: `gtk-cursor-theme-name=Bibata-Modern-Ice`
  5. `/etc/sddm.conf.d/20-kubuntu.conf`: `CursorTheme=Bibata-Modern-Ice` (ensures pre-login cursor matches desktop)

---

### G. GTK, Flatpak & Portal Synchronization

* **Hook Locations**:
  1. `~/.config/gtk-3.0/settings.ini`:
     - `gtk-theme-name`: `Breeze-Dark` (dark) / `Breeze` (light)
     - `gtk-icon-theme-name`: `Papirus-Dark` (dark) / `Papirus` (light)
     - `gtk-application-prefer-dark-theme`: `true` (dark) / `false` (light)
  2. `~/.config/gtk-4.0/settings.ini`: Same as GTK3.
  3. **XDG Desktop Portal & GNOME Interface**:
     - `gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'` / `'prefer-light'`
     - `gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'` / `'Breeze'`
     - `gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'` / `'Papirus'`
  - **Flatpak Sandbox Override**:
    ```bash
    flatpak override --user --filesystem=xdg-data/icons:ro
    ```
    Allows sandboxed Flatpaks (VS Code, Discord, Spotify) to read Papirus icons and receive portal color scheme changes without theme flashes.

---

### H. Lock Screen & SDDM Synchronization

* **Lock Screen (`~/.config/kscreenlockerrc`)**:
  - `desktop-theme` updates `[Greeter][Wallpaper][org.kde.image][General] Image` to match the active mode (`DarkestHour` in dark, `Flow` in light).
  - Verified with zero flicker using `/usr/lib/x86_64-linux-gnu/libexec/kscreenlocker_greet --testing`.
* **SDDM Login Greeter**:
  - Configuration in `/etc/sddm.conf.d/20-kubuntu.conf`.
  - Background set in `/usr/share/sddm/themes/kubuntu/theme.conf`:
    ```ini
    background=/usr/share/wallpapers/DarkestHour/contents/images/2560x1600.jpg
    ```
    Eliminates the stock Kubuntu blue gear splash.

---

## 3. Upstream Update Recovery Procedures

If a system update (`apt upgrade` or KDE Plasma point release) resets your desktop configurations, follow these targeted recovery steps:

### Scenario 1: Dolphin breadcrumbs turn black or sidebar highlight text is unreadable
1. Copy the fixed stylesheets:
   ```bash
   cp ~/.config/dolphin-light.qss ~/.config/dolphin.qss
   ```
2. Verify `ModernLight.colors` has `ForegroundActive=24,26,28`:
   ```bash
   grep -A 8 "\[Colors:Selection\]" ~/.local/share/color-schemes/ModernLight.colors
   ```
3. Restart Dolphin:
   ```bash
   killall dolphin && dolphin &
   ```

### Scenario 2: Dynamic Island turns pitch black in Light Mode or dock has padding gap
1. Verify `Panel.qml` contains the luminance formula:
   ```bash
   grep "isLight" ~/.local/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml
   ```
2. If overwritten, restore from the playbook:
   ```bash
   cp ~/kde-desktop-playbook/files/shell/org.kde.plasma.desktop/contents/views/Panel.qml ~/.local/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml
   kquitapp6 plasmashell && kstart plasmashell &
   ```

### Scenario 3: Control Station Appearance button doesn't toggle
1. Check that `main.qml` defines `toggleTheme()`:
   ```bash
   grep -n "toggleTheme" ~/.local/share/plasma/plasmoids/KdeControlStation/contents/ui/main.qml
   ```
2. Restore from playbook if needed:
   ```bash
   cp -r ~/kde-desktop-playbook/files/plasmoids/KdeControlStation ~/.local/share/plasma/plasmoids/
   kquitapp6 plasmashell && kstart plasmashell &
   ```

### Scenario 4: Window titlebars appear on maximized windows
1. Run:
   ```bash
   kwriteconfig6 --file kwinrc --group Windows --key BorderlessMaximizedWindows true
   qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure
   ```

---

## 4. Manual Selective Deployment Options

You can deploy or restore any single component using `./install.sh` flags:

```bash
# Full suite deployment
./install.sh --all

# Selective deployments
./install.sh --theme        # Only color schemes, modern-dock themes, and switcher
./install.sh --dolphin      # Only Dolphin QSS stylesheets, wrapper, and desktop entry
./install.sh --konsole      # Only Konsole profiles, colors, and JetBrains Mono
./install.sh --kwin         # Only borderless maximized, snapping, and soft shadows
./install.sh --cursor       # Only Bibata Modern Ice cursor and X11 inheritance
./install.sh --gtk          # Only GTK 3/4 settings and GNOME interface portal
./install.sh --lockscreen   # Only lock screen wallpaper and settings
./install.sh --shell        # Only Panel.qml dynamic island and bottom dock
./install.sh --plasmoids    # Only Control Station and DockPin plasmoids
```
