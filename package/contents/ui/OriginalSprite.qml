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

    width: sourceWidth * pixelScale
    height: sourceHeight * pixelScale

    Image {
        anchors.fill: parent
        source: root.source
        sourceClipRect: Qt.rect(root.sourceX, root.sourceY, root.sourceWidth, root.sourceHeight)
        fillMode: Image.Stretch
        smooth: false
        antialiasing: false
    }
}
