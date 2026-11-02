#!/usr/bin/env python3
"""Builds the unit sprite sheets in art/units from Liberated Pixel Cup layers.

Layers are downloaded from the Universal LPC Spritesheet Character Generator
(https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator),
composited in z order, team-tinted, downscaled and packed into one sheet per
unit and team, with a JSON file describing the animation layout.

Usage:  python3 tools/build_unit_sprites.py [--cache DIR]
Requires Pillow. See CREDITS.md for the authors and licences of the art.
"""
import argparse
import json
import os
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

BASE_URL = ("https://raw.githubusercontent.com/LiberatedPixelCup/"
            "Universal-LPC-Spritesheet-Character-Generator/HEAD/spritesheets/")
HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "..", "art", "units")
SCALE = 0.75  # 64 px LPC frames -> 48 px
TEAMS = {"blue": (56, 133, 242), "red": (230, 64, 56)}

FRAMES = {"walk": 9, "slash": 6, "thrust": 8, "shoot": 13, "spellcast": 7, "hurt": 6}
STD = ["walk", "slash", "thrust", "shoot", "spellcast", "hurt"]


def std(d, anims=STD):
    """Layer whose files are <dir><anim>.png."""
    return {a: f"{d}{a}.png" for a in anims}


def var(d, v, anims=STD):
    """Layer whose files are <dir><anim>/<variant>.png."""
    return {a: f"{d}{a}/{v}.png" for a in anims}


def layer(z, files, team=False, big=None, color=None):
    """big: {anim: file} for 128 px oversized custom animations.
    team: recolour to the team colour. color: recolour to a fixed (r, g, b)."""
    return {"z": z, "files": files, "team": team, "big": big or {}, "color": color}


BODY = [
    layer(10, std("body/bodies/male/")),
    layer(100, std("head/heads/human/male/")),
]
SHOES = layer(15, std("feet/shoes/basic/male/"), color=(70, 50, 35))
PANTS = layer(20, std("legs/pants/male/"), color=(120, 90, 60))
SHIRT = layer(35, std("torso/clothes/longsleeve/longsleeve/male/"), team=True)
HAIR = layer(120, std("hair/plain/adult/"), color=(95, 62, 35))
SHIELD = [
    layer(2, std("shield/heater/original/wood/bg/")),
    layer(3, std("shield/heater/original/paint/bg/"), team=True),
    layer(110, std("shield/heater/original/wood/fg/")),
    layer(111, std("shield/heater/original/paint/fg/"), team=True),
    layer(115, std("shield/heater/original/trim/fg/")),
]
SWORD = [
    layer(9, var("weapon/sword/arming/universal/bg/", "steel", ["walk", "hurt"]),
          big={"slash": "weapon/sword/arming/attack_slash/bg/steel.png"}),
    layer(140, var("weapon/sword/arming/universal/fg/", "steel", ["walk", "hurt"]),
          big={"slash": "weapon/sword/arming/attack_slash/fg/steel.png"}),
]
PLATE = [
    layer(20, std("legs/armour/plate/male/")),
    layer(60, std("torso/armour/plate/male/")),
    layer(60, std("arms/armour/plate/male/")),
]


def tool(name):
    return [
        layer(140, {f"walk_{name}": f"tools/{name}/male/walk.png"}),
        layer(9, {}, big={f"work_{name}": f"tools/{name}/bg.png"}),
        layer(150, {}, big={f"work_{name}": f"tools/{name}/fg.png"}),
    ]


# Each unit: layers + list of output animations (name, body animation, oversized?).
UNITS = {
    "villager": {
        "layers": BODY + [SHOES, PANTS, SHIRT, HAIR] + tool("axe") + tool("pickaxe") + tool("hammer"),
        "anims": [("walk_axe", "walk", False), ("work_axe", "slash", True),
                  ("walk_pickaxe", "walk", False), ("work_pickaxe", "slash", True),
                  ("walk_hammer", "walk", False), ("work_hammer", "slash", True),
                  ("hurt", "hurt", False)],
    },
    "swordsman": {
        "layers": BODY + [SHOES, PANTS,
                          layer(50, std("torso/chainmail/male/")),
                          layer(55, var("torso/jacket/tabard/male/", "brown"), team=True),
                          layer(130, std("hat/helmet/nasal/adult/"))] + SHIELD + SWORD,
        "anims": [("walk", "walk", False), ("attack", "slash", True), ("hurt", "hurt", False)],
    },
    "spearman": {
        "layers": BODY + [SHOES, PANTS, SHIRT,
                          layer(50, std("torso/chainmail/male/")),
                          layer(55, var("torso/jacket/tabard/male/", "brown"), team=True),
                          layer(130, std("hat/helmet/barbuta/male/")),
                          layer(9, var("weapon/polearm/spear/background/", "steel", ["walk", "thrust", "hurt"])),
                          layer(140, var("weapon/polearm/spear/foreground/", "steel", ["walk", "thrust", "hurt"]))],
        "anims": [("walk", "walk", False), ("attack", "thrust", False), ("hurt", "hurt", False)],
    },
    "archer": {
        "layers": BODY + [SHOES, PANTS, SHIRT, HAIR,
                          layer(8, {a: f"quiver/{a}/quiver.png" for a in ["walk", "shoot", "hurt"]}),
                          layer(130, std("hat/cloth/hood/adult/"), color=(70, 100, 50)),
                          layer(-1, {"shoot": "weapon/ranged/bow/normal/universal/background/shoot/medium.png",
                                     "hurt": "weapon/ranged/bow/normal/universal/background/hurt/medium.png"},
                                big={"walk": "weapon/ranged/bow/normal/walk/background/medium.png"}),
                          layer(141, {"shoot": "weapon/ranged/bow/normal/universal/foreground/shoot/medium.png",
                                      "hurt": "weapon/ranged/bow/normal/universal/foreground/hurt/medium.png"},
                                big={"walk": "weapon/ranged/bow/normal/walk/foreground/medium.png"}),
                          layer(150, {"shoot": "weapon/ranged/bow/arrow/shoot/arrow.png"})],
        "anims": [("walk", "walk", True), ("attack", "shoot", False), ("hurt", "hurt", False)],
    },
    "knight": {
        "layers": BODY + [SHOES] + PLATE + [
            layer(65, var("torso/jacket/tabard/male/", "brown"), team=True),
            layer(130, std("hat/helmet/armet/adult/"))] + SHIELD + SWORD,
        "anims": [("walk", "walk", False), ("attack", "slash", True), ("hurt", "hurt", False)],
    },
    "monk": {
        "layers": BODY + [SHOES, layer(20, std("legs/pants/male/"), color=(110, 80, 50)),
                          layer(35, std("torso/clothes/longsleeve/longsleeve/male/"), color=(125, 90, 55)),
                          layer(130, std("hat/cloth/hood/adult/"), team=True)],
        "anims": [("walk", "walk", False), ("attack", "spellcast", False), ("hurt", "hurt", False)],
    },
}


def fetch(rel, cache):
    path = os.path.join(cache, rel)
    if os.path.exists(path):
        return path if os.path.getsize(path) > 0 else None
    os.makedirs(os.path.dirname(path), exist_ok=True)
    try:
        with urllib.request.urlopen(BASE_URL + rel, timeout=60) as r:
            data = r.read()
    except Exception:
        data = b""
    with open(path, "wb") as f:
        f.write(data if data[:4] == b"\x89PNG" else b"")
    return path if data[:4] == b"\x89PNG" else None


def tint(img, rgb):
    """Recolours a layer to the team colour, keeping its shading."""
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = (0.3 * r + 0.59 * g + 0.11 * b) / 255.0
            k = min(1.35, 0.35 + lum * 1.1)
            px[x, y] = (min(255, int(rgb[0] * k)), min(255, int(rgb[1] * k)), min(255, int(rgb[2] * k)), a)
    return img


def compose(unit, team_rgb, cache):
    spec = UNITS[unit]
    layers = sorted(spec["layers"], key=lambda l: l["z"])
    blocks = []
    for name, body_anim, big in spec["anims"]:
        frames = FRAMES[body_anim]
        rows = 1 if body_anim == "hurt" else 4
        cell = 128 if big else 64
        sheet = Image.new("RGBA", (frames * cell, rows * cell), (0, 0, 0, 0))
        for l in layers:
            rel = l["big"].get(name) or l["big"].get(body_anim) if big else None
            is_big = rel is not None
            if not is_big:
                rel = l["files"].get(name) or l["files"].get(body_anim)
            if not rel:
                continue
            p = fetch(rel, cache)
            if not p:
                continue
            img = Image.open(p).convert("RGBA")
            if l["team"]:
                img = tint(img, team_rgb)
            elif l["color"]:
                img = tint(img, l["color"])
            src_cell = 128 if is_big else 64
            for r in range(rows):
                for f in range(frames):
                    box = (f * src_cell, r * src_cell, (f + 1) * src_cell, (r + 1) * src_cell)
                    if box[2] > img.width or box[3] > img.height:
                        continue
                    piece = img.crop(box)
                    off = (cell - src_cell) // 2
                    sheet.alpha_composite(piece, (f * cell + off, r * cell + off))
        out_cell = int(cell * SCALE)
        sheet = sheet.resize((frames * out_cell, rows * out_cell), Image.LANCZOS)
        blocks.append((name, sheet, frames, rows, out_cell))
    width = max(b[1].width for b in blocks)
    height = sum(b[1].height for b in blocks)
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    meta = {}
    y = 0
    for name, img, frames, rows, cell in blocks:
        out.alpha_composite(img, (0, y))
        meta[name] = {"y": y, "cell": cell, "frames": frames, "rows": rows}
        y += img.height
    return out, meta


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=os.path.join(HERE, ".lpc_cache"))
    args = ap.parse_args()
    # Prefetch everything in parallel.
    rels = set()
    for spec in UNITS.values():
        for l in spec["layers"]:
            rels.update(l["files"].values())
            rels.update(l["big"].values())
    with ThreadPoolExecutor(16) as ex:
        missing = [r for r, p in zip(rels, ex.map(lambda r: fetch(r, args.cache), rels)) if not p]
    if missing:
        print("warning: missing layers:", *sorted(missing), sep="\n  ", file=sys.stderr)
    os.makedirs(OUT_DIR, exist_ok=True)
    all_meta = {}
    for unit in UNITS:
        for team, rgb in TEAMS.items():
            img, meta = compose(unit, rgb, args.cache)
            img.save(os.path.join(OUT_DIR, f"{unit}_{team}.png"), optimize=True)
            all_meta[unit] = meta
            print(f"{unit}_{team}.png {img.size}")
    with open(os.path.join(OUT_DIR, "sheets.json"), "w") as f:
        json.dump(all_meta, f, indent=1)


if __name__ == "__main__":
    main()
