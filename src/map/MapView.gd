class_name MapView
extends Node2D

const MAP_WIDTH: int = 1600
const MAP_HEIGHT: int = 860

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
	EventBus.province_selected.connect(_on_province_selected_external)
	EventBus.policy_updated.connect(func(_nid: String): update_map_mode_colors(); queue_redraw())

func _generate_province_id_bitmap() -> void:
	id_image = Image.create(MAP_WIDTH, MAP_HEIGHT, false, Image.FORMAT_RGBA8)
	id_image.fill(Color(0, 0, 0, 1))
	
	for pid in WorldEconomy.provinces.keys():
		var prov: Province = WorldEconomy.provinces[pid]
		var poly: PackedVector2Array = prov.polygon_points
		if poly.is_empty():
			continue
		
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
	map_sprite.z_index = -1 # PENTING: Agar label, rute dagang, & ikon di _draw() tampil DI ATAS peta!
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
				col = col.lightened(float(pid % 3) * 0.04)
			"gdp":
				var t: float = clampf(prov.local_nominal_gdp / 18_000.0, 0.0, 1.0)
				col = Color("#b62324").lerp(Color("#d29922"), clampf(t * 2.0, 0.0, 1.0))
				if t > 0.5:
					col = Color("#d29922").lerp(Color("#2ea043"), (t - 0.5) * 2.0)
			"sol":
				var t: float = clampf((prov.standard_of_living - 30.0) / 65.0, 0.0, 1.0)
				col = Color("#da3633").lerp(Color("#2ea043"), t)
			"unemployment":
				var t: float = clampf(prov.unemployment_rate / 0.22, 0.0, 1.0)
				col = Color("#2ea043").lerp(Color("#da3633"), t)
			"infra":
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
			queue_redraw()
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

func _on_province_selected_external(pid: int) -> void:
	shader_mat.set_shader_parameter("selected_province_id", pid)
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
	
	# 1. Gambar jalur pelayaran & logistik dagang antar-provinsi
	var routes: Array = [
		[1, 2], [2, 4], [4, 6], [1, 3], [3, 5], [5, 2], [5, 7], [7, 8], [8, 9], [6, 8], [1, 10], [10, 11], [11, 12], [4, 11]
	]
	for pair in routes:
		var p1: Province = WorldEconomy.get_province(pair[0])
		var p2: Province = WorldEconomy.get_province(pair[1])
		if p1 and p2:
			draw_dashed_line(p1.center_pos, p2.center_pos, Color(0.85, 0.92, 1.0, 0.32), 2.0, 8.0)
	
	# 2. Gambar Header Wilayah Kekaisaran di Atas Peta (Supaya Pemain Langsung Paham Geopolitik)
	draw_string(font, Vector2(460, 118), "👑 KEKAISARAN NUSANTARA (WILAYAH KAMU - KLIK UNTUK MEMBANGUN)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#56d364"))
	draw_string(font, Vector2(880, 105), "🌐 PERSEMAKMURAN MERCIA (Mitra Dagang Industri)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#79c0ff"))
	draw_string(font, Vector2(540, 690), "🌐 IMPERIUM BOREALIS (Mitra Dagang Tambang & Gandum)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e3b341"))
	
	# 3. Gambar Kartu Label di Setiap Provinsi
	var mode: String = WorldEconomy.current_map_mode
	for pid in WorldEconomy.provinces.keys():
		var prov: Province = WorldEconomy.provinces[pid]
		var pos: Vector2 = prov.center_pos
		var is_sel: bool = (pid == WorldEconomy.selected_province_id)
		var is_hov: bool = (pid == hovered_province_id)
		var is_player_owned: bool = (prov.owner_nation_id == WorldEconomy.player_nation_id)
		
		var box_w: float = 176.0
		var box_h: float = 54.0
		var box_rect := Rect2(pos.x - box_w * 0.5, pos.y - box_h * 0.5, box_w, box_h)
		
		var bg_col := Color(0.05, 0.08, 0.12, 0.88)
		if is_sel:
			bg_col = Color(0.12, 0.22, 0.16, 0.96) if is_player_owned else Color(0.14, 0.18, 0.28, 0.96)
		elif is_hov:
			bg_col = Color(0.10, 0.14, 0.20, 0.92)
		
		draw_rect(box_rect, bg_col, true)
		
		var border_col: Color = Color(1, 1, 1, 0.28)
		var border_w: float = 1.0
		if is_sel:
			border_col = Color("#f2cc60")
			border_w = 2.5
		elif is_player_owned:
			border_col = Color("#3fb950", 0.75)
			border_w = 1.5
		draw_rect(box_rect, border_col, false, border_w)
		
		# Baris 1: Nama Provinsi
		var title_col := Color("#ffffff") if not is_sel else Color("#f2cc60")
		draw_string(font, Vector2(box_rect.position.x + 6, box_rect.position.y + 17), prov.name, HORIZONTAL_ALIGNMENT_CENTER, box_w - 12, 13, title_col)
		
		# Baris 2: Metrik utama sesuai Map Mode
		var sub_text: String = ""
		match mode:
			"political":
				var tag: String = "WILAYAHMU" if is_player_owned else prov.owner_nation_id.to_upper()
				sub_text = "[%s] %s" % [tag, FormatUtils.format_population(prov.population)]
			"gdp":
				sub_text = "PDB: %s/bln" % FormatUtils.format_currency(prov.local_nominal_gdp, "")
			"sol":
				sub_text = "Kesejahteraan: %.1f/100" % prov.standard_of_living
			"unemployment":
				sub_text = "Pengangguran: %s" % FormatUtils.format_percent(prov.unemployment_rate)
			"infra":
				sub_text = "Infra Lv.%d (Efisiensi %s)" % [prov.infrastructure_level, FormatUtils.format_percent(prov.get_infrastructure_efficiency())]
		
		draw_string(font, Vector2(box_rect.position.x + 6, box_rect.position.y + 34), sub_text, HORIZONTAL_ALIGNMENT_CENTER, box_w - 12, 11, Color("#c9d1d9"))
		
		# Baris 3: Spesialisasi Komoditas Unggulan Provinsi
		var spec_text: String = _get_province_specialty_summary(prov)
		draw_string(font, Vector2(box_rect.position.x + 6, box_rect.position.y + 48), spec_text, HORIZONTAL_ALIGNMENT_CENTER, box_w - 12, 10, Color("#8b949e"))

func _get_province_specialty_summary(prov: Province) -> String:
	var best_cid: String = "grain"
	var best_mult: float = 1.0
	for cid in prov.resource_multipliers.keys():
		var m: float = float(prov.resource_multipliers[cid])
		if m > best_mult:
			best_mult = m
			best_cid = cid
	var names: Dictionary = {
		"grain": "🌾 Pangan",
		"timber": "🪵 Kayu",
		"coal": "🪨 Batu Bara",
		"iron": "⛏️ Besi",
		"cloth": "👕 Tekstil",
		"tools": "⚙️ Mesin",
		"luxury": "💎 Rempah"
	}
	return "Unggulan: %s (x%.1f)" % [names.get(best_cid, best_cid), best_mult]
