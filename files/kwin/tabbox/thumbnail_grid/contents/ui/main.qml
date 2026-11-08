/*
 * Modern Desktop Suite - Balanced Thumbnail Grid Task Switcher
 * Consistent geometry, uniform card spacing, and live window previews
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kwin as KWin
import org.kde.kirigami as Kirigami

KWin.TabBoxSwitcher {
    id: tabBox

    Instantiator {
        active: tabBox.visible
        delegate: PlasmaCore.Dialog {
            id: switcherDialog
            location: PlasmaCore.Types.Floating
            visible: true
            flags: Qt.Popup | Qt.X11BypassWindowManagerHint

            x: tabBox.screenGeometry.x + Math.round((tabBox.screenGeometry.width - dialogMainItem.width) / 2)
            y: tabBox.screenGeometry.y + Math.round((tabBox.screenGeometry.height - dialogMainItem.height) / 2)

            mainItem: FocusScope {
                id: dialogMainItem
                focus: true

                readonly property bool isDark: (Kirigami.Theme.backgroundColor.r * 0.299 +
                                                Kirigami.Theme.backgroundColor.g * 0.587 +
                                                Kirigami.Theme.backgroundColor.b * 0.114) < 0.5

                readonly property int totalCount: tabBox.model ? tabBox.model.rowCount() : 0

                // Proportional fixed card metrics
                readonly property int cardWidth: 260
                readonly property int cardHeight: 188
                readonly property int cardSpacing: 14
                readonly property int outerPadding: 16

                // Balanced, non-jagged grid columns
                readonly property int gridCols: {
                    if (totalCount <= 4) return Math.max(1, totalCount);
                    if (totalCount <= 6) return 3;
                    if (totalCount <= 8) return 4;
                    return Math.min(5, Math.max(4, Math.ceil(Math.sqrt(totalCount))));
                }
                readonly property int gridRows: Math.max(1, Math.ceil(totalCount / gridCols))

                width: outerPadding * 2 + (gridCols * cardWidth) + ((gridCols - 1) * cardSpacing)
                height: outerPadding * 2 + (gridRows * cardHeight) + ((gridRows - 1) * cardSpacing)

                // Dialog backdrop panel
                Rectangle {
                    anchors.fill: parent
                    color: dialogMainItem.isDark ? "#181a1e" : "#f5f6f8"
                    border.color: dialogMainItem.isDark ? "#2d3038" : "#d8dce4"
                    border.width: 1
                    radius: 16
                }

                GridView {
                    id: gridView
                    // Width accommodates all columns without early wrapping
                    width: dialogMainItem.gridCols * (dialogMainItem.cardWidth + dialogMainItem.cardSpacing)
                    height: dialogMainItem.gridRows * (dialogMainItem.cardHeight + dialogMainItem.cardSpacing)
                    anchors.left: parent.left
                    anchors.leftMargin: dialogMainItem.outerPadding
                    anchors.top: parent.top
                    anchors.topMargin: dialogMainItem.outerPadding

                    cellWidth: dialogMainItem.cardWidth + dialogMainItem.cardSpacing
                    cellHeight: dialogMainItem.cardHeight + dialogMainItem.cardSpacing

                    interactive: false
                    model: tabBox.model
                    currentIndex: tabBox.currentIndex

                    keyNavigationWraps: true
                    highlightFollowsCurrentItem: false
                    focus: true

                    delegate: Item {
                        id: itemRoot
                        width: dialogMainItem.cardWidth
                        height: dialogMainItem.cardHeight

                        readonly property bool isCurrent: GridView.isCurrentItem

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                tabBox.model.activate(index);
                            }

                            Rectangle {
                                id: cardBg
                                anchors.fill: parent
                                radius: 12
                                color: {
                                    if (itemRoot.isCurrent) {
                                        return dialogMainItem.isDark ? "#242730" : "#ffffff";
                                    }
                                    if (itemMouseArea.containsMouse) {
                                        return dialogMainItem.isDark ? "#1e2127" : "#fafbfc";
                                    }
                                    return dialogMainItem.isDark ? "#1a1d22" : "#f0f2f5";
                                }
                                border.width: itemRoot.isCurrent ? 2 : 1
                                border.color: {
                                    if (itemRoot.isCurrent) {
                                        return Kirigami.Theme.highlightColor || "#007aff";
                                    }
                                    if (itemMouseArea.containsMouse) {
                                        return dialogMainItem.isDark ? "#383b45" : "#cdd2db";
                                    }
                                    return dialogMainItem.isDark ? "#2a2d35" : "#e0e3ea";
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 80 }
                                }
                                Behavior on border.color {
                                    ColorAnimation { duration: 80 }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    // Top Header Bar
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 22
                                        spacing: 8

                                        Kirigami.Icon {
                                            Layout.preferredWidth: 20
                                            Layout.preferredHeight: 20
                                            source: model.icon
                                        }

                                        PlasmaComponents3.Label {
                                            Layout.fillWidth: true
                                            text: model.caption
                                            font.pointSize: 9.5
                                            font.weight: itemRoot.isCurrent ? Font.DemiBold : Font.Normal
                                            color: dialogMainItem.isDark ? "#f0f2f5" : "#181a1c"
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        PlasmaComponents3.Button {
                                            Layout.preferredWidth: 20
                                            Layout.preferredHeight: 20
                                            visible: model.closeable && (itemMouseArea.containsMouse || itemRoot.isCurrent)
                                            icon.name: "window-close-symbolic"
                                            onClicked: {
                                                tabBox.model.close(index);
                                            }
                                        }
                                    }

                                    // Live Window Thumbnail
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 8
                                        clip: true
                                        color: "#0d0e10"
                                        border.width: 1
                                        border.color: dialogMainItem.isDark ? "#22252b" : "#dfe2e9"

                                        KWin.WindowThumbnail {
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            wId: (typeof windowId !== "undefined") ? windowId : (model && model.windowId ? model.windowId : 0)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    onCurrentIndexChanged: {
                        if (tabBox.currentIndex !== gridView.currentIndex) {
                            tabBox.currentIndex = gridView.currentIndex;
                        }
                    }
                }

                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - 32
                    icon.source: "edit-none"
                    text: "No open windows"
                    visible: dialogMainItem.totalCount === 0
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Left) {
                        gridView.moveCurrentIndexLeft();
                    } else if (event.key === Qt.Key_Right) {
                        gridView.moveCurrentIndexRight();
                    } else if (event.key === Qt.Key_Up) {
                        gridView.moveCurrentIndexUp();
                    } else if (event.key === Qt.Key_Down) {
                        gridView.moveCurrentIndexDown();
                    } else {
                        return;
                    }
                    event.accepted = true;
                    tabBox.currentIndex = gridView.currentIndex;
                }
            }

            onSceneGraphError: () => {
                // Safeguard against graphics reset
            }
        }
    }
}
