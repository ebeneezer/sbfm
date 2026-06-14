/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Launch")
        icon: "system-run"
        source: "ConfigGeneral.qml"
    }
}
