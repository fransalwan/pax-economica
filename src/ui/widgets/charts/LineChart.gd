class_name LineChart
extends Control

var chart_title: String = "Indikator Makro"
var unit_suffix: String = ""
var series_data: Array[Dictionary] = [] # [{ "name": String, "values": Array[float], "color": Color }]

func _init(p_title: String = "Grafik Time-Series", p_unit: String = "") -> void:
	chart_title = p_title
	unit_suffix = p_unit
	custom_minimum_size = Vector2(360, 155)

func set_series(new_series: Array[Dictionary]) -> void:
	series_data = new_series
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("#0d1117"), true)
	draw_rect(rect, Color("#30363d"), false, 1.0)
	
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(10, 18), chart_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e6edf3"))
	
	var plot_left: float = 54.0
	var plot_right: float = size.x - 14.0
	var plot_top: float = 28.0
	var plot_bottom: float = size.y - 24.0
	var plot_w: float = maxf(10.0, plot_right - plot_left)
	var plot_h: float = maxf(10.0, plot_bottom - plot_top)
	
	# Cari rentang nilai min & max di seluruh seri
	var min_val: float = INF
	var max_val: float = -INF
	for s in series_data:
		var vals: Array = s.get("values", [])
		for v in vals:
			var fv: float = float(v)
			if fv < min_val:
				min_val = fv
			if fv > max_val:
				max_val = fv
	
	if min_val == INF or max_val == -INF:
		min_val = 0.0
		max_val = 100.0
	elif is_equal_approx(min_val, max_val):
		min_val -= 5.0
		max_val += 5.0
	else:
		var pad: float = (max_val - min_val) * 0.12
		min_val -= pad
		max_val += pad
	
	# Gambar garis grid horizontal & label sumbu Y
	for i in range(4):
		var ratio: float = float(i) / 3.0
		var y: float = lerpf(plot_bottom, plot_top, ratio)
		var val: float = lerpf(min_val, max_val, ratio)
		draw_line(Vector2(plot_left, y), Vector2(plot_right, y), Color(1, 1, 1, 0.07), 1.0)
		var lbl: String = _format_axis_val(val) + unit_suffix
		draw_string(font, Vector2(4, y + 4), lbl, HORIZONTAL_ALIGNMENT_LEFT, 48, 10, Color("#8b949e"))
	
	# Gambar masing-masing kurva data
	var legend_x: float = plot_left
	for s in series_data:
		var vals: Array = s.get("values", [])
		var col: Color = s.get("color", Color("#58a6ff"))
		var s_name: String = str(s.get("name", ""))
		
		if vals.size() >= 2:
			var pts := PackedVector2Array()
			var count: int = vals.size()
			for idx in range(count):
				var x: float = plot_left + (float(idx) / float(count - 1)) * plot_w
				var norm_y: float = (float(vals[idx]) - min_val) / maxf(0.0001, max_val - min_val)
				var y: float = lerpf(plot_bottom, plot_top, clampf(norm_y, 0.0, 1.0))
				pts.append(Vector2(x, y))
			draw_polyline(pts, col, 2.2, true)
			draw_circle(pts[pts.size() - 1], 3.5, col)
		
		# Legenda di bagian bawah grafik
		var latest_str: String = _format_axis_val(float(vals.back())) + unit_suffix if not vals.is_empty() else "-"
		draw_rect(Rect2(legend_x, size.y - 15, 8, 8), col, true)
		var leg_text: String = "%s: %s" % [s_name, latest_str]
		draw_string(font, Vector2(legend_x + 12, size.y - 7), leg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
		legend_x += float(leg_text.length() * 6 + 26)

func _format_axis_val(val: float) -> String:
	var a: float = absf(val)
	if a >= 1_000_000.0:
		return "%.1fM" % (val / 1_000_000.0)
	elif a >= 1_000.0:
		return "%.1fK" % (val / 1_000.0)
	return "%.1f" % val
