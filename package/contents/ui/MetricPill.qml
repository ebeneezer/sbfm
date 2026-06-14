/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property color accent: Kirigami.Theme.highlightColor

    Layout.minimumWidth: labelText.implicitWidth + valueText.implicitWidth + Kirigami.Units.gridUnit
    Layout.preferredWidth: Math.max(Layout.minimumWidth, Kirigami.Units.gridUnit * 5)
    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.35

    radius: Kirigami.Units.smallSpacing
    color: Qt.rgba(0.0, 0.0, 0.0, 0.38)
    border.width: 1
    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.48)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Text {
            id: labelText
            text: root.label
            color: root.accent
            font.bold: true
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: valueText
            text: root.value
            color: "white"
            elide: Text.ElideRight
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
