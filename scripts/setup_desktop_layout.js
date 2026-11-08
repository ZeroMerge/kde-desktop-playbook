// Plasma 6 Layout Setup Script: Modern Desktop Suite
// Bottom Floating Dock + Top-Center Control Station

// 1. Remove existing panels to avoid duplicates
var existingPanels = panels();
for (var i = 0; i < existingPanels.length; ++i) {
    existingPanels[i].remove();
}

// 2. Create Top-Center Status Capsule (Dynamic Morphing Island: KDE Control Station)
var topPanel = new Panel;
topPanel.location = "top";
topPanel.height = 30;
topPanel.alignment = "center";
topPanel.lengthMode = "fit";
topPanel.floating = true;
topPanel.hiding = "windowsgobelow";

var cs = topPanel.addWidget("KdeControlStation");
if (cs) {
    cs.currentConfigGroup = ["Appearance"];
    cs.writeConfig("icon", "configure-toolbars-symbolic");
}

// 3. Create Bottom Floating Dock
var bottomDock = new Panel;
bottomDock.location = "bottom";
bottomDock.height = 64;
bottomDock.alignment = "center";
bottomDock.lengthMode = "fit";
bottomDock.floating = true;
bottomDock.hiding = "windowsgobelow";

// Kickoff Application Launcher
var launcher = bottomDock.addWidget("org.kde.plasma.kickoff");

// Icons-Only Task Manager
var taskManager = bottomDock.addWidget("org.kde.plasma.icontasks");
if (taskManager) {
    taskManager.currentConfigGroup = ["General"];
    taskManager.writeConfig("launchers", [
        "applications:google-chrome.desktop",
        "applications:code.desktop",
        "applications:org.kde.dolphin.desktop",
        "applications:org.kde.konsole.desktop",
        "applications:systemsettings.desktop"
    ]);
}

// Custom Dock Pin Activator (Halved 16px, 0px Flush Right Margin, On-Top Toggle)
var dockPin = bottomDock.addWidget("org.kde.plasma.dockpin");

print("Desktop layout successfully generated: Top Capsule (id: " + topPanel.id + "), Bottom Dock (id: " + bottomDock.id + ")");
