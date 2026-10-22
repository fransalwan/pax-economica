extends Node

var commodity_catalog: Dictionary = {}
var nations: Dictionary = {}       # nation_id -> Nation
var provinces: Dictionary = {}     # province_id -> Province
var color_to_province_id: Dictionary = {} # Color.to_html(false) -> int
var player_nation_id: String = "nusantara"
var selected_province_id: int = 1
var current_map_mode: String = "political" # political, gdp, inflation, sol, infra

func _ready() -> void:
	commodity_catalog = CommodityData.create_default_catalog()
	_setup_initial_world()
	# Jalankan 6 bulan pemanasan awal agar grafik time-series langsung terisi saat game dimulai
	for _i in range(6):
		process_monthly_tick(1850, 1)

func get_player_nation() -> Nation:
	return nations.get(player_nation_id)

func get_province(prov_id: int) -> Province:
	return provinces.get(prov_id)

func _setup_initial_world() -> void:
	nations.clear()
	provinces.clear()
	color_to_province_id.clear()
	
	# 1. Buat 3 Kekaisaran dengan Karakteristik Makro Berbeda
	var nusantara := Nation.new("nusantara", "Kekaisaran Nusantara", "NRP", Color("#2ea043"), commodity_catalog, true)
	var mercia := Nation.new("mercia", "Persemakmuran Mercia", "MRC", Color("#388bfd"), commodity_catalog, false)
	var borealis := Nation.new("borealis", "Imperium Borealis", "BRL", Color("#d29922"), commodity_catalog, false)
	
	mercia.technology_multiplier = 1.28
	mercia.policy_interest_rate = 0.04
	borealis.technology_multiplier = 1.10
	borealis.policy_interest_rate = 0.06
	
	nations["nusantara"] = nusantara
	nations["mercia"] = mercia
	nations["borealis"] = borealis
	
	# 2. Buat 12 Provinsi di Peta beserta Geometri Poligon & Spesialisasi Ekonomi
	var prov_defs: Array[Dictionary] = [
		# Provinsi Kekaisaran Nusantara (Player - 6 Provinsi)
		{
			"id": 1, "name": "Sunda Kalapa (Ibu Kota)", "owner": "nusantara",
			"color": Color8(220, 40, 40), "terrain": "Pelabuhan Metropolitan", "pop": 240_000, "infra": 4,
			"rect": Rect2(140, 290, 210, 145),
			"buildings": {"grain": 2, "timber": 1, "coal": 1, "iron": 1, "cloth": 3, "tools": 2, "luxury": 2},
			"mults": {"cloth": 1.3, "tools": 1.2, "luxury": 1.4}
		},
		{
			"id": 2, "name": "Priangan Tengah", "owner": "nusantara",
			"color": Color8(40, 200, 40), "terrain": "Dataran Tinggi Subur", "pop": 195_000, "infra": 3,
			"rect": Rect2(360, 310, 200, 150),
			"buildings": {"grain": 4, "timber": 2, "coal": 1, "iron": 1, "cloth": 2, "tools": 1, "luxury": 2},
			"mults": {"grain": 1.6, "luxury": 1.5}
		},
		{
			"id": 3, "name": "Swarnadwipa Hulu", "owner": "nusantara",
			"color": Color8(40, 40, 220), "terrain": "Hutan Tropis & Tambang", "pop": 150_000, "infra": 2,
			"rect": Rect2(110, 120, 230, 155),
			"buildings": {"grain": 2, "timber": 4, "coal": 3, "iron": 2, "cloth": 1, "tools": 1, "luxury": 1},
			"mults": {"timber": 1.7, "coal": 1.6, "iron": 1.3}
		},
		{
			"id": 4, "name": "Mataram Hilir", "owner": "nusantara",
			"color": Color8(220, 200, 40), "terrain": "Lumbung Padi Aluvial", "pop": 220_000, "infra": 3,
			"rect": Rect2(570, 330, 210, 145),
			"buildings": {"grain": 5, "timber": 2, "coal": 1, "iron": 1, "cloth": 2, "tools": 1, "luxury": 1},
			"mults": {"grain": 1.8, "cloth": 1.2}
		},
		{
			"id": 5, "name": "Tanjung Tembaga", "owner": "nusantara",
			"color": Color8(200, 40, 200), "terrain": "Pegunungan Mineral", "pop": 135_000, "infra": 2,
			"rect": Rect2(355, 130, 205, 165),
			"buildings": {"grain": 1, "timber": 2, "coal": 3, "iron": 4, "cloth": 1, "tools": 2, "luxury": 1},
			"mults": {"iron": 1.75, "coal": 1.5, "tools": 1.25}
		},
		{
			"id": 6, "name": "Bandar Maluku", "owner": "nusantara",
			"color": Color8(40, 210, 210), "terrain": "Kepulauan Rempah", "pop": 125_000, "infra": 3,
			"rect": Rect2(790, 300, 195, 165),
			"buildings": {"grain": 2, "timber": 2, "coal": 1, "iron": 1, "cloth": 1, "tools": 1, "luxury": 4},
			"mults": {"luxury": 2.0, "grain": 1.2}
		},
		# Provinsi Persemakmuran Mercia (AI Industri - 3 Provinsi)
		{
			"id": 7, "name": "New Albion", "owner": "mercia",
			"color": Color8(255, 128, 40), "terrain": "Kawasan Industri Berat", "pop": 260_000, "infra": 5,
			"rect": Rect2(575, 95, 215, 175),
			"buildings": {"grain": 1, "timber": 1, "coal": 3, "iron": 3, "cloth": 4, "tools": 5, "luxury": 2},
			"mults": {"tools": 1.7, "cloth": 1.5}
		},
		{
			"id": 8, "name": "Lancaster Bay", "owner": "mercia",
			"color": Color8(128, 255, 40), "terrain": "Dermaga Niaga", "pop": 180_000, "infra": 4,
			"rect": Rect2(805, 100, 205, 175),
			"buildings": {"grain": 2, "timber": 2, "coal": 2, "iron": 2, "cloth": 4, "tools": 3, "luxury": 2},
			"mults": {"cloth": 1.6, "tools": 1.4}
		},
		{
			"id": 9, "name": "Westmoreland", "owner": "mercia",
			"color": Color8(128, 40, 255), "terrain": "Lembah Batu Bara", "pop": 165_000, "infra": 4,
			"rect": Rect2(1025, 115, 195, 170),
			"buildings": {"grain": 2, "timber": 2, "coal": 5, "iron": 3, "cloth": 2, "tools": 3, "luxury": 1},
			"mults": {"coal": 1.8, "iron": 1.4}
		},
		# Provinsi Imperium Borealis (AI Agraris & Tambang - 3 Provinsi)
		{
			"id": 10, "name": "Valhalla Frost", "owner": "borealis",
			"color": Color8(255, 60, 140), "terrain": "Taiga & Hutan Utara", "pop": 145_000, "infra": 2,
			"rect": Rect2(160, 465, 255, 150),
			"buildings": {"grain": 2, "timber": 5, "coal": 2, "iron": 3, "cloth": 1, "tools": 1, "luxury": 1},
			"mults": {"timber": 1.9, "iron": 1.5}
		},
		{
			"id": 11, "name": "Krakowia Steppes", "owner": "borealis",
			"color": Color8(60, 140, 255), "terrain": "Stepa Gandum Luas", "pop": 210_000, "infra": 3,
			"rect": Rect2(435, 485, 270, 145),
			"buildings": {"grain": 6, "timber": 2, "coal": 2, "iron": 1, "cloth": 2, "tools": 1, "luxury": 1},
			"mults": {"grain": 1.85}
		},
		{
			"id": 12, "name": "Ironforge Citadel", "owner": "borealis",
			"color": Color8(140, 220, 120), "terrain": "Kawah Besi Kuno", "pop": 170_000, "infra": 3,
			"rect": Rect2(725, 485, 260, 145),
			"buildings": {"grain": 1, "timber": 2, "coal": 4, "iron": 5, "cloth": 1, "tools": 2, "luxury": 1},
			"mults": {"iron": 1.9, "coal": 1.6}
		}
	]
	
	for pdef in prov_defs:
		var pid: int = int(pdef["id"])
		var owner_id: String = str(pdef["owner"])
		var col: Color = pdef["color"]
		var prov := Province.new(pid, str(pdef["name"]), owner_id, col, str(pdef["terrain"]))
		prov.population = int(pdef["pop"])
		prov.infrastructure_level = int(pdef["infra"])
		
		var r: Rect2 = pdef["rect"]
		prov.polygon_points = _create_beveled_rect_polygon(r)
		prov.center_pos = r.get_center()
		
		var b_dict: Dictionary = pdef["buildings"]
		for cid in b_dict.keys():
			prov.buildings[cid] = int(b_dict[cid])
			
		var m_dict: Dictionary = pdef["mults"]
		for cid in m_dict.keys():
			prov.resource_multipliers[cid] = float(m_dict[cid])
			
		provinces[pid] = prov
		color_to_province_id[col.to_html(false)] = pid
		(nations[owner_id] as Nation).provinces.append(prov)

func _create_beveled_rect_polygon(r: Rect2) -> PackedVector2Array:
	var b: float = 16.0
	return PackedVector2Array([
		Vector2(r.position.x + b, r.position.y),
		Vector2(r.end.x - b, r.position.y),
		Vector2(r.end.x, r.position.y + b),
		Vector2(r.end.x, r.end.y - b),
		Vector2(r.end.x - b, r.end.y),
		Vector2(r.position.x + b, r.end.y),
		Vector2(r.position.x, r.end.y - b),
		Vector2(r.position.x, r.position.y + b)
	])

## Siklus Simulasi Makroekonomi Bulanan (Seluruh Negara + Perdagangan Internasional)
func process_monthly_tick(year: int, _month: int) -> void:
	# 1. Simulasi Domestik tiap Negara
	for nid in nations.keys():
		var nat: Nation = nations[nid]
		nat.simulate_domestic_economy()
	
	# 2. Perdagangan Internasional & Arbitrase Keunggulan Komparatif
	_process_international_trade_and_fx()
	
	# 3. Penyelesaian Harga Pasar, GDP, CPI, Obligasi, dan Indikator
	for nid in nations.keys():
		var nat: Nation = nations[nid]
		nat.finalize_monthly_accounting()
		if not nat.is_player:
			_run_ai_central_bank_policy(nat)
	
	# 4. Cek Achievement & Rich Presence untuk Negara Pemain
	var player: Nation = get_player_nation()
	if player:
		SteamManager.update_rich_presence(
			player.name,
			year,
			FormatUtils.format_currency(player.nominal_gdp * 12.0, player.currency_code + " "),
			FormatUtils.format_percent(player.inflation_rate, true)
		)
		_check_macro_achievements(player)

func _process_international_trade_and_fx() -> void:
	for nid in nations.keys():
		var nat: Nation = nations[nid]
		nat.exports_x = 0.0
		nat.imports_m = 0.0
		nat.last_tariff_revenue = 0.0
	
	var nation_list: Array = nations.values()
	for cid in commodity_catalog.keys():
		for i in range(nation_list.size()):
			for j in range(i + 1, nation_list.size()):
				var nat_a: Nation = nation_list[i]
				var nat_b: Nation = nation_list[j]
				
				# Konversi harga ke nilai tukar dasar untuk membandingkan daya saing
				var price_a_global: float = float(nat_a.market.prices[cid]) * nat_a.fx_rate_to_base
				var price_b_global: float = float(nat_b.market.prices[cid]) * nat_b.fx_rate_to_base
				
				if absf(price_a_global - price_b_global) < 1.5:
					continue
				
				var exporter: Nation = nat_a if price_a_global < price_b_global else nat_b
				var importer: Nation = nat_b if price_a_global < price_b_global else nat_a
				
				var exp_price_global: float = minf(price_a_global, price_b_global)
				var imp_price_global: float = maxf(price_a_global, price_b_global)
				
				var price_after_tariff: float = exp_price_global * (1.0 + importer.import_tariff_rate)
				if imp_price_global <= price_after_tariff:
					continue
				
				var trade_qty: float = clampf((imp_price_global - price_after_tariff) * 1.8, 1.0, exporter.market.supply[cid] * 0.18)
				exporter.market.net_trade_volume[cid] += trade_qty
				importer.market.net_trade_volume[cid] -= trade_qty
				
				var export_val_local: float = trade_qty * float(exporter.market.prices[cid])
				var import_val_local: float = trade_qty * (exp_price_global / maxf(0.1, importer.fx_rate_to_base))
				var tariff_collected: float = import_val_local * importer.import_tariff_rate
				
				exporter.exports_x += export_val_local
				importer.imports_m += import_val_local
				importer.last_tariff_revenue += tariff_collected
	
	# Update Nilai Tukar Mata Uang (Floating FX Rate) berdasarkan Neraca Dagang, Suku Bunga, & Inflasi
	for nid in nations.keys():
		var nat: Nation = nations[nid]
		var nx_ratio: float = (nat.exports_x - nat.imports_m) / maxf(10_000.0, nat.nominal_gdp)
		var interest_diff: float = nat.policy_interest_rate - 0.05
		var inflation_drag: float = nat.inflation_rate - 0.02
		var fx_delta: float = (nx_ratio * 0.08) + (interest_diff * 0.15) - (inflation_drag * 0.12)
		nat.fx_rate_to_base = clampf(nat.fx_rate_to_base * (1.0 + fx_delta), 0.30, 3.00)

func _run_ai_central_bank_policy(ai_nation: Nation) -> void:
	# Taylor Rule sederhana untuk Bank Sentral AI
	var target_inflation: float = 0.02
	var inflation_gap: float = ai_nation.inflation_rate - target_inflation
	var desired_rate: float = clampf(0.04 + 1.2 * inflation_gap, 0.01, 0.18)
	ai_nation.policy_interest_rate = lerpf(ai_nation.policy_interest_rate, desired_rate, 0.25)

func _check_macro_achievements(player: Nation) -> void:
	if player.real_gdp > 260_000.0:
		SteamManager.unlock_achievement("INDUSTRIAL_TITAN")
	if player.national_debt <= 100.0 and player.history_nominal_gdp.size() > 12:
		SteamManager.unlock_achievement("SOVEREIGN_DEBT_FREE")
	if player.avg_standard_of_living >= 75.0:
		SteamManager.unlock_achievement("WELFARE_SUPERPOWER")

# --- Tindakan Intervensi Pembangunan Provinsi (Fiskal & Konstruksi) ---
func upgrade_province_building(prov_id: int, commodity_id: String) -> bool:
	var prov: Province = get_province(prov_id)
	var player: Nation = get_player_nation()
	if prov == null or player == null or prov.owner_nation_id != player.id:
		return false
	
	var current_lvl: int = int(prov.buildings.get(commodity_id, 1))
	var cost: float = 12_000.0 * float(current_lvl)
	if player.treasury_cash < cost:
		EventBus.notification_posted.emit("Kas Negara tidak cukup! Butuh %s" % FormatUtils.format_currency(cost, player.currency_code + " "), "warning")
		return false
	
	player.treasury_cash -= cost
	player.gov_spending_g += cost
	prov.buildings[commodity_id] = current_lvl + 1
	EventBus.policy_updated.emit(player.id)
	EventBus.notification_posted.emit("🏭 Level produksi %s di %s naik ke Lv.%d" % [commodity_id.capitalize(), prov.name, current_lvl + 1], "success")
	return true

func upgrade_province_infrastructure(prov_id: int) -> bool:
	var prov: Province = get_province(prov_id)
	var player: Nation = get_player_nation()
	if prov == null or player == null or prov.owner_nation_id != player.id:
		return false
	if prov.infrastructure_level >= 10:
		return false
	
	var cost: float = 15_000.0 * float(prov.infrastructure_level)
	if player.treasury_cash < cost:
		EventBus.notification_posted.emit("Kas Negara tidak cukup untuk infrastruktur! Butuh %s" % FormatUtils.format_currency(cost, player.currency_code + " "), "warning")
		return false
	
	player.treasury_cash -= cost
	player.gov_spending_g += cost
	prov.infrastructure_level += 1
	EventBus.policy_updated.emit(player.id)
	EventBus.notification_posted.emit("🛤️ Infrastruktur %s ditingkatkan ke Lv.%d" % [prov.name, prov.infrastructure_level], "success")
	return true

# --- Skenario Latihan Krisis Makroekonomi (Macro Shocks) ---
func trigger_crisis_scenario(scenario_id: String) -> void:
	var player: Nation = get_player_nation()
	if player == null:
		return
	
	match scenario_id:
		"stagflation":
			for prov in player.provinces:
				prov.supply_shock_modifier = 0.52 # Supply shock produksi anjlok 48%
			player.money_supply *= 1.25
			EventBus.macro_shock_triggered.emit(
				"⚠️ KRISIS: Supply-Side Stagflation Shock!",
				"Bencana iklim & kemacetan energi memotong output produksi provinsi sebesar 48% sementara uang beredar berlebih.",
				"Analisa: Jika kamu mencetak uang, hiperinflasi akan meledak. Jika suku bunga dinaikkan terlalu ekstrem, investasi mati. Tingkatkan Infrastruktur & kapasitas produksi Pangan/Energi sambil menjaga suku bunga moderat!"
			)
		"dutch_disease":
			player.fx_rate_to_base = 1.85 # Mata uang menguat tajam
			player.treasury_cash += 65_000.0
			player.money_supply *= 1.30
			EventBus.macro_shock_triggered.emit(
				"⚠️ KRISIS: Dutch Disease (Kutukan Sumber Daya Alam)!",
				"Penemuan tambang emas & rempah raksasa membuat mata uang NRP menguat tajam (+85%). Barang impor membanjiri pasar domestik dan memukul industri lokal!",
				"Analisa: Perhatikan Neraca Dagang (NX) yang berbalik defisit. Gunakan surplus kas untuk membangun efisiensi manufaktur (Tools/Cloth), pasang Tarif Impor terukur, atau turunkan Suku Bunga untuk meredam apresiasi mata uang."
			)
		"debt_spiral":
			player.national_debt = player.nominal_gdp * 12.0 * 1.15 # 115% Debt-to-GDP
			player.bond_yield = 0.19
			EventBus.macro_shock_triggered.emit(
				"⚠️ KRISIS: Sovereign Debt Spiral!",
				"Rasio Utang terhadap PDB menembus 115%! Investor obligasi panik sehingga Bond Yield melonjak ke 19% per tahun.",
				"Analisa: Beban bunga utang bulanan memakan anggaran negara. Lakukan konsolidasi fiskal (Fiscal Austerity / reformasi pajak) dan lunasi pokok utang sebelum negara gagal bayar!"
			)
	
	process_monthly_tick(SimulationClock.current_year, SimulationClock.current_month)
	EventBus.tick_completed.emit(SimulationClock.current_year, SimulationClock.current_month)

func serialize_state() -> Dictionary:
	var player: Nation = get_player_nation()
	return {
		"policy_interest_rate": player.policy_interest_rate,
		"money_supply": player.money_supply,
		"treasury_cash": player.treasury_cash,
		"national_debt": player.national_debt,
		"income_tax_rate": player.income_tax_rate,
		"corporate_tax_rate": player.corporate_tax_rate,
		"vat_rate": player.vat_rate,
		"import_tariff_rate": player.import_tariff_rate
	}

func deserialize_state(data: Dictionary) -> void:
	var player: Nation = get_player_nation()
	if player == null:
		return
	player.policy_interest_rate = float(data.get("policy_interest_rate", 0.05))
	player.money_supply = float(data.get("money_supply", 250_000.0))
	player.treasury_cash = float(data.get("treasury_cash", 85_000.0))
	player.national_debt = float(data.get("national_debt", 40_000.0))
	player.income_tax_rate = float(data.get("income_tax_rate", 0.15))
	player.corporate_tax_rate = float(data.get("corporate_tax_rate", 0.20))
	player.vat_rate = float(data.get("vat_rate", 0.08))
	player.import_tariff_rate = float(data.get("import_tariff_rate", 0.10))

