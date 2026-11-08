import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "js/colorType.js" as ColorType
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    
    clip: false

    // Suppress default plasmoid hover tooltips
    toolTipMainText: ""
    toolTipSubText: ""

    // PROPERTIES
    property bool animations: plasmoid.configuration.animations
    property bool enableTransparency: Plasmoid.configuration.transparency
    property int transparencyLevel: Plasmoid.configuration.transparencyLevel
    property bool showBorders: Plasmoid.configuration.showBorders
    property var animationDuration: Kirigami.Units.veryShortDuration

    property bool preferChangeGlobalTheme: Plasmoid.configuration.preferChangeGlobalTheme
    property string generalLightTheme: preferChangeGlobalTheme ? Plasmoid.configuration.lightGlobalTheme : Plasmoid.configuration.lightTheme
    property string generalDarkTheme: preferChangeGlobalTheme ? Plasmoid.configuration.darkGlobalTheme : Plasmoid.configuration.darkTheme

    property var scale: Plasmoid.configuration.scale * 1 / 100
    property int fullRepWidth: { 
        switch (plasmoid.configuration.layout) {
            case 0: return 420 * scale;
            case 3: return 330 * scale;
            case 4: return 330 * scale; //custom/
            default: return 380 * scale
        }
    }
    property int fullRepHeight: 380 * scale
    property int sectionHeight: 180 * scale

    property int largeSpacing: 12 * scale
    property int mediumSpacing: 8 * scale
    property int smallSpacing: 6 * scale

    property int buttonMargin: 4 * scale
    property int buttonHeight: 48 * scale

    property int largeFontSize: 15 * scale
    property int mediumFontSize: 13 * scale
    property int smallFontSize: 11 * scale

    property int itemSpacing: 8

    // COlors variables
    property color themeBgColor: Kirigami.Theme.backgroundColor
    property color themeHighlightColor: Kirigami.Theme.highlightColor
    property bool isDarkTheme: ColorType.isDark(themeBgColor)
    property color disabledBgColor: isDarkTheme ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(0, 0, 0, 0.15)
    property color redColor: Kirigami.Theme.negativeTextColor
    
    // Main Icon
     Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon
    
    // Components
    property bool showKDEConnect: Plasmoid.configuration.showKDEConnect
    property bool showNightLight: Plasmoid.configuration.showNightLight
    property bool showColorSwitcher: Plasmoid.configuration.showColorSwitcher
    property bool showDnd: Plasmoid.configuration.showDnd
    property bool showVolume: Plasmoid.configuration.showVolume
    property bool showBrightness: Plasmoid.configuration.showBrightness
    property bool showMediaPlayer: Plasmoid.configuration.showMediaPlayer
    property bool showAvatar: Plasmoid.configuration.showAvatar
    property bool showBattery: Plasmoid.configuration.showBattery
    property bool showSessionActions: Plasmoid.configuration.showSessionActions
    property bool showScreenshot: Plasmoid.configuration.showScreenshot
    property bool showCmd1: Plasmoid.configuration.showCmd1
    property bool showCmd2: Plasmoid.configuration.showCmd2
    property bool showPercentage: Plasmoid.configuration.showPercentage
    
    property string cmdRun1: Plasmoid.configuration.cmdRun1
    property string cmdTitle1: Plasmoid.configuration.cmdTitle1
    property string cmdIcon1: Plasmoid.configuration.cmdIcon1
    property string cmdRun2: Plasmoid.configuration.cmdRun2
    property string cmdTitle2: Plasmoid.configuration.cmdTitle2
    property string cmdIcon2: Plasmoid.configuration.cmdIcon2

    property bool volume_widget_flat: Plasmoid.configuration.volume_widget_flat
    property bool volume_widget_title: Plasmoid.configuration.volume_widget_title
    property bool volume_widget_thin: Plasmoid.configuration.volume_widget_thin
    property bool brightness_widget_flat: Plasmoid.configuration.brightness_widget_flat
    property bool brightness_widget_title: Plasmoid.configuration.brightness_widget_title
    property bool brightness_widget_thin: Plasmoid.configuration.brightness_widget_thin

    property bool useSystemColorsOnToggles: Plasmoid.configuration.useSystemColorsOnToggles
    property bool useSystemColorsOnSliders: Plasmoid.configuration.useSystemColorsOnSliders
    property color toggleButtonsColor: Plasmoid.configuration.toggleButtonsColor
    property color toggleButtonsIconColor: Plasmoid.configuration.toggleButtonsIconColor
    property color slidersColor: Plasmoid.configuration.slidersColor
    property bool usePlasmaSliders: Plasmoid.configuration.usePlasmaSliders

    property bool hideWidgetBeforeScreenshot: Plasmoid.configuration.hideWidgetOnScreenshot
    property string screenshotCommand: Plasmoid.configuration.screenshotCommand

    property bool editingLayout: false

    // Enables quick action(triggering action when clicking icon) on Quick toggle buttons
    property bool enableQuickActions: Plasmoid.configuration.enableQuickActions

    // Dynamic Island morphing state
    property bool islandCollapsed: Boolean(Plasmoid.configuration.islandCollapsed)

    function toggleIslandShape() {
        var nextState = !islandCollapsed;
        islandCollapsed = nextState;
        Plasmoid.configuration.islandCollapsed = nextState;
        console.log("ISLAND_TOGGLED: islandCollapsed is now", nextState);
    }

    readonly property var layouts: {
        "Default": 0, 
        "ControlCenter": 1,
        "Flat": 2,
        "Tahoe": 3,
        "Custom": 4
    }

    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)

    property int plasmaVersion

    signal openPageRequested(string pageName)

    function toggleTheme() {
        executable.connectSource("/bin/bash /home/zeromerge/.local/bin/desktop-theme toggle #" + Date.now());
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: ["plasmashell -v"]
        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0 && data.stdout) {
                var out = (data.stdout || "").trim();
                if (sourceName.indexOf("plasmashell -v") !== -1) {
                    plasmaVersion = out.split(" ")[1].split(".")[1];
                }
                if (sourceName.indexOf("/tmp/control_station_cmd") !== -1) {
                    if (out === "open") {
                        root.expanded = true;
                    } else if (out === "close") {
                        root.expanded = false;
                    } else if (out === "toggle") {
                        root.expanded = !root.expanded;
                    } else if (out === "nightlight") {
                        root.expanded = true;
                        root.openPageRequested("nightlight");
                    } else if (out === "island_toggle") {
                        root.toggleIslandShape();
                    } else if (out === "theme_toggle") {
                        executable.connectSource("/bin/bash /home/zeromerge/.local/bin/desktop-theme toggle #" + Date.now());
                    }
                }
            }
            disconnectSource(sourceName);
        }
    }

    Timer {
        id: cmdTimer
        interval: 350
        repeat: true
        running: true
        onTriggered: {
            executable.connectSource("if [ -f /tmp/control_station_cmd ]; then cat /tmp/control_station_cmd && rm -f /tmp/control_station_cmd; fi #" + Date.now());
        }
    }
    
    switchHeight: fullRepWidth
    switchWidth: fullRepWidth
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    fullRepresentation: FullRepresentation { }
    compactRepresentation: CompactRepresentation {}

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Layout")
            icon.name: "document-edit-symbolic"
            visible: (Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable) 
                     && Plasmoid.configuration.layout == layouts.Custom
            onTriggered: root.editingLayout = true
        }
    ]
}
