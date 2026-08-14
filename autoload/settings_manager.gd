extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"

const DEFAULT_LOCALE := "en"
## Design / release resolution (also used as invalid-mode fallback base).
const DEFAULT_WIDTH := 1920
const DEFAULT_HEIGHT := 1080
const DEFAULT_MODE := "window"
## First-run defaults when running from the Godot editor (F5).
const EDITOR_DEFAULT_WIDTH := 1600
const EDITOR_DEFAULT_HEIGHT := 900
const EDITOR_DEFAULT_MODE := "window"
## First-run defaults for exported builds.
const RELEASE_DEFAULT_MODE := "fullscreen"
const DEFAULT_VSYNC := true
const DEFAULT_MAX_FPS := 0
const DEFAULT_VOLUME := 1.0
const DEFAULT_BACKGROUND := false
const DEFAULT_FONT_FAMILY := "sans"

const RESOLUTION_CANDIDATES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

const DISPLAY_MODES: PackedStringArray = ["window", "fullscreen", "borderless"]
const MAX_FPS_OPTIONS: Array[int] = [0, 30, 60, 120, 144]
const FONT_FAMILIES: PackedStringArray = ["sans", "serif"]
const FONT_SANS_PATH := "res://assets/fonts/KR/NotoSansKR-Regular.ttf"
const FONT_SERIF_PATH := "res://assets/fonts/KR/NotoSerifKR-Regular.otf"
const UI_THEME_PATHS: PackedStringArray = [
	"res://ui/shared/themes/ui_theme.tres",
	"res://ui/inventory/themes/inventory_theme.tres",
	"res://ui/stats/themes/stats_theme.tres",
]

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

var locale: String = DEFAULT_LOCALE
var width: int = DEFAULT_WIDTH
var height: int = DEFAULT_HEIGHT
var mode: String = DEFAULT_MODE
var vsync: bool = DEFAULT_VSYNC
var max_fps: int = DEFAULT_MAX_FPS
var master_volume: float = DEFAULT_VOLUME
var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
var background_audio: bool = DEFAULT_BACKGROUND
var font_family: String = DEFAULT_FONT_FAMILY

var _master_muted_for_focus: bool = false
var _font_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	load_settings()
	apply_all()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_apply_focus_audio(false)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_apply_focus_audio(true)


func _ensure_audio_buses() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, BUS_MASTER)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_reset_to_defaults()
		return
	var default_res := _default_resolution()
	var default_mode := _default_display_mode()
	locale = str(config.get_value("ui", "locale", DEFAULT_LOCALE))
	font_family = str(config.get_value("ui", "font_family", DEFAULT_FONT_FAMILY))
	if not FONT_FAMILIES.has(font_family):
		font_family = DEFAULT_FONT_FAMILY
	width = int(config.get_value("display", "width", default_res.x))
	height = int(config.get_value("display", "height", default_res.y))
	mode = str(config.get_value("display", "mode", default_mode))
	if not DISPLAY_MODES.has(mode):
		mode = default_mode
	vsync = bool(config.get_value("display", "vsync", DEFAULT_VSYNC))
	max_fps = int(config.get_value("display", "max_fps", DEFAULT_MAX_FPS))
	if not MAX_FPS_OPTIONS.has(max_fps):
		max_fps = DEFAULT_MAX_FPS
	master_volume = clampf(float(config.get_value("audio", "master", DEFAULT_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music", DEFAULT_VOLUME)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx", DEFAULT_VOLUME)), 0.0, 1.0)
	background_audio = bool(config.get_value("audio", "background", DEFAULT_BACKGROUND))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("ui", "locale", locale)
	config.set_value("ui", "font_family", font_family)
	config.set_value("display", "width", width)
	config.set_value("display", "height", height)
	config.set_value("display", "mode", mode)
	config.set_value("display", "vsync", vsync)
	config.set_value("display", "max_fps", max_fps)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "background", background_audio)
	config.save(SETTINGS_PATH)


## Deletes settings.cfg and restores in-memory defaults (does not rewrite the file).
func reset_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)
	_reset_to_defaults()
	apply_all()
	settings_changed.emit()


func apply_all() -> void:
	apply_display()
	apply_audio()
	apply_font()


func get_locale() -> String:
	return locale


func set_locale(code: String, persist: bool = true) -> void:
	locale = code
	if persist:
		save_settings()
	settings_changed.emit()


func set_resolution(new_width: int, new_height: int, persist: bool = true) -> void:
	width = new_width
	height = new_height
	apply_display()
	if persist:
		save_settings()
	settings_changed.emit()


func set_display_mode(new_mode: String, persist: bool = true) -> void:
	if not DISPLAY_MODES.has(new_mode):
		new_mode = DEFAULT_MODE
	mode = new_mode
	apply_display()
	if persist:
		save_settings()
	settings_changed.emit()


func set_vsync(enabled: bool, persist: bool = true) -> void:
	vsync = enabled
	apply_display()
	if persist:
		save_settings()
	settings_changed.emit()


func set_max_fps(value: int, persist: bool = true) -> void:
	if not MAX_FPS_OPTIONS.has(value):
		value = DEFAULT_MAX_FPS
	max_fps = value
	apply_display()
	if persist:
		save_settings()
	settings_changed.emit()


func set_master_volume(value: float, persist: bool = true) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	if persist:
		save_settings()
	settings_changed.emit()


func set_music_volume(value: float, persist: bool = true) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	if persist:
		save_settings()
	settings_changed.emit()


func set_sfx_volume(value: float, persist: bool = true) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	if persist:
		save_settings()
	settings_changed.emit()


func set_background_audio(enabled: bool, persist: bool = true) -> void:
	background_audio = enabled
	if persist:
		save_settings()
	settings_changed.emit()


func set_font_family(family: String, persist: bool = true) -> void:
	if not FONT_FAMILIES.has(family):
		family = DEFAULT_FONT_FAMILY
	font_family = family
	apply_font()
	if persist:
		save_settings()
	settings_changed.emit()


func get_available_resolutions() -> Array[Vector2i]:
	var screen := DisplayServer.screen_get_size()
	var result: Array[Vector2i] = []
	for res in RESOLUTION_CANDIDATES:
		if res.x <= screen.x and res.y <= screen.y:
			result.append(res)
	if result.is_empty():
		result.append(_default_resolution())
	return result


func apply_display() -> void:
	Engine.max_fps = max_fps
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
	match mode:
		"fullscreen":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(width, height))
			_center_window()


func apply_audio() -> void:
	_set_bus_linear(BUS_MASTER, master_volume)
	_set_bus_linear(BUS_MUSIC, music_volume)
	_set_bus_linear(BUS_SFX, sfx_volume)
	if _master_muted_for_focus and not background_audio:
		_mute_master(true)


func apply_font() -> void:
	var font := _load_font(font_family)
	if font == null:
		push_warning("SettingsManager: failed to load font family '%s'" % font_family)
		return
	ThemeDB.fallback_font = font
	for path in UI_THEME_PATHS:
		var theme := load(path) as Theme
		if theme:
			theme.default_font = font
	var tree := get_tree()
	if tree == null:
		return
	var root := tree.root
	if root.theme == null:
		var root_theme := Theme.new()
		root_theme.default_font = font
		root.theme = root_theme
	else:
		root.theme.default_font = font


func _load_font(family: String) -> Font:
	var path := FONT_SERIF_PATH if family == "serif" else FONT_SANS_PATH
	if _font_cache.has(path):
		return _font_cache[path] as Font
	var font := load(path) as Font
	if font:
		_font_cache[path] = font
	return font


func _default_resolution() -> Vector2i:
	if OS.has_feature("editor"):
		return Vector2i(EDITOR_DEFAULT_WIDTH, EDITOR_DEFAULT_HEIGHT)
	return Vector2i(DEFAULT_WIDTH, DEFAULT_HEIGHT)


func _default_display_mode() -> String:
	if OS.has_feature("editor"):
		return EDITOR_DEFAULT_MODE
	return RELEASE_DEFAULT_MODE


func _reset_to_defaults() -> void:
	locale = DEFAULT_LOCALE
	font_family = DEFAULT_FONT_FAMILY
	var res := _default_resolution()
	width = res.x
	height = res.y
	mode = _default_display_mode()
	vsync = DEFAULT_VSYNC
	max_fps = DEFAULT_MAX_FPS
	master_volume = DEFAULT_VOLUME
	music_volume = DEFAULT_VOLUME
	sfx_volume = DEFAULT_VOLUME
	background_audio = DEFAULT_BACKGROUND


func _center_window() -> void:
	var screen := DisplayServer.screen_get_size()
	var pos := Vector2i(
		maxi((screen.x - width) / 2, 0),
		maxi((screen.y - height) / 2, 0)
	)
	DisplayServer.window_set_position(pos)


func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var clamped := clampf(linear, 0.0, 1.0)
	if clamped <= 0.0001:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clamped))


func _mute_master(muted: bool) -> void:
	var idx := AudioServer.get_bus_index(BUS_MASTER)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, muted)


func _apply_focus_audio(focused: bool) -> void:
	if background_audio:
		if _master_muted_for_focus:
			_mute_master(false)
			_master_muted_for_focus = false
		return
	if focused:
		if _master_muted_for_focus:
			_mute_master(false)
			_master_muted_for_focus = false
	else:
		_mute_master(true)
		_master_muted_for_focus = true
