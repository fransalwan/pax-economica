class_name MapView
extends Node2D

const MAP_WIDTH: int = 1320
const MAP_HEIGHT: int = 720

var id_image: Image
var id_texture: ImageTexture
var lut_image: Image
var lut_texture: ImageTexture

var map_sprite: Sprite2D
var shader_mat: ShaderMaterial
var hovered_province_id: int = -1

func _ready() -> void:
	_generate_province_id_bitmap()
	_generate_lut_texture()
	_setup_map_sprite()
	update_map_mode_colors()
	
	EventBus.tick_completed.connect(_on_tick_completed)
	EventBus.map_mode_changed.connect(_on_map_mode_changed)
	EventBus.policy_updated.connect(func(_nid: String): update_map_mode_colors(); queue_redraw())

func _generate_province_id_bitmap() -> void:
	id_image = Image.create(MAP_WIDTH, MAP_HEIGHT, false, Image.FORMAT_RGBA8)
	id_image.fill(Color(0, 0, 0, 1))
	
	for pid in WorldEconomy.provinces.keys():
		var prov: Province = WorldEconomy.provinces[pid]
		var poly: PackedVector2Array = prov.polygon_points
		if poly.is_empty():
			continue
		
		# Hitung bounding box poligon untuk mengisi piksel ID provinsi di kanal R
		var min_x: int = MAP_WIDTH
		var max_x: int = 0
		var min_y: int = MAP_HEIGHT
		var max_y: int = 0
		for pt in poly:
			min_x = mini(min_x, int(pt.x))
			max_x = maxi(max_x, int(pt.x))
			min_y = mini(min_y, int(pt.y))
			max_y = maxi(max_y, int(pt.y))
		
		var encoded_color := Color(float(pid) / 255.0, 0.0, 0.0, 1.0)
		for y in range(maxi(0, min_y), mini(MAP_HEIGHT, max_y + 1)):
			for x in range(maxi(0, min_x), mini(MAP_WIDTH, max_x + 1)):
				if Geometry2D.is_point_in_polygon(Vector2(x, y), poly):
					id_image.set_pixel(x, y, encoded_color)
	
	id_texture = ImageTexture.create_from_image(id_image)

func _generate_lut_texture() -> void:
	lut_image = Image.create(256, 1, false, Image.FORMAT_RGBA8)
	lut_image.fill(Color(0.1, 0.1, 0.1, 1.0))
	lut_texture = ImageTexture.create_from_image(lut_image)

func _setup_map_sprite() -> void:
	map_sprite = Sprite2D.new()
	map_sprite.centered = false
	map_sprite.texture = id_texture
	
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = load("res://src/map/shaders/map_province.gdshader")
	shader_mat.set_shader_parameter("province_id_tex", id_texture)
	shader_mat.set_shader_parameter("province_lut_tex", lut_texture)
	shader_mat.set_shader_parameter("selected_province_id", WorldEconomy.selected_province_id)
	shader_mat.set_shader_parameter("tex_size", Vector2(MAP_WIDTH, MAP_HEIGHT))
	map_sprite.material = shader_mat
	add_child(map_sprite)

func update_map_mode_colors() -> void:
	var mode: String = WorldEconomy.current_map_mode
	for pid in WorldEconomy.provinces.keys():
		var prov: Province = WorldEconomy.provinces[pid]
		var nation: Nation = WorldEconomy.nations.get(prov.owner_nation_id)
		var col: Color = Color.GRAY
		
		match mode:
			"political":
				col = nation.map_color if nation else Color.GRAY
				# Variasi rona halus per provinsi agar batas makin jelas
				col = col.lightened(float(pid % 3) * 0.05)
			"gdp":
				# Heatmap GDP Provinsi (Merah -> Kuning -> Hijau Zamrud)
				var t: float = clampf(prov.local_nominal_gdp / 60_000.0, 0.0, 1.0)
				col = Color("#b62324").lerp(Color("#d29922"), clampf(t * 2.0, 0.0, 1.0))
				if t > 0.5:
					col = Color("#d29922").lerp(Color("#2ea043"), (t - 0.5) * 2.0)
			"sol":
				# Heatmap Standard of Living (0 - 100)
				var t: float = clampf((prov.standard_of_living - 25.0) / 55.0, 0.0, 1.0)
				col = Color("#da3633").lerp(Color("#2ea043"), t)
			"unemployment":
				# Heatmap Pengangguran (Hijau rendah -> Merah tinggi)
				var t: float = clampf(prov.unemployment_rate / 0.25, 0.0, 1.0)
				col = Color("#2ea043").lerp(Color("#da3633"), t)
			"infra":
				# Heatmap Level Infrastruktur (1 - 10)
				var t: float = clampf(float(prov.infrastructure_level) / 8.0, 0.0, 1.0)
				col = Color("#30363d").lerp(Color("#58a6ff"), t)
		
		lut_image.set_pixel(pid, 0, col)
	
	lut_texture.update(lut_image)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var local_pos: Vector2 = to_local(get_global_mouse_position())
		var pid: int = _pick_province_at(local_pos)
		if pid != hovered_province_id:
			hovered_province_id = pid
			shader_mat.set_shader_parameter("hovered_province_id", hovered_province_id)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var local_pos: Vector2 = to_local(get_global_mouse_position())
			var pid: int = _pick_province_at(local_pos)
			if pid > 0:
				WorldEconomy.selected_province_id = pid
				shader_mat.set_shader_parameter("selected_province_id", pid)
				EventBus.province_selected.emit(pid)
				queue_redraw()

func _pick_province_at(pos: Vector2) -> int:
	var x: int = int(pos.x)
	var y: int = int(pos.y)
	if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT:
		return -1
	var c: Color = id_image.get_pixel(x, y)
	return int(round(c.r * 255.0))

func _on_tick_completed(_year: int, _month: int) -> void:
	update_map_mode_colors()
	queue_redraw()

func _on_map_mode_changed(_mode_id: String) -> void:
	update_map_mode_colors()
	queue_redraw()

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	
	# Gambar jalur logistik & perdagangan laut antar-ibu kota/provinsi
	var routes: Array = [
		[1, 2], [2, 4], [4, 6], [1, 3], [3, 5], [5, 7], [7, 8], [8, 9], [1, 10], [10, 11], [11, 12]
	]
	for pair in routes:
		var p1: Province = WorldEconomy.get_province(pair[0])
		var p2: Province = WorldEconomy.get_province(pair[1])
		if p1 and p2:
			draw_dashed_line(p1.center_pos, p2.center_pos, Color(1, 1, 1, 0.22), 2.0, 7.0)
	
	# Gambar label nama provinsi & metrik sesuai Map Mode aktif
	var mode: String = WorldEconomy.current_map_mode
	for pid in WorldEconomy.provinces.keys():
		var prov: Province = WorldEconomy.provinces[pid]
		var pos: Vector2 = prov.center_pos
		
		# Kotak latar belakang label agar selalu terbaca tajam
		var box_rect := Rect2(pos.x - 82, pos.y - 24, 164, 46)
		var is_sel: bool = (pid == WorldEconomy.selected_province_id)
		var bg_col := Color(0.06, 0.08, 0.12, 0.85) if not is_sel else Color(0.14, 0.18, 0.26, 0.95)
		draw_rect(box_rect, bg_col, true)
		var border_col := Color("#d4af37") if is_sel else Color(1, 1, 1, 0.25)
		draw_rect(box_rect, border_col, false, 1.5 if is_sel else 1.0)
		
		draw_string(font, Vector2(pos.x - 76, pos.y - 6), prov.name, HORIZONTAL_ALIGNMENT_CENTER, 152, 13, Color.WHITE)
		
		var sub_text: String = ""
		match mode:
			"political":
				var nat: Nation = WorldEconomy.nations.get(prov.owner_nation_id)
				sub_text = "%s | %s" % [nat.currency_code if nat else "", FormatUtils.format_population(prov.population)]
			"gdp":
				sub_text = "PDB: %s/bln" % FormatUtils.format_currency(prov.local_nominal_gdp, "")
			"sol":
				sub_text = "SoL: %.1f / 100" % prov.standard_of_living
			"unemployment":
				sub_text = "Pengangguran: %s" % FormatUtils.format_percent(prov.unemployment_rate)
			"infra":
				sub_text = "Infra Lv.%d (Efisiensi %s)" % [prov.infrastructure_level, FormatUtils.format_percent(prov.get_infrastructure_efficiency())]
		
		draw_string(font, Vector2(pos.x - 76, pos.y + 13), sub_text, HORIZONTAL_ALIGNMENT_CENTER, 152, 11, Color("#e6edf3"))
