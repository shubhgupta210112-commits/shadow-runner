extends Node
## Global audio (autoload "AudioManager"): SFX pool, music crossfade, ambience.
## All audio in this project is original synthesised audio (see tools/gen_audio.py).

const SFX_PATHS := {
	&"jump": "res://assets/audio/sfx/jump.wav",
	&"land": "res://assets/audio/sfx/land.wav",
	&"coin": "res://assets/audio/sfx/coin.wav",
	&"shard": "res://assets/audio/sfx/shard.wav",
	&"heal": "res://assets/audio/sfx/heal.wav",
	&"hurt": "res://assets/audio/sfx/hurt.wav",
	&"shoot": "res://assets/audio/sfx/shoot.wav",
	&"enemy_die": "res://assets/audio/sfx/enemy_die.wav",
	&"stomp": "res://assets/audio/sfx/stomp.wav",
	&"checkpoint": "res://assets/audio/sfx/checkpoint.wav",
	&"lever": "res://assets/audio/sfx/lever.wav",
	&"gate": "res://assets/audio/sfx/gate.wav",
	&"ui_move": "res://assets/audio/sfx/ui_move.wav",
	&"ui_select": "res://assets/audio/sfx/ui_select.wav",
	&"ui_back": "res://assets/audio/sfx/ui_back.wav",
	&"ui_pause": "res://assets/audio/sfx/ui_pause.wav",
	&"spore": "res://assets/audio/sfx/spore.wav",
	&"boss_roar": "res://assets/audio/sfx/boss_roar.wav",
	&"boss_hit": "res://assets/audio/sfx/boss_hit.wav",
	&"boss_slam": "res://assets/audio/sfx/boss_slam.wav",
	&"boss_charge": "res://assets/audio/sfx/boss_charge.wav",
	&"boss_defeat": "res://assets/audio/sfx/boss_defeat.wav",
	&"victory": "res://assets/audio/sfx/victory.wav",
	&"game_over": "res://assets/audio/sfx/game_over.wav",
	&"respawn": "res://assets/audio/sfx/respawn.wav",
}

const MUSIC_PATHS := {
	&"menu": "res://assets/audio/music/menu_theme.ogg",
	&"forest": "res://assets/audio/music/forest_theme.ogg",
	&"boss": "res://assets/audio/music/boss_theme.ogg",
}

const AMBIENT_PATHS := {
	&"wind": "res://assets/audio/ambient/wind.ogg",
	&"night": "res://assets/audio/ambient/night.ogg",
}

const SFX_VOICES := 14
const SILENT_DB := -60.0

var SFX: Dictionary = {}
var MUSIC: Dictionary = {}
var AMBIENT: Dictionary = {}

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
var _music_players: Array[AudioStreamPlayer] = []
var _music_active: int = 0
var _current_music: StringName = &""
var _ambient_players: Dictionary = {}
var _music_tween: Tween
var _ducked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_load_streams()
	for key in MUSIC:
		(MUSIC[key] as AudioStreamOggVorbis).loop = true
	for key in AMBIENT:
		(AMBIENT[key] as AudioStreamOggVorbis).loop = true
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_players.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = &"Music"
		m.volume_db = SILENT_DB
		add_child(m)
		_music_players.append(m)
	for key in AMBIENT:
		var a := AudioStreamPlayer.new()
		a.bus = &"Ambient"
		a.stream = AMBIENT[key]
		a.volume_db = SILENT_DB
		add_child(a)
		_ambient_players[key] = a
	GameManager.settings_changed.connect(apply_volumes)
	apply_volumes()


func _load_streams() -> void:
	## Loaded at runtime (not preload) so a first-time project import never
	## trips over audio that has not been imported yet.
	for key in SFX_PATHS:
		SFX[key] = load(SFX_PATHS[key])
	for key in MUSIC_PATHS:
		MUSIC[key] = load(MUSIC_PATHS[key])
	for key in AMBIENT_PATHS:
		AMBIENT[key] = load(AMBIENT_PATHS[key])


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX", "Ambient"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")


func apply_volumes() -> void:
	_set_bus("Music", GameManager.music_volume * (0.35 if _ducked else 1.0))
	_set_bus("SFX", GameManager.sfx_volume)
	_set_bus("Ambient", GameManager.ambient_volume)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


func play_sfx(sfx_name: StringName, volume_db: float = 0.0, pitch: float = 1.0, pitch_jitter: float = 0.0) -> void:
	if not SFX.has(sfx_name):
		push_warning("AudioManager: unknown sfx '%s'" % sfx_name)
		return
	var p := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % SFX_VOICES
	p.stream = SFX[sfx_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func play_music(track: StringName, fade: float = 1.2) -> void:
	if track == _current_music:
		return
	_current_music = track
	var old := _music_players[_music_active]
	_music_active = 1 - _music_active
	var nxt := _music_players[_music_active]
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	if track != &"" and MUSIC.has(track):
		nxt.stream = MUSIC[track]
		nxt.volume_db = SILENT_DB
		nxt.play()
		_music_tween.tween_property(nxt, "volume_db", 0.0, fade)
	_music_tween.tween_property(old, "volume_db", SILENT_DB, fade)
	_music_tween.chain().tween_callback(old.stop)


func stop_music(fade: float = 1.0) -> void:
	play_music(&"", fade)


func play_ambient(layers: Array[StringName], fade: float = 2.0) -> void:
	for key in _ambient_players:
		var p: AudioStreamPlayer = _ambient_players[key]
		var want := layers.has(key)
		if want and not p.playing:
			p.volume_db = SILENT_DB
			p.play()
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -4.0 if want else SILENT_DB, fade)
		if not want:
			tw.tween_callback(p.stop)


func stop_ambient(fade: float = 1.0) -> void:
	var none: Array[StringName] = []
	play_ambient(none, fade)


func set_music_ducked(on: bool) -> void:
	_ducked = on
	apply_volumes()
