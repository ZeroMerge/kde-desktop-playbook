import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.volume as Vol

import "../lib" as Lib

Item {
    id: volumeControl

    Layout.fillHeight: true
    Layout.fillWidth: true

    property var currentSink: Vol.PreferredDevice.sink

    property bool canTogglePage: true
    property bool glassEffect: false
    property int cornerRadius: roundedWidget ? 22 : 4
    property bool mediumSizeSlider: false

    property bool flat: false
    property bool isLongButton: true
    property bool roundedWidget: false
    property bool showTitle: true

    Connections {
        target: Vol.PreferredDevice
        function onSinkChanged() {
            updateSink();
        }
    }

    function updateSink() {
        var s = Vol.PreferredDevice.sink;
        if (s) {
            volumeControl.currentSink = s;
            sliderLoader.active = true;
        }
    }

    Component.onCompleted: {
        updateSink();
    }

    visible: true

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
