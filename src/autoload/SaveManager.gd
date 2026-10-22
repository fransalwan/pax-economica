extends Node

## Mengelola penyimpanan save game ber-versi di user://saves/ untuk kompatibilitas Steam Auto-Cloud.

const SAVE_DIR: String = "user://saves"
const SAVE_VERSION: int = 1

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot_name: String = "autosave") -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file_path: String = "%s/%s.json" % [SAVE_DIR, slot_name]
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Gagal membuka file save: " + file_path)
		return false
	
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"year": SimulationClock.current_year,
		"month": SimulationClock.current_month,
		"economy": WorldEconomy.serialize_state()
	}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	EventBus.notification_posted.emit("💾 Game disimpan ke %s.json" % slot_name, "info")
	return true

func load_game(slot_name: String = "autosave") -> bool:
	var file_path: String = "%s/%s.json" % [SAVE_DIR, slot_name]
	if not FileAccess.file_exists(file_path):
		EventBus.notification_posted.emit("File save tidak ditemukan: %s" % slot_name, "warning")
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	
	var data: Dictionary = parsed
	SimulationClock.current_year = int(data.get("year", 1850))
	SimulationClock.current_month = int(data.get("month", 1))
	if data.has("economy"):
		WorldEconomy.deserialize_state(data["economy"])
	
	EventBus.tick_completed.emit(SimulationClock.current_year, SimulationClock.current_month)
	EventBus.notification_posted.emit("📂 Save game '%s' berhasil dimuat!" % slot_name, "success")
	return true

