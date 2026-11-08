import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.volume as Vol
import org.kde.kitemmodels as KItemModels

import "../lib" as Lib

Item {
    id: volumeControl

    Layout.fillHeight: true
    Layout.fillWidth: true

    property var currentSink: null

    property bool canTogglePage: true
    property bool glassEffect: false
    property int cornerRadius: roundedWidget ? 22 : 4
    property bool mediumSizeSlider: false

    property bool flat: false
    property bool isLongButton: true
    property bool roundedWidget: false
    property bool showTitle: true

    Vol.SinkModel {
        id: paSinkModel
        onCountChanged: updateSink()
        onDataChanged: updateSink()
        onModelReset: updateSink()
        onRowsInserted: updateSink()
    }

    Connections {
        target: Vol.PreferredDevice
        function onSinkChanged() {
            updateSink();
        }
    }

    function updateSink() {
        if (Vol.PreferredDevice && Vol.PreferredDevice.sink) {
            volumeControl.currentSink = Vol.PreferredDevice.sink;
            sliderLoader.active = true;
            return;
        }

        if (paSinkModel.count === 0) return;

        var defaultRole = paSinkModel.KItemModels.KRoleNames.role("Default");
        var pulseObjectRole = paSinkModel.KItemModels.KRoleNames.role("PulseObject");
        var defaultSink = null;
        var firstSink = null;

        for (var i = 0; i < paSinkModel.count; ++i) {
            var idx = paSinkModel.index(i, 0);
            var sinkObj = paSinkModel.data(idx, pulseObjectRole);
            if (!sinkObj) continue;
            if (!firstSink) firstSink = sinkObj;
            if (paSinkModel.data(idx, defaultRole) === true) {
                defaultSink = sinkObj;
                break;
            }
        }

        var chosen = defaultSink || firstSink;
        if (chosen) {
            volumeControl.currentSink = chosen;
            sliderLoader.active = true;
        }
    }

    Component.onCompleted: {
        updateSink();
    }

    visible: (typeof root !== "undefined" && typeof root.showVolume !== "undefined") ? root.showVolume : true

    Loader {
        id: sliderLoader
        active: Boolean(currentSink)
        anchors.fill: parent
        sourceComponent: sliderComponent
    }

    Component {
        id: sliderComponent

        Lib.Slider {
            id: sliderWidget

            title: i18n("Sound")
            canTogglePage: volumeControl.canTogglePage
            glassEffect: volumeControl.glassEffect
            cornerRadius: volumeControl.cornerRadius
            mediumSizeSlider: volumeControl.mediumSizeSlider
            roundedWidget: volumeControl.roundedWidget

            showTitle: (typeof root !== "undefined" && typeof root.volume_widget_title !== "undefined") ? root.volume_widget_title : true
            thinSlider: (typeof root !== "undefined" && typeof root.volume_widget_thin !== "undefined") ? root.volume_widget_thin : false
            flat: (typeof root !== "undefined" && typeof root.volume_widget_flat !== "undefined") ? root.volume_widget_flat : false

            from: 0
            to: 100
            stepSize: 1

            value: (currentSink && Vol.PulseAudio.NormalVolume) ? Math.round(currentSink.volume / Vol.PulseAudio.NormalVolume * 100) : 0
            secondaryTitle: value + "%"

            source: {
                if (!currentSink || currentSink.muted || value <= 0) return "audio-volume-muted";
                if (value <= 25) return "audio-volume-low";
                if (value <= 75) return "audio-volume-medium";
                return "audio-volume-high";
            }

            Connections {
                target: currentSink
                function onVolumeChanged() {
                    if (currentSink && !sliderWidget.pressed) {
                        sliderWidget.value = Math.round(currentSink.volume / Vol.PulseAudio.NormalVolume * 100);
                    }
                }
                function onMutedChanged() {
                    // Triggers source re-evaluation
                }
            }

            onPressedChanged: {
                if (!pressed && currentSink && typeof volumePage !== "undefined" && volumePage.playFeedback) {
                    var idx = (typeof currentSink.index !== "undefined") ? currentSink.index : 0;
                    volumePage.playFeedback(idx);
                }
            }

            onMoved: {
                if (currentSink && Vol.PulseAudio.NormalVolume) {
                    currentSink.volume = Math.round(value * Vol.PulseAudio.NormalVolume / 100);
                }
            }

            onClicked: {
                if (typeof volumePage !== "undefined" && typeof fullRep !== "undefined") {
                    var pageHeight = volumePage.contentItemHeight + volumePage.headerHeight;
                    fullRep.togglePage(fullRep.defaultInitialWidth, pageHeight, volumePage);
                }
            }

            property real oldVol: (Vol.PulseAudio && Vol.PulseAudio.NormalVolume) ? Vol.PulseAudio.NormalVolume : 65536
            onActionButtonClicked: {
                if (currentSink) {
                    if (value !== 0) {
                        oldVol = currentSink.volume;
                        currentSink.volume = 0;
                    } else {
                        currentSink.volume = oldVol > 0 ? oldVol : Math.round(Vol.PulseAudio.NormalVolume * 0.5);
                    }
                }
            }
        }
    }
}
