extends Node

## Menyimpan konfigurasi perangkat lokal di user://settings.cfg
## Dipisahkan dari user://saves/ agar tidak menimpa resolusi lintas PC/Steam Deck saat Steam Auto-Cloud aktif.

const SETTINGS_PATH: String = "user://settings.cfg"

var ui_scale: float = 1.0
var fullscreen_mode: bool = false
var max_fps: int = 60
var master_volume_db: float = 0.0
var language_code: String = "id"

func _ready() -> void:
	load_settings()
	apply_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		save_settings()
		return
	ui_scale = clampf(float(cfg.get_value("display", "ui_scale", 1.0)), 0.8, 1.4)
	fullscreen_mode = bool(cfg.get_value("display", "fullscreen", false))
	max_fps = int(cfg.get_value("display", "max_fps", 60))
	master_volume_db = float(cfg.get_value("audio", "master_volume_db", 0.0))
	language_code = str(cfg.get_value("locale", "language", "id"))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "ui_scale", ui_scale)
	cfg.set_value("display", "fullscreen", fullscreen_mode)
	cfg.set_value("display", "max_fps", max_fps)
	cfg.set_value("audio", "master_volume_db", master_volume_db)
	cfg.set_value("locale", "language", language_code)
	cfg.save(SETTINGS_PATH)

func apply_settings() -> void:
	Engine.max_fps = max_fps
	if get_tree() and get_tree().root:
		get_tree().root.content_scale_factor = ui_scale
	if fullscreen_mode:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_ui_scale(new_scale: float) -> void:
	ui_scale = clampf(new_scale, 0.8, 1.4)
	apply_settings()
	save_settings()
