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

    // Geometry:
    readonly property int iconSize: 14
    readonly property int contentHeight: 22
    readonly property int circleSize: 0

    readonly property int textWidth: Math.ceil(clockLabel.implicitWidth)
    readonly property int expandedWidth: textWidth + iconSize + 22
    readonly property int targetWidth: isCollapsed ? circleSize : expandedWidth

    implicitWidth: targetWidth
    implicitHeight: contentHeight



    Layout.preferredWidth: implicitWidth
    Layout.minimumWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.preferredHeight: contentHeight
    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 320
            easing.type: Easing.InOutCubic
        }
    }

    Item {
        id: container
        anchors.centerIn: parent
        width: compactRep.isCollapsed ? compactRep.iconSize : parent.width
        height: parent.height

        // Collapsed state: single centered icon in 1:1 circle
        Kirigami.Icon {
            id: collapsedIcon
            anchors.centerIn: parent
            width: compactRep.iconSize
            height: compactRep.iconSize
            source: compactRep.activeIconSource
            smooth: true
            visible: compactRep.isCollapsed
            opacity: mouseArea.containsMouse ? 1.0 : 0.88
        }

        // Expanded state: clock + icon row
        Row {
            id: expandedRow
            anchors.centerIn: parent
            spacing: 8
            visible: !compactRep.isCollapsed

            PlasmaComponents.Label {
                id: clockLabel
                anchors.verticalCenter: parent.verticalCenter
                text: compactRep.showDateInsteadOfTime ? compactRep.currentDateStr : compactRep.currentTimeStr
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: compactRep.iconSize
                height: compactRep.iconSize
                source: compactRep.activeIconSource
                smooth: true
                opacity: mouseArea.containsMouse ? 1.0 : 0.88
            }
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

        ToolTip.visible: containsMouse && !root.expanded
        ToolTip.text: compactRep.fullDateStr
        ToolTip.delay: 600

        onClicked: mouse => {
            if (compactRep.isCollapsed) {
                compactRep.pendingAction = "toggleExpanded";
            } else {
                if (mouse.x < clockLabel.implicitWidth + 8) {
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
