class_name MacroHUD
extends CanvasLayer

# Topbar labels
var lbl_date: Label
var lbl_gdp: Label
var lbl_inflation: Label
var lbl_rates: Label
var lbl_fiscal: Label
var lbl_fx_trade: Label
var lbl_toast: Label

# Left Province Inspector
var lbl_prov_title: Label
var lbl_prov_stats: Label
var btn_upgrade_infra: Button
var vbox_buildings: VBoxContainer

# Right Macro Tabs & Controls
var chart_gdp: LineChart
var chart_inflation: LineChart
var chart_debt: LineChart

var lbl_monetary_summary: Label
var slider_interest: HSlider
var lbl_interest_val: Label

var lbl_fiscal_summary: Label
var slider_income_tax: HSlider
var slider_corp_tax: HSlider
var slider_vat: HSlider
var slider_tariff: HSlider
var slider_subsidy: HSlider

var vbox_market_rows: VBoxContainer
var lbl_crisis_advice: RichTextLabel

func _ready() -> void:
	_build_ui()
	_refresh_all_ui()
	
	EventBus.tick_completed.connect(func(_y: int, _m: int): _refresh_all_ui())
	EventBus.province_selected.connect(func(_pid: int): _refresh_province_panel())
	EventBus.policy_updated.connect(func(_nid: String): _refresh_all_ui())
	EventBus.notification_posted.connect(_on_notification_posted)
	EventBus.macro_shock_triggered.connect(_on_macro_shock_triggered)

func _build_ui() -> void:
	# 1. TOP BAR (Indikator Makro Utama & Kontrol Kecepatan Waktu)
	var top_panel := PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.custom_minimum_size = Vector2(0, 54)
	add_child(top_panel)
	
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 18)
	top_panel.add_child(top_hbox)
	
	lbl_gdp = _create_top_metric(top_hbox, "PDB Nominal / Riil")
	lbl_inflation = _create_top_metric(top_hbox, "CPI & Inflasi")
	lbl_rates = _create_top_metric(top_hbox, "Suku Bunga & Yield")
	lbl_fiscal = _create_top_metric(top_hbox, "Kas & Utang Negara")
	lbl_fx_trade = _create_top_metric(top_hbox, "Kurs FX & Neraca")
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)
	
	lbl_date = Label.new()
	lbl_date.text = "Jan 1850"
	lbl_date.add_theme_font_size_override("font_size", 15)
	top_hbox.add_child(lbl_date)
	
	var btn_pause := Button.new()
	btn_pause.text = "⏸ Pause"
	btn_pause.pressed.connect(func(): SimulationClock.toggle_pause(); btn_pause.text = "▶ Play" if SimulationClock.is_paused else "⏸ Pause")
	top_hbox.add_child(btn_pause)
	
	for spd in [1, 2, 5]:
		var b := Button.new()
		b.text = "%dx" % spd
		b.pressed.connect(func(): SimulationClock.set_speed(spd); btn_pause.text = "⏸ Pause")
		top_hbox.add_child(b)
	
	var btn_save := Button.new()
	btn_save.text = "💾 Save"
	btn_save.pressed.connect(func(): SaveManager.save_game("autosave"))
	top_hbox.add_child(btn_save)
	
	var btn_load := Button.new()
	btn_load.text = "📂 Load"
	btn_load.pressed.connect(func(): SaveManager.load_game("autosave"))
	top_hbox.add_child(btn_load)
	
	# 2. LEFT PANEL (Inspektor Provinsi & Pembangunan Sisi Penawaran)
	var left_panel := PanelContainer.new()
	left_panel.position = Vector2(12, 66)
	left_panel.size = Vector2(330, 560)
	add_child(left_panel)
	
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_vbox)
	
	lbl_prov_title = Label.new()
	lbl_prov_title.add_theme_font_size_override("font_size", 16)
	lbl_prov_title.add_theme_color_override("font_color", Color("#d4af37"))
	left_vbox.add_child(lbl_prov_title)
	
	lbl_prov_stats = Label.new()
	lbl_prov_stats.add_theme_font_size_override("font_size", 12)
	left_vbox.add_child(lbl_prov_stats)
	
	btn_upgrade_infra = Button.new()
	btn_upgrade_infra.text = "🛤️ Tingkatkan Infrastruktur"
	btn_upgrade_infra.pressed.connect(func(): WorldEconomy.upgrade_province_infrastructure(WorldEconomy.selected_province_id))
	left_vbox.add_child(btn_upgrade_infra)
	
	var sep := HSeparator.new()
	left_vbox.add_child(sep)
	
	var lbl_b_header := Label.new()
	lbl_b_header.text = "Kapasitas Sektor Produksi (Supply-Side):"
	lbl_b_header.add_theme_font_size_override("font_size", 13)
	left_vbox.add_child(lbl_b_header)
	
	var scroll_b := ScrollContainer.new()
	scroll_b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(scroll_b)
	
	vbox_buildings = VBoxContainer.new()
	vbox_buildings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_b.add_child(vbox_buildings)
	
	# 3. RIGHT PANEL (Tab Analisa Makroekonomi, Bank Sentral, Fiskal, Pasar, & Lab Krisis)
	var right_tabs := TabContainer.new()
	right_tabs.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_tabs.position = Vector2(1920 - 470, 66)
	right_tabs.size = Vector2(458, 630)
	add_child(right_tabs)
	
	_build_tab_charts(right_tabs)
	_build_tab_central_bank(right_tabs)
	_build_tab_fiscal(right_tabs)
	_build_tab_market_ledger(right_tabs)
	_build_tab_crisis_lab(right_tabs)
	
	# 4. BOTTOM BAR (Pemilih Map Modes & Toast Notifikasi)
	var bottom_panel := PanelContainer.new()
	bottom_panel.position = Vector2(12, 638)
	bottom_panel.size = Vector2(760, 48)
	add_child(bottom_panel)
	
	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 8)
	bottom_panel.add_child(bottom_hbox)
	
	var lbl_mm := Label.new()
	lbl_mm.text = "🗺️ Map Mode:"
	bottom_hbox.add_child(lbl_mm)
	
	var modes: Array[Dictionary] = [
		{"id": "political", "label": "Politik"},
		{"id": "gdp", "label": "Heatmap PDB"},
		{"id": "sol", "label": "Kesejahteraan (SoL)"},
		{"id": "unemployment", "label": "Pengangguran"},
		{"id": "infra", "label": "Infrastruktur"}
	]
	for m in modes:
		var bm := Button.new()
		bm.text = str(m["label"])
		var mid: String = str(m["id"])
		bm.pressed.connect(func():
			WorldEconomy.current_map_mode = mid
			EventBus.map_mode_changed.emit(mid)
		)
		bottom_hbox.add_child(bm)
	
	lbl_toast = Label.new()
	lbl_toast.position = Vector2(360, 600)
	lbl_toast.add_theme_font_size_override("font_size", 14)
	lbl_toast.add_theme_color_override("font_color", Color("#f2cc60"))
	add_child(lbl_toast)

func _create_top_metric(parent: Container, title: String) -> Label:
	var vb := VBoxContainer.new()
	var t_lbl := Label.new()
	t_lbl.text = title
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", Color("#8b949e"))
	vb.add_child(t_lbl)
	
	var v_lbl := Label.new()
	v_lbl.add_theme_font_size_override("font_size", 13)
	vb.add_child(v_lbl)
	parent.add_child(vb)
	return v_lbl

func _build_tab_charts(tabs: TabContainer) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "📈 Grafik Makro"
	vbox.add_theme_constant_override("separation", 10)
	tabs.add_child(vbox)
	
	chart_gdp = LineChart.new("PDB Bulanan: Nominal vs Riil (Output Fisik)", "")
	vbox.add_child(chart_gdp)
	
	chart_inflation = LineChart.new("Laju Inflasi CPI (%) vs Suku Bunga Acuan (%)", "%")
	vbox.add_child(chart_inflation)
	
	chart_debt = LineChart.new("Rasio Utang/PDB (%) & Imbal Hasil Obligasi (%)", "%")
	vbox.add_child(chart_debt)

func _build_tab_central_bank(tabs: TabContainer) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "🏦 Bank Sentral"
	vbox.add_theme_constant_override("separation", 10)
	tabs.add_child(vbox)
	
	lbl_monetary_summary = Label.new()
	lbl_monetary_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_monetary_summary.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_monetary_summary)
	
	lbl_interest_val = Label.new()
	lbl_interest_val.text = "Suku Bunga Acuan (Policy Rate): 5.00%"
	vbox.add_child(lbl_interest_val)
	
	slider_interest = HSlider.new()
	slider_interest.min_value = 0.5
	slider_interest.max_value = 25.0
	slider_interest.step = 0.25
	slider_interest.value = 5.0
	slider_interest.value_changed.connect(func(v: float):
		var player: Nation = WorldEconomy.get_player_nation()
		if player:
			player.policy_interest_rate = v / 100.0
			lbl_interest_val.text = "Suku Bunga Acuan (Policy Rate): %.2f%%" % v
			EventBus.policy_updated.emit(player.id)
	)
	vbox.add_child(slider_interest)
	
	var hbox_qe := HBoxContainer.new()
	vbox.add_child(hbox_qe)
	
	var btn_qe := Button.new()
	btn_qe.text = "🖨️ Cetak Uang / QE (+25K)"
	btn_qe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_qe.pressed.connect(func():
		var player: Nation = WorldEconomy.get_player_nation()
		if player:
			player.print_money_qe(25_000.0)
			EventBus.notification_posted.emit("🖨️ Bank Sentral mencetak 25K uang baru ke Kas Negara (Awas Inflasi!)", "warning")
			EventBus.policy_updated.emit(player.id)
	)
	hbox_qe.add_child(btn_qe)
	
	var btn_qt := Button.new()
	btn_qt.text = "🔥 Serap Likuiditas / QT (-25K)"
	btn_qt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_qt.pressed.connect(func():
		var player: Nation = WorldEconomy.get_player_nation()
		if player:
			player.contract_money_supply(25_000.0)
			EventBus.notification_posted.emit("🔥 Bank Sentral menarik 25K uang beredar dari kas (Disinflasi)", "info")
			EventBus.policy_updated.emit(player.id)
	)
	hbox_qe.add_child(btn_qt)
	
	var theory_box := RichTextLabel.new()
	theory_box.bbcode_enabled = true
	theory_box.fit_content = true
	theory_box.text = "[b]Panduan Teori Moneter (MV = PY):[/b]\n• [color=#3fb950]Naikkan Suku Bunga:[/color] Menurunkan konsumsi rumah tangga & investasi swasta, memperlambat perputaran uang (V), meredam inflasi, dan menguatkan nilai tukar.\n• [color=#f2cc60]Turunkan Suku Bunga:[/color] Memacu kredit & investasi pabrik swasta, namun berisiko memicu Demand-Pull Inflation.\n• [color=#f85149]Cetak Uang (QE):[/color] Menambah kas negara secara instan tanpa utang, tetapi menaikkan rasio M/Y sehingga seluruh harga barang melonjak."
	vbox.add_child(theory_box)

func _build_tab_fiscal(tabs: TabContainer) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "⚖️ Fiskal & Utang"
	vbox.add_theme_constant_override("separation", 8)
	tabs.add_child(vbox)
	
	lbl_fiscal_summary = Label.new()
	lbl_fiscal_summary.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_fiscal_summary)
	
	slider_income_tax = _add_policy_slider(vbox, "Pajak Penghasilan (Income Tax)", 0.0, 45.0, 15.0, func(v: float):
		WorldEconomy.get_player_nation().income_tax_rate = v / 100.0
	)
	slider_corp_tax = _add_policy_slider(vbox, "Pajak Laba Industri (Corporate Tax)", 0.0, 50.0, 20.0, func(v: float):
		WorldEconomy.get_player_nation().corporate_tax_rate = v / 100.0
	)
	slider_vat = _add_policy_slider(vbox, "Pajak Konsumsi / PPN (VAT)", 0.0, 25.0, 8.0, func(v: float):
		WorldEconomy.get_player_nation().vat_rate = v / 100.0
	)
	slider_tariff = _add_policy_slider(vbox, "Bea Masuk / Tarif Impor", 0.0, 50.0, 10.0, func(v: float):
		WorldEconomy.get_player_nation().import_tariff_rate = v / 100.0
	)
	slider_subsidy = _add_policy_slider(vbox, "Subsidi Kesejahteraan Bulanan (Ribu)", 0.0, 25.0, 4.0, func(v: float):
		WorldEconomy.get_player_nation().monthly_subsidy_budget = v * 1000.0
	)
	
	var hbox_bonds := HBoxContainer.new()
	vbox.add_child(hbox_bonds)
	
	var btn_issue := Button.new()
	btn_issue.text = "📜 Terbitkan Obligasi (+30K)"
	btn_issue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_issue.pressed.connect(func():
		var p: Nation = WorldEconomy.get_player_nation()
		p.issue_bonds(30_000.0)
		EventBus.policy_updated.emit(p.id)
	)
	hbox_bonds.add_child(btn_issue)
	
	var btn_repay := Button.new()
	btn_repay.text = "💸 Lunasi Utang (-30K)"
	btn_repay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_repay.pressed.connect(func():
		var p: Nation = WorldEconomy.get_player_nation()
		p.repay_debt(30_000.0)
		EventBus.policy_updated.emit(p.id)
	)
	hbox_bonds.add_child(btn_repay)

func _add_policy_slider(parent: Container, label_title: String, min_v: float, max_v: float, init_v: float, callback: Callable) -> HSlider:
	var lbl := Label.new()
	lbl.text = "%s: %.1f%%" % [label_title, init_v]
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)
	
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = 1.0
	s.value = init_v
	s.value_changed.connect(func(val: float):
		lbl.text = "%s: %.1f" % [label_title, val]
		callback.call(val)
		EventBus.policy_updated.emit(WorldEconomy.player_nation_id)
	)
	parent.add_child(s)
	return s

func _build_tab_market_ledger(tabs: TabContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "📦 Pasar & Global"
	tabs.add_child(scroll)
	
	vbox_market_rows = VBoxContainer.new()
	vbox_market_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_market_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox_market_rows)

func _build_tab_crisis_lab(tabs: TabContainer) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "⚡ Lab Krisis"
	vbox.add_theme_constant_override("separation", 10)
	tabs.add_child(vbox)
	
	var intro := Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "Uji kemampuan analisis makroekonomimu dengan memicu guncangan ekonomi nyata (Macroeconomic Shocks) dan stabilkan kembali peradabanmu:"
	intro.add_theme_font_size_override("font_size", 12)
	vbox.add_child(intro)
	
	var scenarios: Array[Dictionary] = [
		{"id": "stagflation", "title": "🔥 Picu Supply-Side Stagflation Shock (Gagal Panen & Krisis Energi)"},
		{"id": "dutch_disease", "title": "💎 Picu Dutch Disease (Boom Komoditas & Penguatan Kurs Ekstrem)"},
		{"id": "debt_spiral", "title": "📉 Picu Sovereign Debt Crisis (Lonjakan Rasio Utang & Bond Yield)"}
	]
	for sc in scenarios:
		var b := Button.new()
		b.text = str(sc["title"])
		var sid: String = str(sc["id"])
		b.pressed.connect(func(): WorldEconomy.trigger_crisis_scenario(sid))
		vbox.add_child(b)
	
	lbl_crisis_advice = RichTextLabel.new()
	lbl_crisis_advice.bbcode_enabled = true
	lbl_crisis_advice.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_crisis_advice.text = "[b]Diagnosis & Catatan Ekonom:[/b]\nPilih salah satu skenario krisis di atas atau amati dinamika pasar secara organik."
	vbox.add_child(lbl_crisis_advice)

func _refresh_all_ui() -> void:
	var player: Nation = WorldEconomy.get_player_nation()
	if player == null:
		return
	
	lbl_date.text = "📅 " + FormatUtils.format_date(SimulationClock.current_year, SimulationClock.current_month)
	
	# Update Topbar
	var annual_nom_gdp: float = player.nominal_gdp * 12.0
	lbl_gdp.text = "%s (Riil %s)" % [
		FormatUtils.format_currency(annual_nom_gdp, player.currency_code + " "),
		FormatUtils.format_percent(player.real_gdp_growth_rate, true)
	]
	lbl_inflation.text = "CPI %.1f (%s)" % [
		player.cpi_index,
		FormatUtils.format_percent(player.inflation_rate, true)
	]
	lbl_rates.text = "BI/Acuan %s | Yield %s" % [
		FormatUtils.format_percent(player.policy_interest_rate),
		FormatUtils.format_percent(player.bond_yield)
	]
	lbl_fiscal.text = "Kas %s | Utang %s (%s PDB)" % [
		FormatUtils.format_currency(player.treasury_cash, ""),
		FormatUtils.format_currency(player.national_debt, ""),
		FormatUtils.format_percent(player.get_debt_to_gdp_ratio())
	]
	lbl_fx_trade.text = "Kurs %.2f | NX %s/bln" % [
		player.fx_rate_to_base,
		FormatUtils.format_currency(player.net_exports_nx, "")
	]
	
	# Update Charts
	chart_gdp.set_series([
		{"name": "PDB Nominal", "values": player.history_nominal_gdp, "color": Color("#58a6ff")},
		{"name": "PDB Riil", "values": player.history_real_gdp, "color": Color("#3fb950")}
	])
	chart_inflation.set_series([
		{"name": "Inflasi YoY", "values": player.history_inflation, "color": Color("#f85149")},
		{"name": "Suku Bunga", "values": player.history_interest_rate, "color": Color("#d29922")}
	])
	chart_debt.set_series([
		{"name": "Utang/PDB", "values": player.history_debt_to_gdp, "color": Color("#a371f7")},
		{"name": "Bond Yield", "values": player.history_bond_yield, "color": Color("#f778ba")}
	])
	
	# Update Monetary Summary
	lbl_monetary_summary.text = (
		"Jumlah Uang Beredar (M): %s\n" % FormatUtils.format_currency(player.money_supply, player.currency_code + " ") +
		"Perputaran Uang (Velocity V): %.2f\n" % player.velocity_of_money +
		"Pengali Harga Moneter (M*V / Y_real): %.2fx\n" % player.get_monetary_multiplier() +
		"Pengangguran Nasional: %s | Kesejahteraan Rata-rata: %.1f" % [
			FormatUtils.format_percent(player.avg_unemployment_rate),
			player.avg_standard_of_living
		]
	)
	
	# Update Fiscal Summary
	lbl_fiscal_summary.text = (
		"Penerimaan Pajak + Tarif Bulanan: %s\n" % FormatUtils.format_currency(player.last_tax_revenue + player.last_tariff_revenue, "") +
		"Belanja Negara (G) + Bunga Obligasi: %s (Bunga: %s)\n" % [
			FormatUtils.format_currency(player.gov_spending_g + player.last_bond_interest_expense, ""),
			FormatUtils.format_currency(player.last_bond_interest_expense, "")
		] +
		"Surplus / Defisit Bulanan: %s\n" % FormatUtils.format_currency(player.last_fiscal_balance, "") +
		"Komponen PDB: C=%s | I=%s | G=%s | NX=%s" % [
			FormatUtils.format_currency(player.consumption_c, ""),
			FormatUtils.format_currency(player.investment_i, ""),
			FormatUtils.format_currency(player.gov_spending_g, ""),
			FormatUtils.format_currency(player.net_exports_nx, "")
		]
	)
	
	_refresh_province_panel()
	_refresh_market_ledger()

func _refresh_province_panel() -> void:
	var prov: Province = WorldEconomy.get_province(WorldEconomy.selected_province_id)
	if prov == null:
		return
	var owner_nat: Nation = WorldEconomy.nations.get(prov.owner_nation_id)
	var is_owned_by_player: bool = (prov.owner_nation_id == WorldEconomy.player_nation_id)
	
	lbl_prov_title.text = "📍 %s (%s)" % [prov.name, owner_nat.name if owner_nat else ""]
	lbl_prov_stats.text = (
		"Tipe Wilayah: %s\n" % prov.terrain_type +
		"Populasi: %s (Pengangguran: %s)\n" % [FormatUtils.format_population(prov.population), FormatUtils.format_percent(prov.unemployment_rate)] +
		"Standard of Living (SoL): %.1f / 100\n" % prov.standard_of_living +
		"PDB Provinsi: %s/bln (Riil: %s)\n" % [FormatUtils.format_currency(prov.local_nominal_gdp, ""), FormatUtils.format_currency(prov.local_real_gdp, "")] +
		"Tabungan Rumah Tangga: %s | Modal Swasta: %s\n" % [FormatUtils.format_currency(prov.household_savings, ""), FormatUtils.format_currency(prov.capitalist_capital_pool, "")] +
		"Infrastruktur: Lv.%d (Efisiensi Logistik: %s)" % [prov.infrastructure_level, FormatUtils.format_percent(prov.get_infrastructure_efficiency())]
	)
	
	var infra_cost: float = 15_000.0 * float(prov.infrastructure_level)
	btn_upgrade_infra.disabled = not is_owned_by_player or prov.infrastructure_level >= 10
	btn_upgrade_infra.text = "🛤️ Upgrade Infrastruktur ke Lv.%d (%s)" % [prov.infrastructure_level + 1, FormatUtils.format_currency(infra_cost, "")]
	
	for child in vbox_buildings.get_children():
		child.queue_free()
	
	for cid in WorldEconomy.commodity_catalog.keys():
		var cdata: CommodityData = WorldEconomy.commodity_catalog[cid]
		var lvl: int = int(prov.buildings.get(cid, 1))
		var mult: float = float(prov.resource_multipliers.get(cid, 1.0))
		var out_qty: float = float(prov.last_production_volume.get(cid, 0.0))
		var cost: float = 12_000.0 * float(lvl)
		
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.text = "%s (Lv.%d | x%.1f)\nOutput: %.1f unit" % [cdata.display_name, lvl, mult, out_qty]
		row.add_child(lbl)
		
		var btn := Button.new()
		btn.text = "+Lv (%s)" % FormatUtils.format_currency(cost, "")
		btn.disabled = not is_owned_by_player
		var cap_cid: String = cid
		btn.pressed.connect(func(): WorldEconomy.upgrade_province_building(prov.id, cap_cid))
		row.add_child(btn)
		
		vbox_buildings.add_child(row)

func _refresh_market_ledger() -> void:
	for child in vbox_market_rows.get_children():
		child.queue_free()
	
	var player: Nation = WorldEconomy.get_player_nation()
	if player == null:
		return
	
	var hdr := Label.new()
	hdr.text = "📊 Pasar Komoditas Domestik (%s)" % player.name
	hdr.add_theme_color_override("font_color", Color("#d4af37"))
	vbox_market_rows.add_child(hdr)
	
	for cid in WorldEconomy.commodity_catalog.keys():
		var cdata: CommodityData = WorldEconomy.commodity_catalog[cid]
		var price: float = float(player.market.prices[cid])
		var s: float = float(player.market.supply[cid])
		var d: float = float(player.market.demand[cid])
		var nx: float = float(player.market.net_trade_volume[cid])
		var ratio_pct: float = ((price - cdata.base_price) / cdata.base_price)
		
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.text = "• %s | Harga: %.1f (%s vs Base %.0f)\n   Supply: %.1f | Demand: %.1f | Net Ekspor: %+.1f" % [
			cdata.display_name, price, FormatUtils.format_percent(ratio_pct, true), cdata.base_price, s, d, nx
		]
		vbox_market_rows.add_child(lbl)
	
	var sep := HSeparator.new()
	vbox_market_rows.add_child(sep)
	
	var hdr_global := Label.new()
	hdr_global.text = "🌍 Perbandingan Makro Antar-Kekaisaran"
	hdr_global.add_theme_color_override("font_color", Color("#58a6ff"))
	vbox_market_rows.add_child(hdr_global)
	
	for nid in WorldEconomy.nations.keys():
		var nat: Nation = WorldEconomy.nations[nid]
		var n_lbl := Label.new()
		n_lbl.add_theme_font_size_override("font_size", 11)
		n_lbl.text = "🏛️ %s (%s) — PDB/thn: %s | Inflasi: %s | Kurs: %.2f | Bunga: %s" % [
			nat.name,
			nat.currency_code,
			FormatUtils.format_currency(nat.nominal_gdp * 12.0, ""),
			FormatUtils.format_percent(nat.inflation_rate, true),
			nat.fx_rate_to_base,
			FormatUtils.format_percent(nat.policy_interest_rate)
		]
		vbox_market_rows.add_child(n_lbl)

func _on_notification_posted(message: String, _severity: String) -> void:
	lbl_toast.text = message

func _on_macro_shock_triggered(title: String, description: String, advice: String) -> void:
	lbl_toast.text = title
	if lbl_crisis_advice:
		lbl_crisis_advice.text = "[b][color=#f85149]%s[/color][/b]\n%s\n\n[b][color=#3fb950]%s[/color][/b]" % [title, description, advice]

