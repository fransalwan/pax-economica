class_name CommodityData
extends RefCounted

var id: String
var display_name: String
var base_price: float
var cpi_weight: float
var is_essential: bool
var color: Color

func _init(
	p_id: String,
	p_name: String,
	p_base_price: float,
	p_cpi_weight: float,
	p_is_essential: bool = false,
	p_color: Color = Color.WHITE
) -> void:
	id = p_id
	display_name = p_name
	base_price = p_base_price
	cpi_weight = p_cpi_weight
	is_essential = p_is_essential
	color = p_color

static func create_default_catalog() -> Dictionary:
	return {
		"grain": CommodityData.new("grain", "Pangan (Gandum & Beras)", 10.0, 0.40, true, Color("#f2cc60")),
		"timber": CommodityData.new("timber", "Kayu & Material", 15.0, 0.15, true, Color("#a371f7")),
		"coal": CommodityData.new("coal", "Batu Bara (Energi)", 22.0, 0.15, true, Color("#8b949e")),
		"iron": CommodityData.new("iron", "Bijih Besi & Baja", 30.0, 0.05, false, Color("#58a6ff")),
		"cloth": CommodityData.new("cloth", "Tekstil & Pakaian", 25.0, 0.15, true, Color("#3fb950")),
		"tools": CommodityData.new("tools", "Mesin & Alat Kerja", 45.0, 0.05, false, Color("#d29922")),
		"luxury": CommodityData.new("luxury", "Barang Mewah & Rempah", 80.0, 0.05, false, Color("#f778ba"))
	}

