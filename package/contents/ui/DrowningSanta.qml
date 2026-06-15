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

    readonly property int gridWidth: 20
    readonly property int gridHeight: 24
    readonly property real pixelScale: Math.max(0.85, aquariumHeight / (compact ? 48 : 86))
    readonly property real bob: Math.sin(phase * 0.9) * pixelScale * 1.2
    readonly property real sway: Math.sin(phase * 0.58) * pixelScale * 2.2
    readonly property real rockAngle: Math.sin(phase * 0.52) * 3.2
    readonly property real travel: swimProgress
    readonly property bool swimmingRight: travel < 1
    readonly property real swimLeg: swimmingRight ? travel : travel - 1
    readonly property real leftOutX: -width - pixelScale * 3
    readonly property real rightOutX: aquariumWidth + pixelScale * 3
    readonly property real span: rightOutX - leftOutX
    readonly property real swimX: swimmingRight ? leftOutX + swimLeg * span : rightOutX - swimLeg * span
    readonly property int armFrame: Math.floor(phase * 2.4) % 4
    readonly property int legFrame: Math.floor(phase * 2.8) % 4
    readonly property int hatFrame: Math.floor(phase * 2.0) % 3

    width: gridWidth * pixelScale
    height: gridHeight * pixelScale
    x: swimX + sway
    y: Math.max(0, Math.min(aquariumHeight - height, waterSurfaceY - height * 0.44 + bob))
    opacity: 0.95

    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height * 0.44
        angle: root.rockAngle
    }

    NumberAnimation on swimProgress {
        from: 0
        to: 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }

    Canvas {
        id: santaCanvas

        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        function cell(ctx, x, y, color) {
            ctx.fillStyle = color;
            ctx.fillRect(x * root.pixelScale, y * root.pixelScale, root.pixelScale, root.pixelScale);
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.imageSmoothingEnabled = false;

            // Hat with a small moving pom-pom.
            for (let x = 7; x <= 12; ++x) {
                cell(ctx, x, 2, "#b51217");
            }
            for (let x = 6; x <= 13; ++x) {
                cell(ctx, x, 3, "#d71920");
            }
            if (root.hatFrame === 0) {
                cell(ctx, 12, 1, "#d71920");
                cell(ctx, 13, 1, "#f8f4e8");
                cell(ctx, 14, 1, "#f8f4e8");
            } else if (root.hatFrame === 1) {
                cell(ctx, 12, 1, "#d71920");
                cell(ctx, 13, 0, "#f8f4e8");
                cell(ctx, 14, 0, "#f8f4e8");
            } else {
                cell(ctx, 11, 1, "#d71920");
                cell(ctx, 12, 0, "#f8f4e8");
                cell(ctx, 13, 0, "#f8f4e8");
            }
            for (let x = 6; x <= 13; ++x) {
                cell(ctx, x, 4, "#f8f4e8");
            }

            // Head and beard.
            for (let y = 5; y <= 8; ++y) {
                for (let x = 7; x <= 12; ++x) {
                    cell(ctx, x, y, "#f0c18f");
                }
            }
            cell(ctx, 8, 6, "#10151c");
            cell(ctx, 11, 6, "#10151c");
            for (let x = 7; x <= 12; ++x) {
                cell(ctx, x, 9, "#f8f4e8");
            }
            for (let x = 8; x <= 11; ++x) {
                cell(ctx, x, 10, "#f8f4e8");
            }

            // Coat just below the surface.
            for (let y = 11; y <= 17; ++y) {
                for (let x = 7; x <= 12; ++x) {
                    cell(ctx, x, y, "#b51217");
                }
            }
            for (let y = 11; y <= 17; ++y) {
                cell(ctx, 9, y, "#f8f4e8");
                cell(ctx, 10, y, "#f8f4e8");
            }

            // Arms: small panic flail around the same silhouette.
            if (root.armFrame === 0) {
                cell(ctx, 5, 11, "#b51217");
                cell(ctx, 4, 9, "#b51217");
                cell(ctx, 3, 7, "#b51217");
                cell(ctx, 2, 6, "#f0c18f");
                cell(ctx, 14, 11, "#b51217");
                cell(ctx, 15, 9, "#b51217");
                cell(ctx, 16, 7, "#b51217");
                cell(ctx, 17, 6, "#f0c18f");
            } else if (root.armFrame === 1) {
                cell(ctx, 5, 12, "#b51217");
                cell(ctx, 4, 10, "#b51217");
                cell(ctx, 3, 8, "#b51217");
                cell(ctx, 2, 7, "#f0c18f");
                cell(ctx, 14, 12, "#b51217");
                cell(ctx, 15, 10, "#b51217");
                cell(ctx, 16, 8, "#b51217");
                cell(ctx, 17, 7, "#f0c18f");
            } else if (root.armFrame === 2) {
                cell(ctx, 5, 10, "#b51217");
                cell(ctx, 4, 8, "#b51217");
                cell(ctx, 3, 6, "#b51217");
                cell(ctx, 2, 5, "#f0c18f");
                cell(ctx, 14, 12, "#b51217");
                cell(ctx, 16, 11, "#b51217");
                cell(ctx, 17, 9, "#b51217");
                cell(ctx, 18, 8, "#f0c18f");
            } else {
                cell(ctx, 5, 12, "#b51217");
                cell(ctx, 3, 11, "#b51217");
                cell(ctx, 2, 9, "#b51217");
                cell(ctx, 1, 8, "#f0c18f");
                cell(ctx, 14, 10, "#b51217");
                cell(ctx, 15, 8, "#b51217");
                cell(ctx, 16, 6, "#b51217");
                cell(ctx, 17, 5, "#f0c18f");
            }

            // Legs below the coat, mostly under water.
            if (root.legFrame === 0 || root.legFrame === 3) {
                cell(ctx, 8, 18, "#8f1115");
                cell(ctx, 7, 19, "#8f1115");
                cell(ctx, 7, 20, "#10151c");
                cell(ctx, 11, 18, "#8f1115");
                cell(ctx, 12, 19, "#8f1115");
                cell(ctx, 12, 20, "#10151c");
            } else if (root.legFrame === 1) {
                cell(ctx, 8, 18, "#8f1115");
                cell(ctx, 8, 19, "#8f1115");
                cell(ctx, 9, 20, "#10151c");
                cell(ctx, 11, 18, "#8f1115");
                cell(ctx, 11, 19, "#8f1115");
                cell(ctx, 10, 20, "#10151c");
            } else {
                cell(ctx, 8, 18, "#8f1115");
                cell(ctx, 9, 19, "#8f1115");
                cell(ctx, 9, 20, "#10151c");
                cell(ctx, 11, 18, "#8f1115");
                cell(ctx, 10, 19, "#8f1115");
                cell(ctx, 10, 20, "#10151c");
            }

            // Waterline splashes over coat.
            cell(ctx, 5, 16, "#9defff");
            cell(ctx, 6, 17, "#d8fbff");
            cell(ctx, 13, 16, "#d8fbff");
            cell(ctx, 14, 17, "#9defff");
            cell(ctx, 8, 18, "#8bd8ec");
            cell(ctx, 11, 18, "#8bd8ec");
        }
    }

    onPixelScaleChanged: santaCanvas.requestPaint()
    onArmFrameChanged: santaCanvas.requestPaint()
    onLegFrameChanged: santaCanvas.requestPaint()
    onHatFrameChanged: santaCanvas.requestPaint()
}
