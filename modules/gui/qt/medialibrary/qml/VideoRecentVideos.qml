/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12

import org.videolan.medialib 0.1
import org.videolan.vlc 0.1

import "qrc:///widgets/" as Widgets
import "qrc:///util/" as Util
import "qrc:///util/Helpers.js" as Helpers
import "qrc:///style/"

FocusScope {
    id: root

    // Aliases

    property alias bottomPadding: recentVideosColumn.bottomPadding

    property alias displayMarginBeginning: listView.displayMarginBeginning
    property alias displayMarginEnd: listView.displayMarginEnd

    property alias subtitleText : subtitleLabel.text

    // Settings

    implicitHeight: recentVideosColumn.height

    focus: recentModel.count > 0

    // Functions

    function _play(id) {
        MediaLib.addAndPlay( id, [":restore-playback-pos=2"] )
        History.push(["player"])
    }

    function _playIndex(idx) {
        recentModel.addAndPlay( [idx], [":restore-playback-pos=2"] )
        History.push(["player"])
    }

    // Childs

    MLRecentsVideoModel {
        id: recentModel

        ml: MediaLib

        limit: 10
    }

    Util.MLContextMenu {
        id: contextMenu

        model: listView.model

        showPlayAsAudioAction: true
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    Column {
        id: recentVideosColumn

        width: root.width

        topPadding: VLCStyle.margin_large

        spacing: VLCStyle.margin_normal

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right

            anchors.leftMargin: listView.contentLeftMargin
            anchors.rightMargin: listView.contentRightMargin

            Widgets.SubtitleLabel {
                id: label

                Layout.fillWidth: true

                text: I18n.qtr("Continue Watching")

                // NOTE: Setting this to gridView.visible seems to causes unnecessary implicitHeight
                //       calculations in the Column parent.
                visible: recentModel.count > 0
                color: theme.fg.primary
            }

            Widgets.TextToolButton {
                id: button

                visible: recentModel.maximumCount > recentModel.count

                Layout.preferredWidth: implicitWidth

                focus: true

                text: I18n.qtr("See All")

                font.pixelSize: VLCStyle.fontSize_large

                Navigation.parentItem: root

                onClicked: History.push(["mc", "video", "all", "recentVideos"]);
            }
        }

        Widgets.KeyNavigableListView {
            id: listView

            width: parent.width

            implicitHeight: VLCStyle.gridItem_video_height + VLCStyle.gridItemSelectedBorder
                            +
                            VLCStyle.margin_xlarge

            spacing: VLCStyle.column_spacing

            // NOTE: We want navigation buttons to be centered on the item cover.
            buttonMargin: VLCStyle.margin_xsmall + VLCStyle.gridCover_video_height / 2 - buttonLeft.height / 2

            orientation: ListView.Horizontal

            focus: true

            // NOTE: We want a gentle fade at the beginning / end of the history.
            enableFade: true

            Navigation.parentItem: root

            visible: recentModel.count > 0

            model: recentModel

            delegate: VideoGridItem {
                id: gridItem

                pictureWidth: VLCStyle.gridCover_video_width
                pictureHeight: VLCStyle.gridCover_video_height

                selected: activeFocus

                focus: true

                onItemDoubleClicked: gridItem.play()

                onItemClicked: {
                    listView.currentIndex = index
                    this.forceActiveFocus(Qt.MouseFocusReason)
                }

                // NOTE: contextMenu.popup wants a list of indexes.
                onContextMenuButtonClicked: {
                    contextMenu.popup([listView.model.index(index, 0)],
                                      globalMousePos,
                                      { "player-options": [":restore-playback-pos=2"] })
                }

                dragItem: Widgets.DragItem {
                    coverRole: "thumbnail"

                    indexes: [index]

                    onRequestData: {
                        resolve([model])
                    }

                    onRequestInputItems: {
                        const idList = data.map((o) => o.id)
                        MediaLib.mlInputItem(idList, resolve)
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: VLCStyle.duration_short
                    }
                }

                function play() {
                    if (model.id !== undefined) {
                        root._play(model.id)
                    }
                }
            }

            onActionAtIndex: {
                root._playIndex(index)
            }
        }

        Widgets.SubtitleLabel {
            id: subtitleLabel

            visible: text !== ""
            color: theme.fg.primary
        }
    }
}