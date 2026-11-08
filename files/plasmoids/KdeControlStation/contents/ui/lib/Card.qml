import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Rectangle {
    id: rectangle
    color: "transparent"
    border.width: 1
    border.color: root.editingLayout ? root.disabledBgColor : "transparent"

    /******
     We need to gain space to display the shadow so we reduce top and bottom margins to avoid cut elements
     in small widgets such as UserAvatar 
    *******/
    property bool smallTopMargins: false
    property bool smallBottomMargins: false
    property bool smallLeftMargins: false
    property bool smallRightMargins: false
    /******
     This is used to manage widget background color so we can change the color depending on widget status(Command Run) 
    *******/
    property alias customBgColor: cardBg.color


    property bool flat: false

    property bool shadow: flat ? false : true

    property bool filled:  flat ? false : true

    property bool bordr:  flat ? false : true

    property bool glassEffect: false

    property bool noMargins: false

    property bool roundedWidget: false

    property int cornerRadius: roundedWidget ? 24 : 4

    property var margins: shadowContainer.margins
    default property alias content: dataContainer.data
    radius: 2

    property bool hovered: false
    property bool showContentOverflowIndicator: false

    signal clicked
    
    MouseArea {
        anchors.fill: contentOverflowIndicator
        enabled: !root.editingLayout
        hoverEnabled: enabled

        onEntered: rectangle.hovered = true;
        onExited: rectangle.hovered = false;

        onClicked: rectangle.clicked()
    }

    Item {
        id: shadowContainer
        visible: shadow
        
        anchors.fill: parent
        anchors.margins: 0
        layer.enabled: true

        opacity: 0.1 // This controls the opcity of the shadow
        clip: true

        /*
        * This is the real widget where the the shadow is drawn around, we applied some margins
        * to separate it from it's parent(container) so the shadow could be displayed
        */
        Rectangle {
            id: shadowWidget
            anchors.fill: parent
            anchors.margins: 0
            color: root.isDarkTheme ? root.themeBgColor : "#ffffff"
            radius: cornerRadius
        }
        DropShadow {
            anchors.fill: shadowWidget
            source: shadowWidget
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 1
            radius: 2
            samples: 5
            color: root.isDarkTheme ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(0, 0, 0, 0.08)
        }
    }

    Rectangle {
        id: cardBg; 
        color: !filled ? (rectangle.hovered ? (root.isDarkTheme ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.05)) : "transparent") :
                root.enableTransparency ? 
                Qt.rgba(root.themeBgColor.r, root.themeBgColor.g, root.themeBgColor.b, root.transparencyLevel/100)
                : (rectangle.hovered ? (root.isDarkTheme ? "#2b2f38" : "#e8edf2") : (root.isDarkTheme ? "#21242b" : "#ffffff"))

        border.color: root.isDarkTheme ? "transparent" : "#d8dee6"
        border.width: root.isDarkTheme ? 0 : 1
        anchors.centerIn: shadowContainer
        width: shadowWidget.width
        height: shadowWidget.height
        radius: cornerRadius
        z: -1
    }

    Item {
        id: dataContainer
        anchors.fill: parent
        anchors.topMargin: noMargins ? -1 : smallTopMargins ? 1 : 2
        anchors.bottomMargin: noMargins ? -1 : smallBottomMargins ? 1 : 2
        anchors.leftMargin: (noMargins || smallLeftMargins) ? -1 : 3
        anchors.rightMargin: (noMargins || smallRightMargins) ? -1 : 3
    }

    Rectangle {
        id: contentOverflowIndicator
        width: cardBg.width
        height: cardBg.height - 2
        color: "transparent"
        radius: cornerRadius
        visible: showContentOverflowIndicator
        opacity: rectangle.hovered ? 1 : 0
        
        anchors.right: cardBg.right
        anchors.rightMargin: 1
        anchors.verticalCenter: cardBg.verticalCenter

        Kirigami.Icon {
            source: "arrow-right"
            width: 15
            height: width
            scale: contentOverflowIndicator.opacity

            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter

        }

        Behavior on opacity { PropertyAnimation {} }
    }
}