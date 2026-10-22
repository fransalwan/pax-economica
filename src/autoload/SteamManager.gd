extends Node

## Wrapper Steamworks (GodotSteam GDExtension) dengan Safe Fallback.
## Aman dijalankan langsung dari Godot Editor walaupun Steam tidak aktif.

const STEAM_APP_ID_TEST: int = 480 # Spacewar Test AppID resmi Steam

var is_steam_enabled: bool = false
var steam_username: String = "Standalone Economist"
var unlocked_achievements: Dictionary = {}

func _ready() -> void:
	if ClassDB.class_exists("Steam"):
		var steam_singleton: Object = Engine.get_singleton("Steam")
		if steam_singleton and steam_singleton.has_method("steamInitEx"):
			var response: Dictionary = steam_singleton.call("steamInitEx", STEAM_APP_ID_TEST, true)
			if response.get("status", -1) == 0:
				is_steam_enabled = true
				steam_username = str(steam_singleton.call("getPersonaName"))
				print("[SteamManager] Steamworks aktif. User: ", steam_username)
			else:
				print("[SteamManager] Steam client tidak terdeteksi, berjalan di mode Standalone.")
	else:
		print("[SteamManager] Plugin GodotSteam belum terpasang, berjalan di mode Standalone.")

func _process(_delta: float) -> void:
	if is_steam_enabled and Engine.has_singleton("Steam"):
		Engine.get_singleton("Steam").call("run_callbacks")

func unlock_achievement(achievement_id: String) -> void:
	if unlocked_achievements.get(achievement_id, false):
		return
	unlocked_achievements[achievement_id] = true
	print("[SteamManager] Achievement Unlocked: ", achievement_id)
	EventBus.notification_posted.emit("🏆 Steam Achievement: %s" % achievement_id, "success")
	
	if is_steam_enabled and Engine.has_singleton("Steam"):
		var steam_singleton: Object = Engine.get_singleton("Steam")
		steam_singleton.call("setAchievement", achievement_id)
		steam_singleton.call("storeStats")

func update_rich_presence(nation_name: String, year: int, gdp_text: String, inflation_text: String) -> void:
	if is_steam_enabled and Engine.has_singleton("Steam"):
		var steam_singleton: Object = Engine.get_singleton("Steam")
		var status_str: String = "%s (%d) | GDP: %s | CPI: %s" % [nation_name, year, gdp_text, inflation_text]
		steam_singleton.call("setRichPresence", "steam_display", "#StatusFull")
		steam_singleton.call("setRichPresence", "status", status_str)

