/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root

    property real aquariumWidth: 1
    property real aquariumHeight: 1
    property real waterSurfaceY: 0
    property real phase: 0
    property bool compact: false
    property real swimProgress: 0

    readonly property real cakeSize: Math.max(14, aquariumHeight * (compact ? 0.32 : 0.192))
    readonly property real bob: Math.sin(phase * 0.72) * cakeSize * 0.035
    readonly property real sway: Math.sin(phase * 0.46) * cakeSize * 0.055
    readonly property real rockAngle: Math.sin(phase * 0.62) * 5.0
    readonly property real travel: swimProgress
    readonly property bool movingRight: travel < 1
    readonly property real swimLeg: movingRight ? travel : travel - 1
    readonly property real leftOutX: -width - cakeSize * 0.12
    readonly property real rightOutX: aquariumWidth + cakeSize * 0.12
    readonly property real span: rightOutX - leftOutX
    readonly property real swimX: movingRight ? leftOutX + swimLeg * span : rightOutX - swimLeg * span
    readonly property real waterlineRatio: 0.70

    width: cakeSize
    height: cakeSize
    x: swimX + sway
    y: waterSurfaceY - height * waterlineRatio + bob
    opacity: 0.98

    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height * root.waterlineRatio
        angle: root.rockAngle
    }

    NumberAnimation on swimProgress {
        from: 0
        to: 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/december-cake.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        cache: true
    }
}
