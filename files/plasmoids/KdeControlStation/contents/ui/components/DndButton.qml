import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../lib" as Lib
import org.kde.notificationmanager as NotificationManager
import org.kde.kirigami as Kirigami

Lib.CardButton {
    id: dndBtn
    visible: root.showDnd
    Layout.fillWidth: true
    Layout.fillHeight: true
    title: i18n("Do Not Disturb")

    NotificationManager.Settings {
        id: notificationSettings
    }

    readonly property bool dndActive: {
        var until = notificationSettings.notificationsInhibitedUntil;
        if (until && !isNaN(until.getTime()) && Date.now() < until.getTime()) {
            return true;
        }
        return Boolean(notificationSettings.notificationsInhibitedByApplication);
    }

    onClicked: {
        if (dndActive) {
            notificationSettings.notificationsInhibitedUntil = undefined;
            notificationSettings.revokeApplicationInhibitions();
            notificationSettings.screensMirrored = false;
            notificationSettings.save();
        } else {
            var d = new Date();
            d.setFullYear(d.getFullYear() + 1);
            notificationSettings.notificationsInhibitedUntil = d;
            notificationSettings.save();
        }
    }

    Lib.Icon {
        id: dndIcon
        anchors.fill: parent
        customIcon: true
        source: dndActive ? Qt.resolvedUrl("../icons/feather/notifications-off.svg") : Qt.resolvedUrl("../icons/feather/notifications-on.svg")
        selected: dndActive
    }
}
