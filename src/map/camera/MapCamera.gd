class_name MapCamera
extends Camera2D

var zoom_level: float = 1.0
const MIN_ZOOM: float = 0.65
const MAX_ZOOM: float = 2.40
const ZOOM_SPEED: float = 0.12
const PAN_SPEED: float = 520.0

var _is_dragging: bool = false

func _ready() -> void:
	position = Vector2(660, 360)
	zoom = Vector2(zoom_level, zoom_level)

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	
	if dir != Vector2.ZERO:
		position += dir.normalized() * (PAN_SPEED / zoom_level) * delta
		_clamp_camera_bounds()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_set_zoom(zoom_level + ZOOM_SPEED)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_set_zoom(zoom_level - ZOOM_SPEED)
	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		position -= mm.relative / zoom_level
		_clamp_camera_bounds()

func _set_zoom(new_zoom: float) -> void:
	zoom_level = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(zoom_level, zoom_level)

func _clamp_camera_bounds() -> void:
	position.x = clampf(position.x, 200.0, 1150.0)
	position.y = clampf(position.y, 120.0, 620.0)

