import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRep
    
    readonly property bool useCustomButtonImage: (Plasmoid.configuration.useCustomButtonImage && Plasmoid.configuration.customButtonImage.length != 0)
    
    implicitWidth: 22
    implicitHeight: 22
    Layout.preferredWidth: 22
    Layout.preferredHeight: 22
    Layout.alignment: Qt.AlignVCenter

    Kirigami.Icon {
        anchors.centerIn: parent
        width: 14
        height: 14
        source: useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon
        smooth: true
        opacity: mouseArea.containsMouse ? 1.0 : 0.85
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.expanded = !root.expanded
        }
    }
}
