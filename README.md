# Modern Desktop Suite for KDE Plasma 6 (Ansible Playbook & Installer)

Automated provisioning and customization suite for modern Kubuntu / KDE Plasma 6 on Wayland.
Wraps all desktop refinements, edge flush-fitting fixes, on-top dock behaviors, blur-free performance optimizations, and the unified macOS-style Control Center into a reproducible Ansible playbook and turnkey installer script.

---

## Architecture & What Gets Deployed

```
┌────────────────────────────────────────────────────────┐
│             [ 19:50  •  (Switch Toggle) ]              │  <-- Top Status Capsule (Option 3)
│                                                        │      (Digital Clock + KDE Control Station)
│                                                        │
│                                                        │
│                     Active Windows                     │  <-- Maximized windows remain unpushed
│                                                        │
│                                                        │
│       [ Kickoff | Chrome | VSCode | Files | [|] ]       │  <-- Bottom Floating Dock
└────────────────────────────────────────────────────────┘      (Flush 0px Activator, On-Top Pinned Mode)
```

### 1. Top-Center Status Capsule (`Option 3: KDE Control Station`)
* **Placement**: Top-center floating panel (`height = 36px`, `alignment = center`, `lengthMode = fit`, `floating = true`, `hiding = windowsgobelow`).
* **Widgets**:
  - **Digital Clock**: Clean time readout (`HH:mm`), clean and non-cluttered.
  - **KDE Control Station**: Interactive dual-slider toggle button.
* **Control Center Card**:
  - Full-width tactile sliders for **Display Brightness** and **Audio Volume**.
  - One-click quick action tiles for **Wi-Fi**, **Bluetooth**, **Do Not Disturb**, **KDE Connect**, **Night Light**, and **Dark Theme Switcher**.
  - Integrated MPRIS media player card showing song title, artist, live track progress, and playback controls.
  - User and power shortcuts (`Abundant Joel`, `zeromerge@homelab`, battery level, power/lock).
  - High-contrast solid dark styling (`#1e2024`) with zero background bleed-through.

### 2. Bottom Floating Dock & Flush Activator
* **Flush Right Boundary (0px Gap)**: Activator rectangle extends flush to the outer border of the dock with zero gap.
* **Halved Activator Footprint**: Slim 16px wide tile with a 2px vertical pin accent.
* **On-Top Mode (`WindowsGoBelow`)**: Stays on top of full-screen windows without reserving workspace struts or shrinking maximized windows.
* **Smooth 60fps Transition**: Eliminates dynamic Gaussian blur and contrast filter effects for clean, instant sliding animations.

---

## Directory Structure

```
kde-desktop-playbook/
├── .gitignore                         # Git ignore rules for bytecode & editor artifacts
├── README.md                          # Documentation
├── desktop.yml                        # Main Ansible Playbook
├── inventory.ini                      # Localhost connection definition
├── install.sh                         # Turnkey dual-mode installer (Ansible or pure Bash)
│
├── python-services/                   # Custom Python Desktop Suite (Option 4)
│   ├── dynamic_island.py              # Custom PyQt6 Wayland dynamic island service
│   ├── bottom_dock.py                 # Custom PyQt6 physics dock
│   ├── start_desktop.sh               # Runner script
│   └── modern-desktop.service         # systemd user unit
│
├── scripts/                           # Layout scripts & test tools
│   ├── setup_desktop_layout.js        # Plasma JS script constructing panels & applets
│   ├── apply_layout.sh                # Helper script to execute layout via Plasma D-Bus
│   └── mpris_player.py                # Standalone MPRIS2 test player daemon
│
└── files/                             # Provisioning files used by Ansible playbook
    ├── plasmoids/
    │   ├── org.kde.plasma.dockpin/    # Custom 16px flush on-top dock pin activator
    │   ├── KdeControlStation/         # Option 3 Control Station (patched for Plasma 6)
    │   └── com.manu028.dynamicisland/ # Option 2 Dynamic Island (community alternative)
    ├── shell/
    │   └── org.kde.plasma.desktop/    # Custom zero-margin Panel.qml
    ├── themes/
    │   └── modern-dock/               # Custom dark 0px blur-free desktop theme
    ├── python-services/               # Standalone Python desktop suite files
    └── scripts/
        ├── setup_desktop_layout.js
        └── apply_layout.sh
```

---

## Git Repository Setup

This folder is initialized as a standalone Git repository:

```bash
cd /home/zeromerge/.gemini/antigravity/scratch/kde-desktop-playbook

# Add your remote GitHub / GitLab / Gitea repository:
git remote add origin git@github.com:YOUR_USERNAME/kde-modern-desktop.git

# Push to your remote repository:
git branch -M main
git push -u origin main
```

---

## Quick Start / How to Run on a New Machine

### Option A: Using the Automated Installer (Recommended)
On any fresh machine, simply clone or copy this repository and run:

```bash
chmod +x install.sh
./install.sh
```
* If Ansible is installed on the machine, it executes `desktop.yml` via `ansible-playbook`.
* If Ansible is not installed, it automatically runs the native Shell Installer mode with zero extra dependencies required!

### Option B: Using Ansible Directly
If you already use Ansible:

```bash
# Run locally (add -K if you want to install system apt packages)
ansible-playbook -i inventory.ini desktop.yml -K
```

Or skip apt packages and only configure user desktop files and plasma:
```bash
ansible-playbook -i inventory.ini desktop.yml --skip-tags packages
```

---

## Compatibility Fixes Included for Plasma 6
1. **Kirigami.Units Port**: Replaced legacy `PlasmaCore.Units` with modern `Kirigami.Units` in `MainView.qml`.
2. **Guarded Array Bounds**: Guarded uninitialized `powerManagementItem.inhibitions` in `PowerManagementItem.qml`.
3. **Strict Boolean Casts**: Fixed uninitialized boolean properties in `VolumePage.qml`.
4. **Shell Padding Zeroing**: Zeroed horizontal floating padding in `Panel.qml` so applet containers extend 100% flush to the physical dock boundary.
5. **Blur Calculations Removed**: Disabled dynamic blur effects in `plasmarc` and SVG themes to prevent KWin frame-drops during dock show/hide events.
