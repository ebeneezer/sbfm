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

    readonly property int gridWidth: 21
    readonly property int gridHeight: 25
    readonly property real pixelScale: Math.max(0.85, aquariumHeight / (compact ? 49 : 88))
    readonly property real bob: Math.sin(phase * 0.76) * pixelScale
    readonly property real sway: Math.sin(phase * 0.50) * pixelScale * 1.85
    readonly property real rockAngle: Math.sin(phase * 0.45) * 2.7
    readonly property real travel: swimProgress
    readonly property bool swimmingRight: travel < 1
    readonly property real swimLeg: swimmingRight ? travel : travel - 1
    readonly property real leftOutX: -width - pixelScale * 3
    readonly property real rightOutX: aquariumWidth + pixelScale * 3
    readonly property real span: rightOutX - leftOutX
    readonly property real swimX: swimmingRight ? leftOutX + swimLeg * span : rightOutX - swimLeg * span
    readonly property int earFrame: Math.floor(phase * 1.05) % 4
    readonly property int kickFrame: Math.floor(phase * 2.4) % 4

    width: gridWidth * pixelScale
    height: gridHeight * pixelScale
    x: swimX + sway
    y: Math.max(0, Math.min(aquariumHeight - height, waterSurfaceY - height * 0.49 + bob))
    opacity: 0.96

    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height * 0.49
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
        id: bunnyCanvas

        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        function cell(ctx, x, y, color) {
            ctx.fillStyle = color;
            ctx.fillRect(x * root.pixelScale, y * root.pixelScale, root.pixelScale, root.pixelScale);
        }

        function drawEar(ctx, centerX, baseY, bend, fur, shade, inner) {
            const centers = [
                [centerX, baseY],
                [centerX, baseY - 1],
                [centerX, baseY - 2],
                [centerX + bend, baseY - 3],
                [centerX + bend, baseY - 4],
                [centerX + bend, baseY - 5],
                [centerX, baseY - 6]
            ];

            for (let i = 0; i < centers.length; ++i) {
                const x = centers[i][0];
                const y = centers[i][1];
                const edge = i === centers.length - 1 ? 0 : 1;
                cell(ctx, x - edge, y, shade);
                cell(ctx, x, y, shade);
                cell(ctx, x + edge, y, shade);
            }

            for (let j = 0; j < centers.length; ++j) {
                const ex = centers[j][0];
                const ey = centers[j][1];
                const widthEdge = j === centers.length - 1 ? 0 : 1;
                cell(ctx, ex - widthEdge, ey, fur);
                cell(ctx, ex, ey, fur);
                cell(ctx, ex + widthEdge, ey, fur);
                if (j === 2 || j === 3) {
                    cell(ctx, ex, ey, inner);
                }
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.imageSmoothingEnabled = false;

            const fur = "#f3f0e8";
            const shade = "#d8d2c7";
            const inner = "#eaa7b7";
            const eye = "#11161d";
            const carrot = "#ff8b2a";

            // Emergency ears. Yes, that is now a technical term.
            if (root.earFrame === 0) {
                drawEar(ctx, 7, 7, -1, fur, shade, inner);
                drawEar(ctx, 13, 7, 1, fur, shade, inner);
            } else if (root.earFrame === 1) {
                drawEar(ctx, 7, 7, 0, fur, shade, inner);
                drawEar(ctx, 13, 7, 1, fur, shade, inner);
            } else if (root.earFrame === 2) {
                drawEar(ctx, 7, 7, -1, fur, shade, inner);
                drawEar(ctx, 13, 7, 0, fur, shade, inner);
            } else {
                drawEar(ctx, 7, 7, 0, fur, shade, inner);
                drawEar(ctx, 13, 7, 0, fur, shade, inner);
            }

            // Head.
            for (let y = 7; y <= 12; ++y) {
                for (let x = 6; x <= 14; ++x) {
                    if (!(x === 6 && y === 7) && !(x === 14 && y === 7)) {
                        cell(ctx, x, y, fur);
                    }
                }
            }
            cell(ctx, 6, 10, shade);
            cell(ctx, 14, 10, shade);
            cell(ctx, 8, 9, eye);
            cell(ctx, 12, 9, eye);
            cell(ctx, 10, 10, "#ef8fa3");
            cell(ctx, 9, 11, shade);
            cell(ctx, 11, 11, shade);
            cell(ctx, 15, 11, carrot);
            cell(ctx, 16, 11, carrot);
            cell(ctx, 17, 10, "#58a55b");

            // Body just below the waterline.
            for (let y = 13; y <= 18; ++y) {
                for (let x = 7; x <= 13; ++x) {
                    cell(ctx, x, y, fur);
                }
            }
            for (let x = 8; x <= 12; ++x) {
                cell(ctx, x, 16, shade);
                cell(ctx, x, 17, shade);
            }

            // Kicking feet under water.
            if (root.kickFrame === 0 || root.kickFrame === 3) {
                cell(ctx, 8, 19, fur);
                cell(ctx, 7, 20, fur);
                cell(ctx, 6, 20, shade);
                cell(ctx, 12, 19, fur);
                cell(ctx, 13, 20, fur);
                cell(ctx, 14, 20, shade);
            } else if (root.kickFrame === 1) {
                cell(ctx, 8, 19, fur);
                cell(ctx, 9, 20, fur);
                cell(ctx, 10, 20, shade);
                cell(ctx, 12, 19, fur);
                cell(ctx, 11, 20, fur);
                cell(ctx, 10, 21, shade);
            } else {
                cell(ctx, 8, 19, fur);
                cell(ctx, 7, 21, fur);
                cell(ctx, 6, 21, shade);
                cell(ctx, 12, 19, fur);
                cell(ctx, 13, 21, fur);
                cell(ctx, 14, 21, shade);
            }

            // Waterline splashes.
            cell(ctx, 5, 17, "#9defff");
            cell(ctx, 6, 18, "#d8fbff");
            cell(ctx, 14, 17, "#d8fbff");
            cell(ctx, 15, 18, "#9defff");
            cell(ctx, 8, 19, "#8bd8ec");
            cell(ctx, 12, 19, "#8bd8ec");
        }
    }

    onPixelScaleChanged: bunnyCanvas.requestPaint()
    onEarFrameChanged: bunnyCanvas.requestPaint()
    onKickFrameChanged: bunnyCanvas.requestPaint()
}
