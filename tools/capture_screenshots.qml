/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window

import "../package/contents/ui" as Sbfm

Window {
    id: window

    width: 960
    height: 640
    visible: true
    color: "#101018"
    title: "Super Bubble Fishy Mon screenshots"

    property string outputDir: "screenshots"
    property int scenarioIndex: -1
    property string activeToon: ""
    property var scenarios: [
        {
            file: "01-aquarium-clear-day.png",
            cpu: 0.28,
            system: 4.2,
            memory: 0.62,
            swap: 0.18,
            network: 0.36,
            condition: "clear",
            cloud: 0.04,
            rain: 0,
            snow: 0,
            season: "auto",
            time: new Date(2026, 5, 15, 14, 20, 0)
        },
        {
            file: "02-night-moon.png",
            cpu: 0.10,
            system: 2.1,
            memory: 0.55,
            swap: 0.08,
            network: 0.12,
            condition: "clear",
            cloud: 0.02,
            rain: 0,
            snow: 0,
            season: "auto",
            time: new Date(2026, 5, 15, 23, 40, 0)
        },
        {
            file: "03-rain-weather.png",
            cpu: 0.42,
            system: 3.4,
            memory: 0.70,
            swap: 0.22,
            network: 0.55,
            condition: "rain",
            cloud: 0.86,
            rain: 2.1,
            snow: 0,
            season: "auto",
            time: new Date(2026, 5, 15, 16, 10, 0)
        },
        {
            file: "04-swap-plants.png",
            cpu: 0.18,
            system: 2.6,
            memory: 0.50,
            swap: 0.82,
            network: 0.24,
            condition: "cloudy",
            cloud: 0.58,
            rain: 0,
            snow: 0,
            season: "auto",
            time: new Date(2026, 5, 15, 12, 0, 0)
        },
        {
            file: "05-christmas-santa.png",
            cpu: 0.24,
            system: 2.3,
            memory: 0.58,
            swap: 0.15,
            network: 0.28,
            condition: "snow",
            cloud: 0.72,
            rain: 0,
            snow: 1.2,
            season: "auto",
            time: new Date(2026, 11, 24, 21, 10, 0),
            toon: "santa"
        },
        {
            file: "06-easter-bunny.png",
            cpu: 0.20,
            system: 2.0,
            memory: 0.56,
            swap: 0.12,
            network: 0.20,
            condition: "clear",
            cloud: 0.10,
            rain: 0,
            snow: 0,
            season: "auto",
            time: new Date(2026, 3, 5, 13, 10, 0),
            toon: "bunny"
        },
        {
            file: "07-halloween-pumpkin.png",
            cpu: 0.32,
            system: 2.7,
            memory: 0.60,
            swap: 0.35,
            network: 0.34,
            condition: "fog",
            cloud: 0.75,
            rain: 0,
            snow: 0,
            season: "auto",
            time: new Date(2026, 9, 31, 22, 20, 0),
            toon: "pumpkin"
        },
        {
            file: "08-predator-skeleton-fish.png",
            cpu: 0.16,
            system: 1.0,
            memory: 0.58,
            swap: 0.10,
            network: 0.26,
            condition: "clear",
            cloud: 0.05,
            rain: 0,
            snow: 0,
            season: "auto",
            time: new Date(2026, 5, 15, 15, 15, 0),
            predator: true
        }
    ]

    Sbfm.Aquarium {
        id: aquarium

        width: window.width
        height: window.height
        frameInterval: 42
        downloadText: "420 KiB/s"
        uploadText: "64 KiB/s"
        showWater: true
        showBubbles: true
        showFish: true
        showDuck: true
        showWeeds: true

        Sbfm.Fish {
            id: predatorDemo

            aquariumWidth: window.width
            aquariumHeight: window.height
            waterSurfaceY: aquarium.waterSurfaceY
            seed: 4
            load: 0.26
            phase: 11.0
            compact: false
            wanted: false
            present: true
            leftToRight: true
            swimProgress: 0.56
            predatorActive: true
            predatorReturning: false
            predatorLeftToRight: true
            predatorProgress: 0.49
            visible: false
            z: 8
        }

        Sbfm.DrowningSanta {
            aquariumWidth: aquarium.width
            aquariumHeight: aquarium.height
            waterSurfaceY: aquarium.waterSurfaceY
            phase: 12.0
            swimProgress: 0.5
            swimAnimationRunning: false
            compact: false
            visible: window.activeToon === "santa"
            z: 9
        }

        Sbfm.DrowningEasterBunny {
            aquariumWidth: aquarium.width
            aquariumHeight: aquarium.height
            waterSurfaceY: aquarium.waterSurfaceY
            phase: 10.0
            swimProgress: 0.5
            swimAnimationRunning: false
            compact: false
            visible: window.activeToon === "bunny"
            z: 9
        }

        Sbfm.DrowningHalloween {
            aquariumWidth: aquarium.width
            aquariumHeight: aquarium.height
            waterSurfaceY: aquarium.waterSurfaceY
            phase: 10.0
            swimProgress: 0.5
            swimAnimationRunning: false
            compact: false
            visible: window.activeToon === "pumpkin"
            z: 9
        }
    }

    function applyScenario(scenario) {
        aquarium.cpuLoad = scenario.cpu;
        aquarium.systemLoad = scenario.system;
        aquarium.memoryLoad = scenario.memory;
        aquarium.swapLoad = scenario.swap;
        aquarium.networkLoad = scenario.network;
        aquarium.weatherCondition = scenario.condition;
        aquarium.weatherCloudCover = scenario.cloud;
        aquarium.weatherPrecipitation = scenario.rain;
        aquarium.weatherSnowfall = scenario.snow;
        aquarium.seasonMode = scenario.season;
        aquarium.currentTime = scenario.time;
        aquarium.showDuck = scenario.toon === undefined;

        predatorDemo.waterSurfaceY = aquarium.waterSurfaceY;
        predatorDemo.visible = scenario.predator === true;
        activeToon = scenario.toon || "";
    }

    function captureCurrentScenario() {
        const scenario = scenarios[scenarioIndex];
        aquarium.grabToImage(function(result) {
            result.saveToFile(outputDir + "/" + scenario.file);
            nextScenarioTimer.restart();
        }, Qt.size(1000, 660));
    }

    function runNextScenario() {
        scenarioIndex += 1;
        if (scenarioIndex >= scenarios.length) {
            window.close();
            Qt.exit(0);
            return;
        }

        applyScenario(scenarios[scenarioIndex]);
        captureTimer.restart();
    }

    Timer {
        id: startupTimer

        interval: 250
        repeat: false
        running: true
        onTriggered: window.runNextScenario()
    }

    Timer {
        id: captureTimer

        interval: 950
        repeat: false
        onTriggered: window.captureCurrentScenario()
    }

    Timer {
        id: nextScenarioTimer

        interval: 120
        repeat: false
        onTriggered: window.runNextScenario()
    }
}
