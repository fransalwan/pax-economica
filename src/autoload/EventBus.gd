extends Node

signal tick_completed(year: int, month: int)
signal speed_changed(speed_multiplier: int, is_paused: bool)
signal province_selected(province_id: int)
signal map_mode_changed(mode_id: String)
signal policy_updated(nation_id: String)
signal macro_shock_triggered(title: String, description: String, advice: String)
signal notification_posted(message: String, severity: String)
