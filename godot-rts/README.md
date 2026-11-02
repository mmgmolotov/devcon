# Tiny Realms: a small mobile RTS (Godot 4)

An original, compact real-time strategy game for Android phones in landscape.
Gather resources, grow your village, raise an army and destroy the enemy Town Center
before they destroy yours. All art is procedural (drawn in code and shaders); there
are no third-party or copyrighted assets.

## Look and feel

- **3/4 top-down medieval style**: stone-keep Town Center with towers and banners,
  timber-frame thatched houses, a barracks hall with weapon racks, and construction
  stages with scaffolding.
- **Animated units**: walk cycles, axes/picks/hammers swinging while working, carried
  logs/sacks/stones, swordsmen with helmets and shields, archers drawing bows.
- **Effects**: wood chips, gold sparks, dust, chimney smoke, fire and smoke on damaged
  buildings, arrows flying in arcs, corpses, rubble and tree stumps.
- **Terrain shader**: textured grass with flowers, dirt yards and roads, ponds with
  animated water, foam and sandy shores.
- **Fog of war**: unexplored land is black, explored land you can't currently see is
  dimmed, and enemies are hidden outside your vision.
- **Medieval HUD**: wood-and-gold panels, serif font, drawn resource icons, a portrait
  of the selection with HP, and picture buttons.

## Gameplay

| | |
|---|---|
| **Map** | 64×64 tiles, procedurally generated and point-symmetric (fair for both sides): grass, forests (wood), gold mines and stone quarries |
| **Start** | 1 Town Center, 3 villagers, 200 wood, 100 gold |
| **Win / lose** | Destroy the enemy Town Center / lose your own |

**Units**

| Unit | Cost | Trained at | Notes |
|---|---|---|---|
| Villager | 50 wood | Town Center (10 s) | Gathers, builds, weak in combat |
| Swordsman | 20 wood, 50 gold | Barracks (14 s) | Tough melee unit, bonus vs buildings |
| Archer | 30 wood, 40 gold | Barracks (14 s) | Ranged (150 px), weak vs buildings |

**Buildings**

| Building | Cost | Build time | Notes |
|---|---|---|---|
| Town Center | – | – | +5 pop, trains villagers, resource drop-off, shoots arrows |
| House | 30 wood | 15 s | +5 population |
| Barracks | 150 wood, 50 stone | 30 s | Trains swordsmen and archers |

Population cap is 60. More villagers working on a building finish it faster.

**Enemy AI**: keeps its villagers gathering a balanced mix of resources, trains villagers,
builds houses before it runs out of population, builds a barracks, trains a mixed army and
defends its base. The first attack wave arrives at about 4:00, then every 2.5 minutes, with
waves getting larger over time.

## Controls

| Touch (phone) | Mouse (desktop testing) | Action |
|---|---|---|
| Tap own unit/building | Left click | Select |
| Double-tap a unit | Double click | Select all units of that type on screen |
| One-finger drag | Left drag | Box-select your units |
| Tap ground (units selected) | Left click | Move |
| Tap enemy (units selected) | Left click | Attack |
| Tap tree/mine (villagers selected) | Left click | Gather |
| Tap unfinished building (villagers selected) | Left click | Help build |
| Tap ground (Town Center/Barracks selected) | Left click | Set rally point |
| Two-finger drag | Right/middle drag, arrow keys | Pan camera |
| Pinch | Mouse wheel | Zoom |
| Tap/drag minimap | Click minimap | Jump camera |

Bottom bar buttons: **House**, **Barracks**, **Stop** (villagers), **Villager / Swordsman /
Archer**, **Cancel** (buildings) and **X** to deselect. Top bar: **Idle Villager** cycles
through idle villagers, **Army** selects all soldiers.

To place a building, press its button, tap the map to move the green/red ghost (or drag it),
then tap the ghost again or press **Build**.

## Project layout

```
godot-rts/
├── project.godot          # Landscape, canvas_items stretch, GL Compatibility renderer
├── export_presets.cfg     # Android preset (arm64-v8a, landscape, immersive)
├── core/
│   ├── game.gd            # Autoload "Game": data tables, economy, registry, selection, win/lose
│   ├── entity.gd          # Base class: team, HP, damage, death, health bar
│   └── art.gd             # Procedural art shared by units, buildings, resources and UI
├── fx/
│   ├── fx.gd              # Single-node particle system (chips, dust, smoke, fire)
│   └── decal.gd           # Fading corpses, rubble and stumps
├── map/
│   ├── game_map.gd/.tscn  # Map generation, terrain, ponds, AStarGrid2D, tile occupancy
│   ├── ground.gdshader    # Procedural grass/dirt/water shader
│   ├── fog_of_war.gd      # Player vision and explored-area tracking
│   └── resource_node.*    # Trees, gold, stone
├── units/
│   ├── unit.gd/.tscn      # Unit state machine: idle/move/attack/gather/return/build
│   └── projectile.*       # Arrows
├── buildings/
│   └── building.gd/.tscn  # Construction, training queue, rally point, drop-off, TC arrows
├── ui/
│   ├── hud.gd/.tscn       # Mobile HUD (built in code, adapts to any aspect ratio)
│   ├── icon_view.gd       # Renders game art inside HUD buttons and the portrait
│   ├── minimap.gd
│   ├── placement_ghost.gd
│   └── tap_marker.gd
├── ai/
│   └── enemy_ai.gd        # Opponent logic
├── main/
│   ├── main.gd/.tscn      # Match bootstrap
│   ├── input_controller.gd# Touch/mouse gestures to commands
│   └── rts_camera.gd      # Pan/zoom camera clamped to the map
└── tests/
    ├── smoke_test.*       # Headless end-to-end test (plays a whole match)
    └── screenshot.*       # Dev helper that renders a screenshot
```

**Design notes**
- Gameplay nodes communicate through the `Game` autoload (signals and entity lists), so
  scenes don't hold hard references to each other.
- Pathfinding uses one `AStarGrid2D` (64×64, diagonal moves only around obstacles).
  Buildings and resources mark their tiles solid. Units steer between waypoints, and a
  cheap spatial-hash separation pass stops them from stacking.
- Performance: the ground is one shader-drawn sprite fed by a 64×64 terrain map, and fog
  of war is one 64×64 texture. Static art (trees, mines, buildings) is cached by Godot and
  only redrawn when it changes. Animated units redraw at 15 fps, and all particles share
  one node. The simulation costs about 0.4 ms per frame headless (measured by the smoke
  test).

## Opening and running

1. Install **Godot 4.3** (standard build, not .NET): <https://godotengine.org/download>.
2. Open Godot, click **Import**, and select `godot-rts/project.godot`.
3. Press **F5** (Run Project). On desktop, play with the mouse (see controls above).
   To test touch gestures on desktop, enable *Project Settings → Input Devices → Pointing →
   Emulate Touch From Mouse* (single touch only).

### Running the tests (headless)

```bash
cd godot-rts
GODOT=/path/to/godot ./run_tests.sh
```

This imports the project, then plays a full match on fast-forward (~5 s of real time). It
checks: starting state, tap controls, training, construction, population cap, gathering, the
AI building a barracks, the AI sending a wave that reaches your base, victory by destroying
the enemy Town Center, a clean restart, and defeat when you lose yours. It exits non-zero on
any failed check or engine/script error.

## Exporting the APK (Android)

One-time setup:

1. **Export templates**: in Godot, *Editor → Manage Export Templates → Download and Install*.
2. **Java**: install OpenJDK 17.
3. **Android SDK**: install Android Studio, or the command-line tools plus
   `platform-tools` and `build-tools` (34.x) via `sdkmanager`.
4. In *Editor → Editor Settings → Export → Android*, set **Java SDK Path** and
   **Android SDK Path**. Godot generates a debug keystore automatically.

Export:

1. *Project → Export…*. The **Android** preset is already configured (arm64-v8a, landscape,
   immersive mode, package `com.tinyrealms.rts`).
2. Click **Export Project** and save as `build/TinyRealms.apk`. Use *Export With Debug*
   for a quick test build.
3. Install on a phone with USB debugging enabled: `adb install -r build/TinyRealms.apk`.
   You can also use the one-click deploy (Android icon) in the editor's top-right corner.

Command-line export (after the setup above):

```bash
cd godot-rts
mkdir -p build
godot --headless --export-debug "Android" build/TinyRealms.apk
```

**Release builds**: create your own keystore
(`keytool -genkeypair -v -keystore release.keystore -alias tinyrealms -keyalg RSA -keysize 2048 -validity 10000`),
fill in *Keystore → Release / User / Password* in the export dialog (these are stored in
`.godot/export_credentials.cfg`, which isn't committed), then use *Export Project* with
"Export With Debug" unticked. For Google Play, set *Gradle Build → Export Format* to AAB
(this requires *Project → Install Android Build Template*).
