import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Layout.fillHeight: true
    Layout.preferredWidth: 16
    Layout.minimumWidth: 16
    Layout.maximumWidth: 16
    Layout.leftMargin: -2

    readonly property var panelWindow: root.Window.window
    readonly property bool isStatic: panelWindow ? panelWindow.visibilityMode === 3 : false

    function toggleHiding() {
        if (!panelWindow) return;
        if (panelWindow.visibilityMode === 3) {
            // Switch back to normal dodge mode
            panelWindow.visibilityMode = 2; // DodgeWindows
        } else {
            // Make dock stick ON TOP of windows WITHOUT pushing windows up!
            panelWindow.visibilityMode = 3; // WindowsGoBelow
        }
    }

    fullRepresentation: Item {
        anchors.fill: parent

        Rectangle {
            id: activatorRect
            anchors.fill: parent
            anchors.leftMargin: -1
            anchors.rightMargin: -8
            anchors.topMargin: -4
            anchors.bottomMargin: -4
            radius: 0 // 0px sharp rectangular block

            // Solid blue (#3DAEE9) in static pinned mode; dark surface in normal dodge mode
            color: root.isStatic 
                   ? "#3DAEE9" 
                   : (mouseArea.containsMouse ? "#3a3e44" : "#24272b")

            // Clean 1px left separator
            Rectangle {
                width: 1
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: root.isStatic ? "#62c5ff" : "rgba(255, 255, 255, 0.12)"
            }

            // Minimal vertical pin indicator bar
            Rectangle {
                width: 2
                height: 12
                radius: 0
                anchors.centerIn: parent
                color: root.isStatic ? "#FFFFFF" : (mouseArea.containsMouse ? "#FFFFFF" : "#727880")
            }

            Behavior on color {
                ColorAnimation { duration: 120 }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.toggleHiding()
            }
        }
    }
}
