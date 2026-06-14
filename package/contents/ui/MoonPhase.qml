/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Canvas {
    id: root

    property int phaseStep: 0
    property bool waxing: true
    property color litColor: Qt.rgba(0.88, 0.93, 1.0, 0.92)
    property color shadowColor: Qt.rgba(0.04, 0.03, 0.16, 0.98)
    property color rimColor: Qt.rgba(0.80, 0.90, 1.0, 0.46)

    function drawCrescent(ctx, cx, cy, radius, fraction, rightSide) {
        const control = radius * (1 - 2 * fraction);

        ctx.beginPath();
        if (rightSide) {
            ctx.arc(cx, cy, radius, -Math.PI / 2, Math.PI / 2, false);
            ctx.quadraticCurveTo(cx + control, cy, cx, cy - radius);
        } else {
            ctx.arc(cx, cy, radius, Math.PI / 2, -Math.PI / 2, false);
            ctx.quadraticCurveTo(cx - control, cy, cx, cy + radius);
        }
        ctx.closePath();
        ctx.fill();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        const radius = Math.max(1, Math.min(width, height) * 0.46);
        const cx = width / 2;
        const cy = height / 2;
        const step = Math.max(0, Math.min(5, phaseStep));
        const litFraction = step / 5;

        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, Math.PI * 2);
        ctx.fillStyle = shadowColor;
        ctx.fill();

        if (step === 5) {
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, Math.PI * 2);
            ctx.fillStyle = litColor;
            ctx.fill();
        } else if (step > 0 && step <= 2) {
            ctx.fillStyle = litColor;
            drawCrescent(ctx, cx, cy, radius, litFraction, waxing);
        } else if (step > 2) {
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, Math.PI * 2);
            ctx.fillStyle = litColor;
            ctx.fill();

            ctx.fillStyle = shadowColor;
            drawCrescent(ctx, cx, cy, radius, 1 - litFraction, !waxing);
        }

        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, Math.PI * 2);
        ctx.lineWidth = Math.max(1, radius * 0.10);
        ctx.strokeStyle = rimColor;
        ctx.stroke();
    }

    onPhaseStepChanged: requestPaint()
    onWaxingChanged: requestPaint()
    onLitColorChanged: requestPaint()
    onShadowColorChanged: requestPaint()
    onRimColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()
}
