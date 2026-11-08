import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.0

import org.kde.plasma.plasmoid
//import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami 

import "../lib" as Lib
import "../js/colorType.js" as ColorType

Lib.CardButton {
    id: colorSchemeSwitcher

    visible: root.showColorSwitcher
    Layout.fillHeight: true
    Layout.fillWidth: true
    title: root.isDarkTheme ? i18n("Dark Theme") : i18n("Light Theme")
    property string command: root.preferChangeGlobalTheme ? 
                            "plasma-apply-lookandfeel -a " : 
                            "plasma-apply-colorscheme "

    property alias sourceColor: icon.sourceColor
    
    Lib.Icon {
        id: icon
        anchors.fill: parent
        fullSizeIcon: colorSchemeSwitcher.fullSizeIcon
        source: Qt.resolvedUrl("../icons/feather/dark-mode.svg")
        selected: root.isDarkTheme
        customIcon: true
    }

    onClicked: {
        root.toggleTheme();
    }
}
