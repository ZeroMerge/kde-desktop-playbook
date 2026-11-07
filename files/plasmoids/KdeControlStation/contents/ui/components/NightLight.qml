import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.0

import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami 

import "../lib" as Lib

Lib.CardButton {
    id: nightLight

    Layout.fillHeight: true
    Layout.fillWidth: true

    visible: root.showNightLight
    title: i18n("Night Light")
    shouldStickIconSize: true

    property var control: nightLightPage.control

    Lib.Icon {
        id: icon
        anchors.fill: parent
        source: "weather-clear-night-symbolic"
        selected: control.running && !control.inhibited
        enableQuickAction: true
        onQuickActionTriggered: {
            if (control.togglable) {
                control.inhibited = !control.inhibited;
            }
        }
    }

    onClicked: {
        var pageHeight = Math.max(260, nightLightPage.contentItemHeight + nightLightPage.headerHeight);
        fullRep.togglePage(fullRep.defaultInitialWidth, pageHeight, nightLightPage);
    }
}
