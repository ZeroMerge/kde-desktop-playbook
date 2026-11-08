import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: compactRep
    clip: false

    readonly property bool useCustomButtonImage: (Plasmoid.configuration.useCustomButtonImage && Plasmoid.configuration.customButtonImage.length != 0)
    readonly property bool isCollapsed: root.islandCollapsed

    readonly property var activeIconSource: {
        if (compactRep.useCustomButtonImage) {
            return Plasmoid.configuration.customButtonImage;
        }
        var iconName = Plasmoid.configuration.icon;
        if (!iconName || iconName === "configure" || iconName === "configure-toolbars-symbolic" || iconName === "control-center-symbolic") {
            return Qt.resolvedUrl("../icons/control-center-symbolic.svg");
        }
        return iconName;
    }

    // Live clock & date strings
    property string currentTimeStr: Qt.formatTime(new Date(), "hh:mm")
    property string currentDateStr: Qt.formatDate(new Date(), "ddd, MMM d")
    property string fullDateStr: Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
    property bool showDateInsteadOfTime: false

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            currentTimeStr = Qt.formatTime(now, "hh:mm");
            currentDateStr = Qt.formatDate(now, "ddd, MMM d");
            fullDateStr = Qt.formatDate(now, "dddd, MMMM d, yyyy");
        }
    }

    // Geometry & Layout:
    readonly property int iconSize: 14
    readonly property int contentHeight: 22
    readonly property int circleSize: 0

    // Expanded target width (enforce even integer to guarantee symmetrical subpixel recentering)
    readonly property int textWidth: Math.ceil(clockLabel.implicitWidth)
    readonly property int rawExpandedWidth: textWidth + iconSize + 22
    readonly property int expandedWidth: (rawExpandedWidth % 2 === 0) ? rawExpandedWidth : rawExpandedWidth + 1
    readonly property int targetWidth: isCollapsed ? circleSize : expandedWidth

    // Fluid Framer-Motion liquid spring width animation
    property real animatedWidth: targetWidth

    Behavior on animatedWidth {
        NumberAnimation {
            id: widthAnim
            duration: 380
            easing.type: Easing.OutBack
            easing.overshoot: compactRep.isCollapsed ? 1.0 : 1.12
        }
    }

    readonly property bool isMorphing: widthAnim.running

    // Strictly even integer implicitWidth clamped to 0:
    // (1920 - W) / 2 produces integer coordinates with 0 remainder,
    // eliminating Wayland LayerShell horizontal alternating coordinate oscillation (jitter/shaking)
    implicitWidth: Math.max(0, Math.round(animatedWidth / 2) * 2)
    implicitHeight: contentHeight

    Layout.preferredWidth: implicitWidth
    Layout.minimumWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.preferredHeight: contentHeight
    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    Item {
        id: container
        anchors.centerIn: parent
        width: compactRep.isCollapsed && !compactRep.isMorphing ? compactRep.iconSize : Math.max(compactRep.iconSize, compactRep.implicitWidth)
        height: parent.height

        // Collapsible Clock Container: animates width, scale, opacity, and clips content
        Item {
            id: clockWrapper
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            height: compactRep.contentHeight
            clip: true
            visible: !compactRep.isCollapsed || compactRep.isMorphing

            width: compactRep.isCollapsed ? 0 : compactRep.textWidth
            opacity: compactRep.isCollapsed ? 0.0 : 1.0
            scale: compactRep.isCollapsed ? 0.75 : 1.0

            Behavior on width {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutBack
                    easing.overshoot: compactRep.isCollapsed ? 1.0 : 1.12
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.InOutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutBack
                    easing.overshoot: compactRep.isCollapsed ? 1.0 : 1.12
                }
            }

            PlasmaComponents.Label {
                id: clockLabel
                anchors.centerIn: parent
                text: compactRep.showDateInsteadOfTime ? compactRep.currentDateStr : compactRep.currentTimeStr
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Single Control Center Symbolic Icon:
        // When collapsed: centered in container (exact geometric center of 1:1 circle)
        // When expanded: positioned on right side of container with smooth spring gliding
        Kirigami.Icon {
            id: controlIcon
            width: compactRep.iconSize
            height: compactRep.iconSize
            source: compactRep.activeIconSource
            smooth: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: (compactRep.isCollapsed && !compactRep.isMorphing) ? undefined : parent.right
            anchors.rightMargin: (compactRep.isCollapsed && !compactRep.isMorphing) ? 0 : 2
            anchors.horizontalCenter: (compactRep.isCollapsed && !compactRep.isMorphing) ? parent.horizontalCenter : undefined
            opacity: mouseArea.containsMouse ? 1.0 : 0.88
        }
    }

    // Debounce timer for distinguishing single click from double click
    Timer {
        id: singleClickTimer
        interval: 220
        onTriggered: {
            if (pendingAction === "toggleExpanded") {
                root.expanded = !root.expanded;
            } else if (pendingAction === "toggleDate") {
                compactRep.showDateInsteadOfTime = !compactRep.showDateInsteadOfTime;
            }
            pendingAction = "";
        }
    }

    property string pendingAction: ""

    MouseArea {
        id: mouseArea
        anchors.centerIn: parent
        width: Math.max(30, parent.width)
        height: Math.max(30, parent.height)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        // NO TOOLTIPS ON HOVER - per user explicit requirement

        onClicked: mouse => {
            if (compactRep.isCollapsed) {
                compactRep.pendingAction = "toggleExpanded";
            } else {
                if (mouse.x < (clockWrapper.x + clockWrapper.width + 4)) {
                    compactRep.pendingAction = "toggleDate";
                } else {
                    compactRep.pendingAction = "toggleExpanded";
                }
            }
            singleClickTimer.restart();
        }

        onDoubleClicked: mouse => {
            singleClickTimer.stop();
            compactRep.pendingAction = "";
            root.toggleIslandShape();
        }
    }
}
