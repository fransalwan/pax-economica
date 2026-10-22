class_name MacroHUD
extends CanvasLayer

# Topbar labels
var lbl_date: Label
var lbl_gdp: Label
var lbl_inflation: Label
var lbl_rates: Label
var lbl_fiscal: Label
var lbl_fx_trade: Label
var btn_pause: Button

# Guided Demo & Macro Advisor Banner (Top-Center)
var advisor_panel: PanelContainer
var lbl_diagnosis_status: Label
var lbl_diagnosis_summary: Label
var lbl_demo_step_title: Label
var lbl_demo_step_desc: Label
var btn_demo_action: Button
var current_demo_step: int = 0

# Left Province Inspector
var opt_province_selector: OptionButton
var lbl_ownership_badge: Label
var btn_jump_capital: Button
var lbl_prov_title: Label
var lbl_prov_stats: Label
var btn_upgrade_infra: Button
var vbox_buildings: VBoxContainer

# Right Macro Tabs & Controls
var right_tabs: TabContainer
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
var lbl_toast: Label

const DEMO_STEPS: Array[Dictionary] = [
	{
		"title": "🎓 Demo 1/4: Ekspansi Produksi Riil (Supply-Side)",
		"desc": "Provinsi berwarna HIJAU adalah wilayah Kekaisaran Nusantara milikmu. Meningkatkan Infrastruktur & Level Pabrik akan menaikkan PDB Riil (kurva hijau) dan menambah pasokan barang.",
		"btn": "⚡ Demo Otomatis: Upgrade Infrastruktur & Pabrik di Sunda Kalapa"
	},
	{
		"title": "🎓 Demo 2/4: Eksperimen Cetak Uang (MV = PY)",
		"desc": "Apa jadinya jika Bank Sentral mencetak uang (Quantitative Easing) tanpa diimbangi kenaikan produksi barang? Jumlah uang beredar (M) melonjak dan memicu Inflasi CPI (kurva merah)!",
		"btn": "⚡ Demo Otomatis: Cetak Uang +50K & Amati Grafik Inflasi"
	},
	{
		"title": "🎓 Demo 3/4: Jinakkan Inflasi dengan Suku Bunga (Volcker Shock)",
		"desc": "Untuk meredam inflasi tinggi, Bank Sentral menaikkan Suku Bunga Acuan & menyerap likuiditas (QT). Konsumsi dan perputaran uang (V) melambat sehingga inflasi turun.",
		"btn": "⚡ Demo Otomatis: Naikkan Bunga ke 11% & Tarik Likuiditas"
	},
	{
		"title": "🎓 Demo 4/4: Uji Krisis Makroekonomi (Stagflation / Dutch Disease)",
		"desc": "Uji insting makroekonomimu menghadapi guncangan ekonomi dunia nyata: gagal panen serentak (Supply-Side Stagflation) atau penguatan kurs ekstrem (Dutch Disease).",
		"btn": "⚡ Demo Otomatis: Picu Stagflation Shock & Buka Analisis"
	}
]

func _ready() -> void:
	_build_ui()
	_refresh_demo_banner()
	_refresh_all_ui()
	
	EventBus.tick_completed.connect(func(_y: int, _m: int): _refresh_all_ui())
	EventBus.province_selected.connect(func(_pid: int): _refresh_province_panel())
	EventBus.policy_updated.connect(func(_nid: String): _refresh_all_ui())
	EventBus.notification_posted.connect(_on_notification_posted)
	EventBus.macro_shock_triggered.connect(_on_macro_shock_triggered)

func _create_styled_panel(bg_color: Color = Color(0.07, 0.09, 0.14, 0.95), border_col: Color = Color("#30363d")) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_col
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	return panel

func _build_ui() -> void:
	# =========================================================================
	# 1. TOP BAR (Indikator Makro Utama dengan Tooltip & Kontrol Kecepatan)
	# =========================================================================
	var top_panel := _create_styled_panel(Color(0.05, 0.07, 0.11, 0.98), Color("#3fb950"))
	top_panel.position = Vector2(0, 0)
	top_panel.size = Vector2(1920, 62)
	top_panel.custom_minimum_size = Vector2(1920, 62)
	add_child(top_panel)
	
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 20)
	top_panel.add_child(top_hbox)
	
	lbl_gdp = _create_top_metric(
		top_hbox,
		"📈 PDB Tahunan (Pertumbuhan Riil)",
		"PDB Nominal = C + I + G + (X - M).\nPDB Riil mengukur output fisik murni tanpa bias harga inflasi."
	)
	lbl_inflation = _create_top_metric(
		top_hbox,
		"🔥 Indeks Harga (CPI) & Inflasi",
		"Mengukur kenaikan harga keranjang komoditas.\nTarget ideal: +1% s/d +4%.\nJika terlalu tinggi: Naikkan Suku Bunga di tab Moneter."
	)
	lbl_rates = _create_top_metric(
		top_hbox,
		"🏦 Suku Bunga & Bond Yield",
		"Suku Bunga Acuan diatur olehmu di tab Moneter.\nBond Yield adalah bunga surat utang negara yang naik jika utangmu membengkak."
	)
	lbl_fiscal = _create_top_metric(
		top_hbox,
		"⚖️ Kas Negara & Rasio Utang/PDB",
		"Kas dipakai untuk membangun pabrik & infrastruktur provinsi.\nJaga Utang/PDB di bawah 60% agar tidak terkena krisis bunga utang."
	)
	lbl_fx_trade = _create_top_metric(
		top_hbox,
		"🌍 Kurs Mata Uang & Ekspor Bersih",
		"Kurs menguat jika Neraca Dagang (NX) surplus atau suku bunga tinggi.\nNX = Ekspor (X) dikurangi Impor (M)."
	)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)
	
	lbl_date = Label.new()
	lbl_date.text = "📅 Jan 1850"
	lbl_date.add_theme_font_size_override("font_size", 15)
	lbl_date.add_theme_color_override("font_color", Color("#f2cc60"))
	top_hbox.add_child(lbl_date)
	
	btn_pause = Button.new()
	btn_pause.text = "⏸ Pause (Space)"
	btn_pause.pressed.connect(func():
		SimulationClock.toggle_pause()
		btn_pause.text = "▶ Play (Space)" if SimulationClock.is_paused else "⏸ Pause (Space)"
	)
	top_hbox.add_child(btn_pause)
	
	for spd in [1, 2, 5]:
		var b := Button.new()
		b.text = "%dx" % spd
		b.pressed.connect(func():
			SimulationClock.set_speed(spd)
			btn_pause.text = "⏸ Pause (Space)"
		)
		top_hbox.add_child(b)
	
	var btn_save := Button.new()
	btn_save.text = "💾 Save"
	btn_save.pressed.connect(func(): SaveManager.save_game("autosave"))
	top_hbox.add_child(btn_save)
	
	var btn_load := Button.new()
	btn_load.text = "📂 Load"
	btn_load.pressed.connect(func(): SaveManager.load_game("autosave"))
	top_hbox.add_child(btn_load)
	
	# =========================================================================
	# 2. TOP-CENTER GUIDED DEMO & MACRO ADVISOR BANNER
	# =========================================================================
	advisor_panel = _create_styled_panel(Color(0.08, 0.12, 0.18, 0.94), Color("#58a6ff"))
	advisor_panel.position = Vector2(376, 68)
	advisor_panel.size = Vector2(1020, 148)
	advisor_panel.custom_minimum_size = Vector2(1020, 148)
	add_child(advisor_panel)
	
	var adv_vbox := VBoxContainer.new()
	adv_vbox.add_theme_constant_override("separation", 5)
	advisor_panel.add_child(adv_vbox)
	
	# Baris Diagnosis Kesehatan Makro Otomatis
	var diag_hbox := HBoxContainer.new()
	diag_hbox.add_theme_constant_override("separation", 12)
	adv_vbox.add_child(diag_hbox)
	
	lbl_diagnosis_status = Label.new()
	lbl_diagnosis_status.add_theme_font_size_override("font_size", 13)
	diag_hbox.add_child(lbl_diagnosis_status)
	
	lbl_diagnosis_summary = Label.new()
	lbl_diagnosis_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_diagnosis_summary.add_theme_font_size_override("font_size", 12)
	lbl_diagnosis_summary.add_theme_color_override("font_color", Color("#c9d1d9"))
	diag_hbox.add_child(lbl_diagnosis_summary)
	
	adv_vbox.add_child(HSeparator.new())
	
	# Baris Tutorial / Guided Demo Interaktif
	var demo_top_hbox := HBoxContainer.new()
	demo_top_hbox.add_theme_constant_override("separation", 10)
	adv_vbox.add_child(demo_top_hbox)
	
	lbl_demo_step_title = Label.new()
	lbl_demo_step_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_demo_step_title.add_theme_font_size_override("font_size", 14)
	lbl_demo_step_title.add_theme_color_override("font_color", Color("#f2cc60"))
	demo_top_hbox.add_child(lbl_demo_step_title)
	
	var btn_prev_demo := Button.new()
	btn_prev_demo.text = "◀ Sebelumnya"
	btn_prev_demo.pressed.connect(func():
		current_demo_step = posmod(current_demo_step - 1, DEMO_STEPS.size())
		_refresh_demo_banner()
	)
	demo_top_hbox.add_child(btn_prev_demo)
	
	var btn_next_demo := Button.new()
	btn_next_demo.text = "Langkah Berikutnya ▶"
	btn_next_demo.pressed.connect(func():
		current_demo_step = posmod(current_demo_step + 1, DEMO_STEPS.size())
		_refresh_demo_banner()
	)
	demo_top_hbox.add_child(btn_next_demo)
	
	lbl_demo_step_desc = Label.new()
	lbl_demo_step_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_demo_step_desc.add_theme_font_size_override("font_size", 12)
	lbl_demo_step_desc.add_theme_color_override("font_color", Color("#e6edf3"))
	adv_vbox.add_child(lbl_demo_step_desc)
	
	btn_demo_action = Button.new()
	btn_demo_action.add_theme_color_override("font_color", Color("#56d364"))
	btn_demo_action.pressed.connect(_execute_current_demo_action)
	adv_vbox.add_child(btn_demo_action)
	
	# =========================================================================
	# 3. LEFT PANEL (Inspektor Provinsi & Pembangunan Sisi Penawaran)
	# =========================================================================
	var left_panel := _create_styled_panel()
	left_panel.position = Vector2(12, 68)
	left_panel.size = Vector2(352, 946)
	left_panel.custom_minimum_size = Vector2(352, 946)
	add_child(left_panel)
	
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 7)
	left_panel.add_child(left_vbox)
	
	var lbl_sel_hdr := Label.new()
	lbl_sel_hdr.text = "🗺️ Pilih Cepat Provinsi Wilayahmu:"
	lbl_sel_hdr.add_theme_font_size_override("font_size", 12)
	lbl_sel_hdr.add_theme_color_override("font_color", Color("#8b949e"))
	left_vbox.add_child(lbl_sel_hdr)
	
	opt_province_selector = OptionButton.new()
	for pid in range(1, 7):
		var p: Province = WorldEconomy.get_province(pid)
		if p:
			opt_province_selector.add_item("🟢 %s (%s)" % [p.name, p.terrain_type], pid)
	opt_province_selector.item_selected.connect(func(idx: int):
		var pid: int = opt_province_selector.get_item_id(idx)
		WorldEconomy.selected_province_id = pid
		EventBus.province_selected.emit(pid)
	)
	left_vbox.add_child(opt_province_selector)
	
	lbl_ownership_badge = Label.new()
	lbl_ownership_badge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_ownership_badge.add_theme_font_size_override("font_size", 12)
	left_vbox.add_child(lbl_ownership_badge)
	
	btn_jump_capital = Button.new()
	btn_jump_capital.text = "🎯 Kembali ke Ibu Kota (★ Sunda Kalapa)"
	btn_jump_capital.visible = false
	btn_jump_capital.pressed.connect(func():
		WorldEconomy.selected_province_id = 1
		EventBus.province_selected.emit(1)
	)
	left_vbox.add_child(btn_jump_capital)
	
	lbl_prov_title = Label.new()
	lbl_prov_title.add_theme_font_size_override("font_size", 16)
	lbl_prov_title.add_theme_color_override("font_color", Color("#f2cc60"))
	left_vbox.add_child(lbl_prov_title)
	
	lbl_prov_stats = Label.new()
	lbl_prov_stats.add_theme_font_size_override("font_size", 12)
	left_vbox.add_child(lbl_prov_stats)
	
	btn_upgrade_infra = Button.new()
	btn_upgrade_infra.text = "🛤️ Tingkatkan Infrastruktur"
	btn_upgrade_infra.pressed.connect(func(): WorldEconomy.upgrade_province_infrastructure(WorldEconomy.selected_province_id))
	left_vbox.add_child(btn_upgrade_infra)
	
	left_vbox.add_child(HSeparator.new())
	
	var lbl_b_header := Label.new()
	lbl_b_header.text = "🏭 Bangun Sektor Produksi (Klik +Lv):"
	lbl_b_header.add_theme_font_size_override("font_size", 13)
	lbl_b_header.add_theme_color_override("font_color", Color("#58a6ff"))
	left_vbox.add_child(lbl_b_header)
	
	var scroll_b := ScrollContainer.new()
	scroll_b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_b.custom_minimum_size = Vector2(324, 460)
	left_vbox.add_child(scroll_b)
	
	vbox_buildings = VBoxContainer.new()
	vbox_buildings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_buildings.add_theme_constant_override("separation", 6)
	scroll_b.add_child(vbox_buildings)
	
	# =========================================================================
	# 4. RIGHT PANEL (Tab Analisa Makroekonomi, Bank Sentral, Fiskal, Pasar, & Krisis)
	# =========================================================================
	right_tabs = TabContainer.new()
	right_tabs.position = Vector2(1408, 68)
	right_tabs.size = Vector2(500, 946)
	right_tabs.custom_minimum_size = Vector2(500, 946)
	add_child(right_tabs)
	
	_build_tab_charts(right_tabs)
	_build_tab_central_bank(right_tabs)
	_build_tab_fiscal(right_tabs)
	_build_tab_market_ledger(right_tabs)
	_build_tab_crisis_lab(right_tabs)
	
	# =========================================================================
	# 5. BOTTOM BAR (Pemilih Map Modes, Legenda Peta, & Toast Notifikasi)
	# =========================================================================
	var bottom_panel := _create_styled_panel()
	bottom_panel.position = Vector2(376, 956)
	bottom_panel.size = Vector2(1020, 58)
	bottom_panel.custom_minimum_size = Vector2(1020, 58)
	add_child(bottom_panel)
	
	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 10)
	bottom_panel.add_child(bottom_hbox)
	
	var lbl_mm := Label.new()
	lbl_mm.text = "🗺️ Mode Peta:"
	bottom_hbox.add_child(lbl_mm)
	
	var modes: Array[Dictionary] = [
		{"id": "political", "label": "Politik (F1)"},
		{"id": "gdp", "label": "Heatmap PDB (F2)"},
		{"id": "sol", "label": "Kesejahteraan / SoL (F3)"},
		{"id": "unemployment", "label": "Pengangguran (F4)"},
		{"id": "infra", "label": "Infrastruktur (F5)"}
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
	lbl_toast.position = Vector2(382, 924)
	lbl_toast.add_theme_font_size_override("font_size", 14)
	lbl_toast.add_theme_color_override("font_color", Color("#f2cc60"))
	add_child(lbl_toast)

func _create_top_metric(parent: Container, title: String, tooltip: String) -> Label:
	var vb := VBoxContainer.new()
	vb.tooltip_text = tooltip
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

func _refresh_demo_banner() -> void:
	var step_data: Dictionary = DEMO_STEPS[current_demo_step]
	lbl_demo_step_title.text = str(step_data["title"])
	lbl_demo_step_desc.text = str(step_data["desc"])
	btn_demo_action.text = str(step_data["btn"])

func _execute_current_demo_action() -> void:
	var player: Nation = WorldEconomy.get_player_nation()
	if player == null:
		return
	
	match current_demo_step:
		0:
			# Pilih Ibu Kota Sunda Kalapa, upgrade infrastruktur & bangun Pangan + Mesin
			WorldEconomy.selected_province_id = 1
			EventBus.province_selected.emit(1)
			WorldEconomy.upgrade_province_infrastructure(1)
			WorldEconomy.upgrade_province_building(1, "grain")
			WorldEconomy.upgrade_province_building(1, "tools")
			right_tabs.current_tab = 0 # Tampilkan Tab Grafik
			EventBus.notification_posted.emit("✅ Demo 1: Infrastruktur & Pabrik di Sunda Kalapa ditingkatkan! Perhatikan kenaikan PDB Riil (kurva hijau).", "success")
			current_demo_step = 1
			_refresh_demo_banner()
		1:
			# Cetak uang QE +50K dan jalankan 3 bulan simulasi agar efek terlihat langsung di grafik
			player.print_money_qe(50_000.0)
			slider_interest.value = player.policy_interest_rate * 100.0
			for _i in range(3):
				SimulationClock.advance_one_month()
			right_tabs.current_tab = 0
			EventBus.notification_posted.emit("🖨️ Demo 2: Bank Sentral mencetak +50K uang! Lihat kurva merah (Inflasi CPI) yang langsung menanjak!", "warning")
			current_demo_step = 2
			_refresh_demo_banner()
		2:
			# Naikkan suku bunga ke 11% dan serap likuiditas QT -30K
			player.policy_interest_rate = 0.11
			slider_interest.value = 11.0
			player.contract_money_supply(30_000.0)
			for _i in range(3):
				SimulationClock.advance_one_month()
			right_tabs.current_tab = 0
			EventBus.notification_posted.emit("🏦 Demo 3: Suku Bunga dinaikkan ke 11% & likuiditas diserap! Perhatikan tekanan inflasi mulai berbalik turun.", "info")
			current_demo_step = 3
			_refresh_demo_banner()
		3:
			# Picu skenario Stagflation & buka tab Krisis
			WorldEconomy.trigger_crisis_scenario("stagflation")
			right_tabs.current_tab = 4
			current_demo_step = 0
			_refresh_demo_banner()

func _build_tab_charts(tabs: TabContainer) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "📈 Grafik"
	vbox.add_theme_constant_override("separation", 12)
	tabs.add_child(vbox)
	
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "💡 Tips Analisa: Bandingkan PDB Nominal (Biru) dengan PDB Riil (Hijau). Jika Biru naik tapi Hijau datar, artinya kenaikan PDB tersebut semu karena Inflasi!"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color("#8b949e"))
	vbox.add_child(hint)
	
	chart_gdp = LineChart.new("PDB Bulanan: Nominal vs Riil (Output Fisik)", "")
	chart_gdp.custom_minimum_size = Vector2(465, 245)
	vbox.add_child(chart_gdp)
	
	chart_inflation = LineChart.new("Laju Inflasi CPI (%) vs Suku Bunga Acuan (%)", "%")
	chart_inflation.custom_minimum_size = Vector2(465, 245)
	vbox.add_child(chart_inflation)
	
	chart_debt = LineChart.new("Rasio Utang/PDB (%) & Imbal Hasil Obligasi (%)", "%")
	chart_debt.custom_minimum_size = Vector2(465, 245)
	vbox.add_child(chart_debt)

func _build_tab_central_bank(tabs: TabContainer) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "🏦 Moneter"
	vbox.add_theme_constant_override("separation", 12)
	tabs.add_child(vbox)
	
	lbl_monetary_summary = Label.new()
	lbl_monetary_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_monetary_summary.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_monetary_summary)
	
	lbl_interest_val = Label.new()
	lbl_interest_val.text = "Suku Bunga Acuan (Policy Rate): 5.00%"
	lbl_interest_val.add_theme_color_override("font_color", Color("#f2cc60"))
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
	theory_box.custom_minimum_size = Vector2(450, 260)
	theory_box.text = "[b]Panduan Teori Moneter (MV = PY):[/b]\n• [color=#3fb950]Naikkan Suku Bunga:[/color] Menurunkan konsumsi rumah tangga & investasi swasta, memperlambat perputaran uang (V), meredam inflasi, dan menguatkan nilai tukar.\n• [color=#f2cc60]Turunkan Suku Bunga:[/color] Memacu kredit & investasi pabrik swasta, namun berisiko memicu Demand-Pull Inflation.\n• [color=#f85149]Cetak Uang (QE):[/color] Menambah kas negara secara instan tanpa utang, tetapi menaikkan rasio M/Y sehingga seluruh harga barang melonjak."
	vbox.add_child(theory_box)

func _build_tab_fiscal(tabs: TabContainer) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "⚖️ Fiskal"
	vbox.add_theme_constant_override("separation", 10)
	tabs.add_child(vbox)
	
	lbl_fiscal_summary = Label.new()
	lbl_fiscal_summary.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_fiscal_summary)
	
	slider_income_tax = _add_policy_slider(vbox, "Pajak Penghasilan Rumah Tangga (Income Tax %)", 0.0, 45.0, 15.0, func(v: float):
		WorldEconomy.get_player_nation().income_tax_rate = v / 100.0
	)
	slider_corp_tax = _add_policy_slider(vbox, "Pajak Laba Industri (Corporate Tax %)", 0.0, 50.0, 20.0, func(v: float):
		WorldEconomy.get_player_nation().corporate_tax_rate = v / 100.0
	)
	slider_vat = _add_policy_slider(vbox, "Pajak Pertambahan Nilai / PPN (VAT %)", 0.0, 25.0, 8.0, func(v: float):
		WorldEconomy.get_player_nation().vat_rate = v / 100.0
	)
	slider_tariff = _add_policy_slider(vbox, "Bea Masuk / Tarif Impor (%)", 0.0, 50.0, 10.0, func(v: float):
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
		EventBus.notification_posted.emit("📜 Negara menerbitkan +30K surat utang obligasi.", "info")
	)
	hbox_bonds.add_child(btn_issue)
	
	var btn_repay := Button.new()
	btn_repay.text = "💸 Lunasi Utang (-30K)"
	btn_repay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_repay.pressed.connect(func():
		var p: Nation = WorldEconomy.get_player_nation()
		p.repay_debt(30_000.0)
		EventBus.policy_updated.emit(p.id)
		EventBus.notification_posted.emit("💸 Pokok utang negara berhasil dilunasi sebesar 30K!", "success")
	)
	hbox_bonds.add_child(btn_repay)

func _add_policy_slider(parent: Container, label_title: String, min_v: float, max_v: float, init_v: float, callback: Callable) -> HSlider:
	var lbl := Label.new()
	lbl.text = "%s: %.1f" % [label_title, init_v]
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
	scroll.name = "📦 Pasar"
	tabs.add_child(scroll)
	
	vbox_market_rows = VBoxContainer.new()
	vbox_market_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_market_rows.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox_market_rows)

func _build_tab_crisis_lab(tabs: TabContainer) -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "⚡ Krisis"
	vbox.add_theme_constant_override("separation", 12)
	tabs.add_child(vbox)
	
	var intro := Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "Uji kemampuan analisis makroekonomimu dengan memicu guncangan ekonomi nyata (Macroeconomic Shocks) dan stabilkan kembali peradabanmu:"
	intro.add_theme_font_size_override("font_size", 12)
	vbox.add_child(intro)
	
	var scenarios: Array[Dictionary] = [
		{"id": "stagflation", "title": "🔥 Picu Supply-Side Stagflation Shock"},
		{"id": "dutch_disease", "title": "💎 Picu Dutch Disease (Kutukan SDA)"},
		{"id": "debt_spiral", "title": "📉 Picu Sovereign Debt Crisis (Krisis Utang)"}
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
	lbl_crisis_advice.custom_minimum_size = Vector2(450, 320)
	lbl_crisis_advice.text = "[b]Diagnosis & Catatan Ekonom:[/b]\nPilih salah satu skenario krisis di atas atau ikuti langkah di panel Demo Interaktif."
	vbox.add_child(lbl_crisis_advice)

func _refresh_all_ui() -> void:
	var player: Nation = WorldEconomy.get_player_nation()
	if player == null:
		return
	
	lbl_date.text = "📅 " + FormatUtils.format_date(SimulationClock.current_year, SimulationClock.current_month)
	
	# Update Diagnosis Kesehatan Makro
	var diag: Dictionary = WorldEconomy.get_player_macro_diagnosis()
	lbl_diagnosis_status.text = str(diag["status"])
	lbl_diagnosis_status.add_theme_color_override("font_color", diag["color"])
	lbl_diagnosis_summary.text = str(diag["summary"])
	
	# Update Topbar dengan pewarnaan indikator kesehatan
	var annual_nom_gdp: float = player.nominal_gdp * 12.0
	lbl_gdp.text = "%s (Riil %s)" % [
		FormatUtils.format_currency(annual_nom_gdp, player.currency_code + " "),
		FormatUtils.format_percent(player.real_gdp_growth_rate, true)
	]
	lbl_gdp.add_theme_color_override("font_color", Color("#3fb950") if player.real_gdp_growth_rate >= 0.0 else Color("#f85149"))
	
	lbl_inflation.text = "CPI %.1f (%s)" % [
		player.cpi_index,
		FormatUtils.format_percent(player.inflation_rate, true)
	]
	var inf_col := Color("#3fb950")
	if absf(player.inflation_rate) > 0.08:
		inf_col = Color("#f85149")
	elif absf(player.inflation_rate) > 0.04:
		inf_col = Color("#f2cc60")
	lbl_inflation.add_theme_color_override("font_color", inf_col)
	
	lbl_rates.text = "Acuan %s | Yield %s" % [
		FormatUtils.format_percent(player.policy_interest_rate),
		FormatUtils.format_percent(player.bond_yield)
	]
	
	var debt_ratio: float = player.get_debt_to_gdp_ratio()
	lbl_fiscal.text = "Kas %s | Utang %s (%s PDB)" % [
		FormatUtils.format_currency(player.treasury_cash, ""),
		FormatUtils.format_currency(player.national_debt, ""),
		FormatUtils.format_percent(debt_ratio)
	]
	lbl_fiscal.add_theme_color_override("font_color", Color("#f85149") if debt_ratio > 0.75 else Color("#e6edf3"))
	
	lbl_fx_trade.text = "Kurs %.2f | NX %s/bln" % [
		player.fx_rate_to_base,
		FormatUtils.format_currency(player.net_exports_nx, "")
	]
	
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
	
	lbl_monetary_summary.text = (
		"Jumlah Uang Beredar (M): %s\n" % FormatUtils.format_currency(player.money_supply, player.currency_code + " ") +
		"Perputaran Uang (Velocity V): %.2f\n" % player.velocity_of_money +
		"Pengali Harga Moneter (M*V / Y_real): %.2fx\n" % player.get_monetary_multiplier() +
		"Pengangguran Nasional: %s | Kesejahteraan Rata-rata: %.1f" % [
			FormatUtils.format_percent(player.avg_unemployment_rate),
			player.avg_standard_of_living
		]
	)
	
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
	
	# Sinkronkan dropdown jika provinsi milik pemain
	if is_owned_by_player:
		var idx: int = opt_province_selector.get_item_index(prov.id)
		if idx >= 0:
			opt_province_selector.selected = idx
		lbl_ownership_badge.text = "🟢 WILAYAH KEDAULATANMU — Kamu bebas membangun Infrastruktur & Pabrik di bawah."
		lbl_ownership_badge.add_theme_color_override("font_color", Color("#3fb950"))
		btn_jump_capital.visible = false
	else:
		lbl_ownership_badge.text = "⚠️ WILAYAH NEGARA TETANGGA (%s) — Hanya mode pantau. Klik provinsi HIJAU atau tombol di bawah untuk membangun wilayahmu!" % (owner_nat.name if owner_nat else "")
		lbl_ownership_badge.add_theme_color_override("font_color", Color("#f2cc60"))
		btn_jump_capital.visible = true
	
	lbl_prov_title.text = "📍 %s" % prov.name
	lbl_prov_stats.text = (
		"Negara: %s | Tipe: %s\n" % [owner_nat.name if owner_nat else "", prov.terrain_type] +
		"Populasi: %s (Pengangguran: %s)\n" % [FormatUtils.format_population(prov.population), FormatUtils.format_percent(prov.unemployment_rate)] +
		"Standard of Living (SoL): %.1f / 100\n" % prov.standard_of_living +
		"PDB Provinsi: %s/bln (Riil: %s)\n" % [FormatUtils.format_currency(prov.local_nominal_gdp, ""), FormatUtils.format_currency(prov.local_real_gdp, "")] +
		"Tabungan Warga: %s | Modal Swasta: %s\n" % [FormatUtils.format_currency(prov.household_savings, ""), FormatUtils.format_currency(prov.capitalist_capital_pool, "")] +
		"Infrastruktur: Lv.%d (Efisiensi Logistik: %s)" % [prov.infrastructure_level, FormatUtils.format_percent(prov.get_infrastructure_efficiency())]
	)
	
	var infra_cost: float = 15_000.0 * float(prov.infrastructure_level)
	btn_upgrade_infra.disabled = not is_owned_by_player or prov.infrastructure_level >= 10
	btn_upgrade_infra.text = "🛤️ Upgrade Infrastruktur ke Lv.%d (Biaya: %s)" % [prov.infrastructure_level + 1, FormatUtils.format_currency(infra_cost, "")]
	
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
		var bonus_tag: String = " ⭐UNGGULAN" if mult >= 1.4 else ""
		lbl.text = "%s (Lv.%d | x%.1f%s)\nOutput: %.1f unit/bln" % [cdata.display_name, lvl, mult, bonus_tag, out_qty]
		if mult >= 1.4:
			lbl.add_theme_color_override("font_color", Color("#56d364"))
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
	
	vbox_market_rows.add_child(HSeparator.new())
	
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
