import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.0
import "../components" as Components
import "components/ControlCenter" as LayoutComponents 
ColumnLayout {
    id: wrapper

    anchors.fill: parent
    anchors.margins: 4
    spacing: 4

    RowLayout {
        id: header
        spacing: 4
        Layout.fillWidth: true
        Layout.preferredHeight: root.sectionHeight/3.3
        anchors.margins: 0
        visible: header.children.length > 0
        
        Components.UserAvatar{
            isLongButton: true
            smallTopMargins: true
            smallBottomMargins: true
        }
        Components.Battery {
            id: mainBatteryWidget
            Layout.preferredWidth: header.Layout.preferredHeight * 1.7
            Layout.maximumWidth: Layout.preferredWidth
        }
        Components.SystemActions{
            Layout.preferredWidth: header.Layout.preferredHeight
            Layout.maximumWidth: Layout.preferredWidth
        }
    }

    RowLayout {
        id: sectionA

        spacing: 4
        anchors.margins: 0

        Layout.preferredHeight: root.sectionHeight
        Layout.maximumHeight: root.sectionHeight 
        
        // Network, Bluetooth and Settings Button
        LayoutComponents.LeftColumn{}

        // Screen controls section
        LayoutComponents.RightColumn{}
    }
    RowLayout {
        id: slidersRow
        Layout.fillWidth: true
        Layout.preferredHeight: root.sectionHeight / (root.brightness_widget_title ? 2.2 : 2.8)
        spacing: 4

        Components.BrightnessSlider{
            id: brightnessSlider
            Layout.fillWidth: true
            Layout.fillHeight: true
            canTogglePage: true
        }
        Components.Volume{
            id: volumeSlider
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
    Components.MediaPlayer{
        Layout.preferredHeight: root.sectionHeight/2
    }
}