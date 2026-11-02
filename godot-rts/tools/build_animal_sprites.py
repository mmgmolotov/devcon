#!/usr/bin/env python3
"""Builds art/animals/*.png from CC-BY 3.0 OpenGameArt animal sprites.

Sources (see CREDITS.md):
  "LPC style farm animals" by daneeklu  - sheep_walk.png, sheep_eat.png, pig_eat.png
  "Deer" by Calciumtrice                 - deer_male.png
The boar is the pig recoloured to wild-boar browns (a permitted derivative).

Usage: python3 tools/build_animal_sprites.py [--cache DIR]
"""
import argparse
import os
import urllib.request

from PIL import Image

MIRROR = "https://media.githubusercontent.com/media/BrainMell/whatsapp-bot/HEAD/core/assets/sprites/"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "art", "animals")


def fetch(name, cache):
    path = os.path.join(cache, name)
    if not os.path.exists(path):
        os.makedirs(cache, exist_ok=True)
        with urllib.request.urlopen(MIRROR + name, timeout=60) as r:
            open(path, "wb").write(r.read())
    return Image.open(path).convert("RGBA")


def boar_tint(img):
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = (0.3 * r + 0.59 * g + 0.11 * b) / 255.0
            px[x, y] = (int(40 + 95 * lum), int(28 + 62 * lum), int(18 + 40 * lum), a)
    return img


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=os.path.join(HERE, ".animal_cache"))
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    # Sheep: 4 rows (up, left, down, right) x 4 frames of 128 px -> 64 px cells.
    walk = fetch("sheep_walk.png", a.cache)
    eat = fetch("sheep_eat.png", a.cache)
    sheep = Image.new("RGBA", (512, 1024))
    sheep.alpha_composite(walk, (0, 0))
    sheep.alpha_composite(eat, (0, 512))
    sheep.resize((256, 512), Image.LANCZOS).save(os.path.join(OUT, "sheep.png"), optimize=True)
    # Boar: pig eating cycle (4 rows x 4 frames), recoloured.
    pig = boar_tint(fetch("pig_eat.png", a.cache))
    pig.resize((256, 256), Image.LANCZOS).save(os.path.join(OUT, "boar.png"), optimize=True)
    # Deer: 5x5 frames of 32 px (row 0 idle, 1 graze, 2 run), faces right.
    deer = fetch("deer_male.png", a.cache)
    deer.resize((240, 240), Image.NEAREST).save(os.path.join(OUT, "deer.png"), optimize=True)
    print("animals written to", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
