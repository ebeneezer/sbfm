/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

OriginalSprite {
    id: root

    property real aquariumWidth: 1
    property real aquariumHeight: 1
    property real waterSurfaceY: 0
    property real load: 0
    property real phase: 0
    property bool compact: false

    readonly property int frame: Math.floor(phase * 1.4) % 3
    readonly property real duckWidth: Math.max(18, aquariumHeight * (compact ? 0.46 : 0.22))
    readonly property real bob: Math.sin(phase * 0.75) * aquariumHeight * 0.018
    readonly property real floatingY: waterSurfaceY - height * 0.62 + bob

    source: Qt.resolvedUrl("../images/original-ducks.png")
    sourceX: frame * 18
    sourceY: 0
    sourceWidth: 18
    sourceHeight: 17
    pixelScale: duckWidth / 18
    x: Math.max(0, Math.min(aquariumWidth - width, aquariumWidth * (0.58 + load * 0.22) + Math.sin(phase * 0.22) * aquariumWidth * 0.05))
    y: Math.max(0, Math.min(aquariumHeight - height, floatingY))
}
