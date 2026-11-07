import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.0

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents

import "lib" as Lib
import "components" as Components
import "pages" as Pages
import "js/funcs.js" as Funcs 


Item {
    id: fullRep
    
    // PROPERTIES
    width: root.fullRepWidth
    height: wrapper.implicitHeight
    implicitWidth: width
    implicitHeight: height
    Layout.preferredWidth: root.fullRepWidth
    Layout.preferredHeight: wrapper.implicitHeight
    Layout.minimumWidth: Layout.preferredWidth
    Layout.maximumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight
    Layout.maximumHeight: Layout.preferredHeight
    clip: true

    property var layouts : [
        "layouts/Default.qml", 
        "layouts/ControlCenter.qml",
        "layouts/Flat.qml",
        "layouts/Tahoe.qml",
        "layouts/Custom.qml"
    ]

    property int defaultInitialWidth: root.fullRepWidth
    property int defaultInitialHeight: wrapper.implicitHeight

    property int newWidth: 0
    property int newHeight: 0

    property var activePage: wrapper

    property bool expanded: root.expanded

    Connections {
        target: root
        function onOpenPageRequested(pageName) {
            if (pageName === "nightlight") {
                fullRep.togglePage(fullRep.defaultInitialWidth, 260, nightLightPage);
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#181a1e"
        radius: 4
        border.color: "#24262c"
        border.width: 1
        z: -1
    }

    // System session actions page
    Pages.SystemSessionActionsPage {
        id: systemSessionActionsPage
    }

    // Night Light Page
    Pages.NightLightPage {
        id: nightLightPage
    }

    // Volume devices Page
    Pages.VolumePage {
        id: volumePage
    }

    // Battery devices Page
    Pages.BatteryPage {
        id: batteryPage
    }

    // Media player Page
    Pages.MediaPlayerPage {
        id: mediaPlayerPage
    }

    // Brightness control Page
    Pages.BrightnessControlPage {
        id: brightnessControlPage
    }

    // Bluetooth control Page
    Pages.BluetoothPage {
        id: bluetoothPage
    }

    // Network control Page
    Pages.NetworkPage {
        id: networkPage
    }

    Loader {
        id: wrapper
        source: fullRep.layouts[plasmoid.configuration.layout]
        active: true
        asynchronous: true
        anchors.fill: parent
        visible: true
        property bool shown: true
        states: [
            State {
                name: "show"; when: wrapper.shown
                PropertyChanges { target: wrapper; opacity: 1 }
                PropertyChanges { target: wrapper; visible: true }
            },

            State {
                name: "hide"; when: !wrapper.shown
                PropertyChanges { target: wrapper; opacity: 0 }
                PropertyChanges { target: wrapper; visible: false }
            }
        ]

        transitions: Transition {
            PropertyAnimation { target: wrapper; property: "opacity"; easing.type: Easing.InOutQuad; duration: 20 }
        }
    }

    function togglePage(width = defaultInitialWidth, height = defaultInitialHeight, page = activePage) {
        newHeight = Math.max(340, height);
        newWidth = width > 0 ? width : defaultInitialWidth;
        
        if (wrapper.shown) {
            activePage = page;
            wrapper.shown = false;
            activePage.shown = true;
            fullRep.Layout.preferredWidth = newWidth;
            fullRep.Layout.preferredHeight = newHeight;
        } else {
            if (activePage) {
                activePage.shown = false;
            }
            wrapper.shown = true;
            fullRep.Layout.preferredWidth = defaultInitialWidth;
            fullRep.Layout.preferredHeight = defaultInitialHeight;
        }
    }

    onExpandedChanged: {
        if(!wrapper.shown) {
            togglePage();
        }
    }
}
