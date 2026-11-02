extends Node
## Sound effects, voice lines and music (autoload "Sound").
##
## All audio is CC0 (Kenney audio packs and the Ninja Adventure pack, see
## CREDITS.md). Effects use a small player pool, are skipped when off-screen,
## fade with distance from the camera and are rate-limited per sound so a
## crowd of woodcutters doesn't become noise. Music crossfades between the
## menu, peaceful village and battle themes.

const SETTINGS_PATH := "user://settings.cfg"
const POOL_SIZE := 12
const COMBAT_HOLD := 10.0

const SFX := {
	"chop": ["sfx/chop1.ogg", "sfx/chop2.ogg"],
	"mine": ["sfx/mine1.ogg", "sfx/mine2.ogg"],
	"gather": ["sfx/gather.ogg"],
	"build": ["sfx/build1.ogg", "sfx/build2.ogg"],
	"sword": ["sfx/sword1.ogg", "sfx/sword2.ogg", "sfx/sword3.ogg"],
	"hit": ["sfx/hit1.wav", "sfx/hit2.wav", "sfx/hit3.wav"],
	"arrow": ["sfx/arrow1.wav", "sfx/arrow2.wav"],
	"launch": ["sfx/launch.wav"],
	"stone_hit": ["sfx/stone_hit.ogg"],
	"ram": ["sfx/ram.ogg"],
	"death": ["sfx/death.ogg"],
	"collapse": ["sfx/collapse.ogg"],
	"heal": ["sfx/heal.wav"],
	"coins": ["sfx/coins.ogg"],
	"click": ["sfx/click.ogg"],
	"select": ["sfx/select.ogg"],
	"confirm": ["sfx/confirm.ogg"],
	"error": ["sfx/error.ogg"],
	"complete": ["sfx/complete.ogg"],
	"victory": ["sfx/victory.wav"],
	"defeat": ["sfx/defeat.wav"],
	"prepare_yourself": ["voice/prepare_yourself.ogg"],
	"you_win": ["voice/you_win.ogg"],
	"you_lose": ["voice/you_lose.ogg"],
	"fight": ["voice/fight.ogg"],
	"survival_mode": ["voice/survival_mode.ogg"],
}
## Minimum seconds between two plays of the same effect.
const GAPS := {"chop": 0.18, "mine": 0.18, "gather": 0.3, "build": 0.25, "sword": 0.07,
	"hit": 0.08, "arrow": 0.1, "death": 0.1, "coins": 0.4, "heal": 1.2}
const MUSIC := {"menu": "music/menu.ogg", "village": "music/village.ogg",
	"battle": "music/battle.ogg", "credits": "music/credits.ogg"}

var music_volume := 0.6
var sfx_volume := 0.8
var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}
var _music: Array[AudioStreamPlayer] = []
var _music_idx := 0
var _music_name := ""
var _combat_t := 0.0
var _in_game := false
## Own RNG so audio (which depends on wall-clock rate limits) never shifts the
## game simulation's random sequence.
var _rng := RandomNumberGenerator.new()
## No audio output in headless runs (tests/CI): skip playback entirely.
var _silent := DisplayServer.get_name() == "headless"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.volume_db = -80.0
		add_child(m)
		m.finished.connect(m.play)  # loop
		_music.append(m)
	load_settings()


## Stops everything and releases streams (call before quitting).
func stop_all() -> void:
	for p in _pool + _music:
		p.stop()
		p.stream = null
	_music_name = ""
	_streams.clear()


func _exit_tree() -> void:
	stop_all()


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load("res://audio/" + path)
	return _streams[path]


## Plays an effect. With a world position, it is skipped when far off-screen
## and gets quieter with distance from the camera centre.
func play(sound: String, world_pos = null, volume_db := 0.0) -> void:
	if _silent or sfx_volume <= 0.01 or not SFX.has(sound):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(sound, -10.0)) < GAPS.get(sound, 0.05):
		return
	var vol := volume_db
	if world_pos != null and Game.camera != null:
		if not Game.on_screen(world_pos, 120.0):
			return
		var d: float = Game.camera.position.distance_to(world_pos) * Game.camera.zoom.x
		vol -= clampf(d / 120.0, 0.0, 9.0)
	_last[sound] = now
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	var variants: Array = SFX[sound]
	p.stream = _stream(variants[_rng.randi() % variants.size()])
	p.volume_db = vol + linear_to_db(sfx_volume)
	p.pitch_scale = _rng.randf_range(0.93, 1.07) if world_pos != null else 1.0
	p.play()


## Crossfades to a music track ("" stops the music).
func play_music(track: String) -> void:
	if track == _music_name or _silent:
		return
	_music_name = track
	var old := _music[_music_idx]
	_music_idx = 1 - _music_idx
	var cur := _music[_music_idx]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(old, "volume_db", -60.0, 1.5)
	tw.chain().tween_callback(old.stop)
	if track != "":
		cur.stream = _stream(MUSIC[track])
		cur.volume_db = -60.0
		cur.play()
		create_tween().tween_property(cur, "volume_db", _music_db(), 1.5)


func _music_db() -> float:
	return linear_to_db(maxf(music_volume, 0.0001)) - 6.0


## Called by the game when fighting involves the player; switches to battle music.
func notify_combat() -> void:
	_combat_t = COMBAT_HOLD
	if _in_game and _music_name == "village":
		play_music("battle")


func set_in_game(on: bool) -> void:
	_in_game = on
	_combat_t = 0.0


func _process(delta: float) -> void:
	if _combat_t > 0.0:
		_combat_t -= delta
		if _combat_t <= 0.0 and _in_game and _music_name == "battle":
			play_music("village")


func set_volumes(music: float, sfx: float) -> void:
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	var cur := _music[_music_idx]
	if cur.playing:
		cur.volume_db = _music_db()
	save_settings()


# --- Settings ----------------------------------------------------------------------

var settings := {"difficulty": 1, "mode": "skirmish", "random_map": false}


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	for k in settings:
		settings[k] = cfg.get_value("game", k, settings[k])


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	for k in settings:
		cfg.set_value("game", k, settings[k])
	cfg.save(SETTINGS_PATH)
