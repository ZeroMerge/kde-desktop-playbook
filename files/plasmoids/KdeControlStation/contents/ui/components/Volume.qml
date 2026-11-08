import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.volume as Vol

import "../lib" as Lib
import "../js/funcs.js" as Funcs

Item {
    id: volumeControl
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: sinkAvailable && root.showVolume

    property bool canTogglePage: true

    property bool glassEffect: false
    property int cornerRadius: roundedWidget ? 22 : 4
    property bool mediumSizeSlider: false

    property bool isLongButton: true
    property bool roundedWidget: false

    /* 
    * When using Custom layout we control these properties by changes
    * in context menu, otherwise it's controlled by sliders config in
    * plasmoid settings window-
    */

    property bool showTitle: (plasmoid && plasmoid.configuration && plasmoid.configuration.layout == root.layouts.Custom) ? true : root.volume_widget_title
    property bool flat: (plasmoid && plasmoid.configuration && plasmoid.configuration.layout == root.layouts.Custom) ? false : root.volume_widget_flat

    // Audio source
    property var sink: Vol.PreferredDevice.sink
    readonly property bool sinkAvailable: Boolean(sink && sink.name !== "auto_null")

    Loader {
        id: sliderLoader
        active: Boolean(sinkAvailable)
        anchors.fill: parent
        sourceComponent: sliderComponent
    }

    onSinkChanged: {
        if (sinkAvailable) {
            sliderLoader.active = true;
        }
    }

    Component.onCompleted: {
        if (sinkAvailable) {
            sliderLoader.active = true;
        }
    }

    Component {
        id: sliderComponent
        Lib.Slider {
            id: slider
            useIconButton: true
            title: i18n("Volume")
            canTogglePage: volumeControl.canTogglePage
            glassEffect: volumeControl.glassEffect
            cornerRadius: volumeControl.cornerRadius
            mediumSizeSlider: volumeControl.mediumSizeSlider
            roundedWidget: volumeControl.roundedWidget
            showTitle: volumeControl.showTitle
            thinSlider: root.volume_widget_thin
            flat: volumeControl.flat

            from: 0
            to: 100
            stepSize: 1

            value: (sink && Vol.PulseAudio.NormalVolume) ? Math.round(sink.volume / Vol.PulseAudio.NormalVolume * 100) : 0
            secondaryTitle: value + "%"

            // Changes icon based on the current volume percentage
            source: {
                if (!sink || sink.muted || value <= 0) return "audio-volume-muted";
                if (value <= 25) return "audio-volume-low";
                if (value <= 75) return "audio-volume-medium";
                return "audio-volume-high";
            }

            onPressedChanged: {
                if (!pressed && sink && typeof volumePage !== "undefined" && volumePage.playFeedback) {
                    var idx = (typeof sink.index !== "undefined") ? sink.index : sink.Index;
                    if (idx !== undefined) {
                        volumePage.playFeedback(idx);
                    }
                }
            }
            
            onMoved: {
                if (sink && Vol.PulseAudio.NormalVolume) {
                    sink.volume = Math.round(value * Vol.PulseAudio.NormalVolume / 100);
                }
            }
            
            // Display view that shows audio devices list
            onClicked: {
                if (typeof volumePage !== "undefined" && typeof fullRep !== "undefined") {
                    var pageHeight = volumePage.contentItemHeight + volumePage.headerHeight;
                    fullRep.togglePage(fullRep.defaultInitialWidth, pageHeight, volumePage);
                }
            }
            
            property real oldVol: (Vol.PulseAudio && Vol.PulseAudio.NormalVolume) ? Vol.PulseAudio.NormalVolume : 65536
            onActionButtonClicked: {
                if (sink) {
                    if (value !== 0) {
                        oldVol = sink.volume;
                        sink.volume = 0;
                    } else {
                        sink.volume = oldVol > 0 ? oldVol : Math.round(Vol.PulseAudio.NormalVolume * 0.5);
                    }
                }
            }
        }
    }
}
