# Super Bubble Fishy Mon

Super Bubble Fishy Mon is a Plasma 6 panel widget inspired by the classic
BubbleFishyMon/gkrellm aquarium monitor. CPU activity drives bubbles, network
traffic drives fish, and memory pressure nudges the duck.

Repository: <https://github.com/ebeneezer/sbfm>

Author: Dr. Michael Raus <dr.michael.raus@gmail.com>

## Install locally

```sh
kpackagetool6 --type Plasma/Applet --install package
```

If an older development copy is already installed:

```sh
kpackagetool6 --type Plasma/Applet --upgrade package
```

## Test window

```sh
plasmawindowed de.drraus.plasma.superbubbyfishymon
```

The widget uses KSysGuard sensor ids available on Plasma 6:

- `cpu/all/usage`
- `memory/physical/usedPercent`
- `network/all/download`
- `network/all/upload`

The panel representation is square and follows the panel thickness in both
horizontal and vertical Plasma panels. Clicking the widget opens the configured
KDE URL, defaulting to `applications:org.kde.plasma-systemmonitor.desktop`.
The configuration page can toggle water, bubbles, fish, duck, and plants,
control animation frames per second, and select which network interface drives
fish speed.

The bundled fish, bubble, plant, and duck sprites are generated from the
original BubbleFishyMon headers in `vendor/bfm/include/`:

```sh
python3 tools/generate_original_assets.py
```
