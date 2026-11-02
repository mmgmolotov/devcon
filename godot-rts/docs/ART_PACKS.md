# Art packs

An art pack swaps Tiny Realms' built-in graphics for your own images, without changing
any code. A pack can replace any mix of units, buildings, resources (trees, mines,
berries, farms) and grass. Anything it doesn't cover keeps the built-in art.

> **Personal packs stay personal.** The `artpack/` folder is listed in `.gitignore`, so
> a pack never ends up on GitHub. Only share a pack, or an APK built with one, if you
> have the right to share every image in it. Free packs such as Kenney (CC0) are fine.
> Art from commercial games, Tiny Swords (whose licence forbids redistribution) or
> your own copy of another game is for your own device only.

## Where the game looks

The game uses the first of these folders that contains a `pack.json`:

| Folder | Use it for |
|---|---|
| `godot-rts/artpack/` (inside the project) | Building **your own APK** with the pack inside it (see below) |
| `user://artpack/` (the game's data folder) | Desktop play. On Linux: `~/.local/share/godot/app_userdata/Tiny Realms/artpack/`. On Windows: `%APPDATA%\Godot\app_userdata\Tiny Realms\artpack\` |
| `Documents/TinyRealms/artpack/` | Best effort. Newer Android versions may block reading this folder |

**Settings → Art pack** in the main menu shows which pack was loaded, how many overrides
it has, any problems, and the exact folders. Press **Reload art pack** after changing
files.

## Putting a pack on your phone

The reliable route on Android is to build your own APK with the pack inside:

1. Put the pack in `godot-rts/artpack/`, with `pack.json` directly inside that folder.
2. Open the project in Godot 4.3. It imports the images automatically.
3. Export the Android APK as described in the README (`build/TinyRealms.apk`) and
   install it on your phone.

`export_presets.cfg` already includes `artpack/*.json`, and the images are packed
automatically.

## pack.json

All image paths are relative to the folder that holds `pack.json`. PNG is recommended.

```json
{
  "name": "My Pack",

  "units": {
    "villager": {
      "image": "units/villager_{team}.png",
      "frame": [64, 64],
      "anchor": [32, 58],
      "scale": 0.8,
      "directions": ["S", "SW", "W", "NW", "N"],
      "mirror": true,
      "anims": {
        "idle":   {"y": 0,    "frames": 1},
        "walk":   {"y": 0,    "frames": 8},
        "work":   {"y": 320,  "frames": 8},
        "attack": {"y": 640,  "frames": 6},
        "death":  {"y": 960,  "frames": 6}
      }
    }
  },

  "buildings": {
    "house": {"image": "buildings/house_{team}.png", "anchor": [64, 96], "scale": 1.0,
              "construction": "buildings/house_build.png"}
  },

  "resources": {
    "tree":    {"images": ["trees/a.png", "trees/b.png", "trees/c.png"], "anchor": [24, 60]},
    "gold":    {"images": ["mines/gold.png"], "anchor": [24, 24]},
    "stone":   {"images": ["mines/stone.png"], "anchor": [24, 24]},
    "berries": {"images": ["food/bush.png"], "anchor": [20, 24]},
    "farm":    {"images": ["food/farm.png"], "anchor": [32, 32]}
  },

  "terrain": {"grass": "terrain/grass.png", "dry_grass": "terrain/dry.png"}
}
```

### Units

| Key | Meaning |
|---|---|
| `image` | The sprite sheet. `{team}` is replaced by `blue`, `red` (or `nature` for animals). Without `{team}`, one sheet is used for both sides |
| `frame` | Frame size in pixels `[width, height]` (can also be set per animation) |
| `anchor` | Pixel inside a frame that stands on the ground (usually between the feet) |
| `scale` | Drawing scale. Units are roughly 30–40 px tall in game at scale 1 |
| `directions` | The direction of each row, top to bottom, using `N NE E SE S SW W NW`. You can list 1, 4, 5 or 8 |
| `mirror` | `true` mirrors missing east-side directions from the west side (the common "5 directions + mirror" layout) |
| `anims` | Per animation: `y` = pixel row where it starts (its direction rows follow one under another), `frames` = frames per row, plus an optional `frame`, `anchor` or `directions` override |

The game picks the closest direction for each unit's heading.

Animation names are `idle`, `walk`, `work` (villagers gathering or building), `attack` and
`death` (the last frame is left on the ground as a corpse). Missing ones fall back:
`work` → `attack` → `walk`, and `idle` ↔ `walk`.

Unit keys: `villager`, `swordsman`, `spearman`, `axeman`, `knight`, `archer`,
`crossbowman`, `monk`, `ram`, `catapult`, `sheep`, `deer`, `boar`.

### Buildings and resources

A single image each, placed so that `anchor` (a pixel in the image) sits at the centre of
the building's footprint. Footprints are 64×64 px (2×2 tiles) or 96×96 px (3×3 tiles).
`construction` is an optional image used while the building is unfinished; otherwise the
built-in scaffolding is shown. Resources pick one of their `images` per tile, at random.

Building keys: `town_center`, `house`, `farm`, `mill`, `lumber_camp`, `mining_camp`,
`barracks`, `archery_range`, `siege_workshop`, `watch_tower`, `monastery`.

### Terrain

`grass` and `dry_grass` are seamless tiles blended by the ground shader. Water, roads and
flowers are drawn on top.

## Using graphics from a game you own

Some players want to see graphics from a commercial game they own. Tiny Realms will
never ship or download such files. To view them on your own device:

1. Convert the graphics from **your own installed copy** with a tool made for that
   game. For example, the openage project (https://github.com/SFTtech/openage)
   documents a converter that reads an installed Age of Empires II and writes ordinary
   PNG sprite sheets.
2. Arrange the frames into sheets described by `pack.json` as above. Most RTS sprites
   use the "5 directions + mirror" layout (`"mirror": true`).
3. Install the pack using one of the folders above, for **your own use only**. Don't
   commit, upload or share it, or any APK built with it.

## Troubleshooting

Settings lists the first problem found. Typical messages:

| Message | Fix |
|---|---|
| `pack.json is not valid JSON` | Check for missing commas or quotes (try an online JSON validator) |
| `units/x: can't load path` | Wrong path or file name; paths are case-sensitive on Android |
| `units/x: missing "anims"` | Every unit needs an `anims` object |

Entries with problems are skipped, and the built-in art is used for them instead.
