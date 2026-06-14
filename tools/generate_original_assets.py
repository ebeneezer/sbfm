#!/usr/bin/env python3
"""Generate PNG sprites from the original BubbleFishyMon C headers."""

from __future__ import annotations

import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BFM_INCLUDE = ROOT / "vendor" / "bfm" / "include"
OUT = ROOT / "package" / "contents" / "images"


def parse_cmap(text: str, name: str) -> list[tuple[int, int, int]]:
    match = re.search(rf"{name}\s*\[[^]]+\]\[[^]]+\]\s*=\s*\{{(.*?)\}};", text, re.S)
    if not match:
        raise ValueError(f"Could not find {name}")
    triples = re.findall(r"\{\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\}", match.group(1))
    return [(int(red), int(green), int(blue)) for red, green, blue in triples]


def parse_header_data(text: str) -> bytes:
    match = re.search(r"static char header_data\[\]\s*=\s*\{(.*?)\};", text, re.S)
    if not match:
        raise ValueError("Could not find header_data")
    return bytes(int(value) for value in re.findall(r"-?\d+", match.group(1)))


def parse_ducks(text: str) -> list[list[int]]:
    match = re.search(r"duck_data\s*\[3\]\[306\]\s*=\s*\{(.*?)\};", text, re.S)
    if not match:
        raise ValueError("Could not find duck_data")
    frames: list[list[int]] = []
    for frame in re.findall(r"\{([^{}]+)\}", match.group(1), re.S):
        frames.append([int(value) for value in re.findall(r"-?\d+", frame)])
    if len(frames) != 3:
        raise ValueError(f"Expected 3 duck frames, got {len(frames)}")
    return frames


def write_sprite_sheet() -> None:
    text = (BFM_INCLUDE / "sprites.h").read_text()
    width = int(re.search(r"static unsigned int width = (\d+);", text).group(1))
    height = int(re.search(r"static unsigned int height = (\d+);", text).group(1))
    cmap = parse_cmap(text, "header_data_cmap")
    data = parse_header_data(text)
    if len(data) != width * height:
        raise ValueError(f"Expected {width * height} sprite pixels, got {len(data)}")

    image = Image.new("RGBA", (width, height))
    for index, value in enumerate(data):
        red, green, blue = cmap[value]
        alpha = 0 if value == 0 else 255
        image.putpixel((index % width, index // width), (red, green, blue, alpha))
    image.save(OUT / "original-sprites.png")


def write_duck_sheet() -> None:
    text = (BFM_INCLUDE / "ducks.h").read_text()
    cmap = parse_cmap(text, "duck_cmap")
    frames = parse_ducks(text)

    frame_width = 18
    frame_height = 17
    image = Image.new("RGBA", (frame_width * len(frames), frame_height))
    for frame_index, frame in enumerate(frames):
        if len(frame) != frame_width * frame_height:
            raise ValueError(f"Duck frame {frame_index} has {len(frame)} pixels")
        for index, value in enumerate(frame):
            red, green, blue = cmap[value]
            alpha = 0 if value == 0 else 255
            image.putpixel((frame_index * frame_width + index % frame_width, index // frame_width), (red, green, blue, alpha))
    image.save(OUT / "original-ducks.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write_sprite_sheet()
    write_duck_sheet()


if __name__ == "__main__":
    main()
