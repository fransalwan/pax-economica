extends Node

var current_year: int = 1850
var current_month: int = 1
var is_paused: bool = false
var speed_multiplier: int = 1 # 1x, 2x, 5x

var _accumulated_time: float = 0.0
const BASE_SECONDS_PER_TICK: float = 2.0

func _process(delta: float) -> void:
	if is_paused or speed_multiplier <= 0:
		return
	
	_accumulated_time += delta * float(speed_multiplier)
	if _accumulated_time >= BASE_SECONDS_PER_TICK:
		_accumulated_time -= BASE_SECONDS_PER_TICK
		advance_one_month()

func advance_one_month() -> void:
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	
	WorldEconomy.process_monthly_tick(current_year, current_month)
	EventBus.tick_completed.emit(current_year, current_month)

func set_paused(paused: bool) -> void:
	is_paused = paused
	EventBus.speed_changed.emit(speed_multiplier, is_paused)

func toggle_pause() -> void:
	set_paused(not is_paused)

func set_speed(multiplier: int) -> void:
	speed_multiplier = clampi(multiplier, 1, 5)
	is_paused = false
	EventBus.speed_changed.emit(speed_multiplier, is_paused)
