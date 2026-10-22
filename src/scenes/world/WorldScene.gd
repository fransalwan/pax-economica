extends Node2D

var map_view: MapView
var map_camera: MapCamera
var macro_hud: MacroHUD

func _ready() -> void:
	map_view = MapView.new()
	add_child(map_view)
	
	map_camera = MapCamera.new()
	add_child(map_camera)
	
	macro_hud = MacroHUD.new()
	add_child(macro_hud)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var ke := event as InputEventKey
		match ke.keycode:
			KEY_SPACE:
				SimulationClock.toggle_pause()
			KEY_1:
				SimulationClock.set_speed(1)
			KEY_2:
				SimulationClock.set_speed(2)
			KEY_3:
				SimulationClock.set_speed(5)
			KEY_F1:
				WorldEconomy.current_map_mode = "political"
				EventBus.map_mode_changed.emit("political")
			KEY_F2:
				WorldEconomy.current_map_mode = "gdp"
				EventBus.map_mode_changed.emit("gdp")
			KEY_F3:
				WorldEconomy.current_map_mode = "sol"
				EventBus.map_mode_changed.emit("sol")
			KEY_F4:
				WorldEconomy.current_map_mode = "unemployment"
				EventBus.map_mode_changed.emit("unemployment")
			KEY_F5:
				WorldEconomy.current_map_mode = "infra"
				EventBus.map_mode_changed.emit("infra")

