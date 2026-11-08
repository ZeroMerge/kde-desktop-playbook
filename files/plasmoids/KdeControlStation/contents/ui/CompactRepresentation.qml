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

    // Geometry & Layout Metrics:
    readonly property int iconSize: 14
    readonly property int contentHeight: 22
    readonly property int leftPadding: 6
    readonly property int rightPadding: 6
    readonly property int spacing: 4

    // Expanded target width (enforce even integer to guarantee symmetrical coordinate centering)
    readonly property int textWidth: Math.ceil(clockLabel.implicitWidth)
    readonly property int rawExpandedWidth: leftPadding + textWidth + spacing + iconSize + rightPadding
    readonly property int expandedWidth: (rawExpandedWidth % 2 === 0) ? rawExpandedWidth : rawExpandedWidth + 1
    readonly property int targetWidth: isCollapsed ? 0 : expandedWidth

    // Fluid Framer-Motion liquid easing (organic InOutCubic liquid curve - zero jerk, smooth inertia, zero bounce)
    property real animatedWidth: targetWidth

    Behavior on animatedWidth {
        NumberAnimation {
            id: widthAnim
            duration: 400
            easing.type: Easing.InOutCubic
        }
    }

    readonly property real progress: expandedWidth > 0 ? Math.min(1.0, Math.max(0.0, animatedWidth / expandedWidth)) : (isCollapsed ? 0.0 : 1.0)
    readonly property bool isMorphing: widthAnim.running

    implicitWidth: Math.max(0, Math.round(animatedWidth / 2) * 2)
    implicitHeight: contentHeight

    Layout.preferredWidth: implicitWidth
    Layout.minimumWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.preferredHeight: contentHeight
    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    // Continuous icon horizontal positioning:
    // When progress = 0 (circle): icon is at -iconSize / 2 - 2 (exact 10px left/right/top/bottom padding in 30px circle)
    // When progress = 1 (pill): icon is at expandedWidth - rightPadding - iconSize
    readonly property real collapsedIconX: -iconSize / 2 - 2
    readonly property real expandedIconX: expandedWidth - rightPadding - iconSize
    readonly property real currentIconX: collapsedIconX + (expandedIconX - collapsedIconX) * progress

    // Collapsible Clock Container:
    // Synchronously animates width, opacity and scale driven purely by continuous progress
    Item {
        id: clockWrapper
        x: compactRep.leftPadding
        anchors.verticalCenter: parent.verticalCenter
        height: compactRep.contentHeight
        clip: true
        visible: opacity > 0.01

        width: Math.max(0, controlIcon.x - compactRep.leftPadding - compactRep.spacing)
        opacity: Math.max(0.0, Math.min(1.0, (compactRep.progress - 0.25) / 0.75))
        scale: 0.8 + 0.2 * Math.max(0.0, Math.min(1.0, (compactRep.progress - 0.25) / 0.75))

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

    // Control Center Symbolic Icon:
    Kirigami.Icon {
        id: controlIcon
        x: Math.round(compactRep.currentIconX)
        anchors.verticalCenter: parent.verticalCenter
        width: compactRep.iconSize
        height: compactRep.iconSize
        source: compactRep.activeIconSource
        smooth: true
        opacity: mouseArea.containsMouse ? 1.0 : 0.88
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
        x: compactRep.isCollapsed ? -15 : 0
        width: compactRep.isCollapsed ? 30 : Math.max(30, parent.width)
        height: Math.max(30, parent.height)
        anchors.verticalCenter: parent.verticalCenter
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        // Strict suppression of hover tooltips per user request
        ToolTip.visible: false

        onClicked: mouse => {
            if (compactRep.isCollapsed) {
                compactRep.pendingAction = "toggleExpanded";
            } else {
                if (mouse.x < (controlIcon.x - 2)) {
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
