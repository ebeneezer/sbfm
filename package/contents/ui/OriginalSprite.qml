/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root

    property url source
    property int sourceX: 0
    property int sourceY: 0
    property int sourceWidth: 1
    property int sourceHeight: 1
    property real pixelScale: 1
    property bool mirrored: false
    property bool flipped: false
    property bool spriteVisible: true

    width: sourceWidth * pixelScale
    height: sourceHeight * pixelScale

    Image {
        anchors.fill: parent
        visible: root.spriteVisible
        source: root.source
        sourceClipRect: Qt.rect(root.sourceX, root.sourceY, root.sourceWidth, root.sourceHeight)
        fillMode: Image.Stretch
        mirror: root.mirrored
        smooth: false
        antialiasing: false

        transform: Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            yScale: root.flipped ? -1 : 1
        }
    }
}
