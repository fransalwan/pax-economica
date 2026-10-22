class_name MacroSimulationTest
extends SceneTree

## Skrip pengujian otomatis (Headless Test) untuk memvalidasi rumus makroekonomi:
## Cara jalankan dari terminal: godot --headless -s res://tests/simulation/MacroSimulationTest.gd

func _init() -> void:
	print("=== Memulai Uji Simulasi Makroekonomi Pax Economica ===")
	var catalog: Dictionary = CommodityData.create_default_catalog()
	var test_nation := Nation.new("test", "Kekaisaran Uji", "TST", Color.GREEN, catalog, true)
	var p1 := Province.new(1, "Provinsi Agraris", "test", Color.RED, "Dataran")
	var p2 := Province.new(2, "Provinsi Industri", "test", Color.BLUE, "Kota")
	test_nation.provinces.append(p1)
	test_nation.provinces.append(p2)
	
	for _m in range(12):
		test_nation.simulate_domestic_economy()
		test_nation.finalize_monthly_accounting()
	
	var baseline_cpi: float = test_nation.cpi_index
	print("Baseline CPI setelah 12 bulan: %.2f | PDB Riil: %.2f" % [baseline_cpi, test_nation.real_gdp])
	
	# Uji Teori Kuantitas Uang: Cetak uang besar-besaran (QE) harus menaikkan CPI
	test_nation.print_money_qe(test_nation.money_supply * 0.80)
	for _m in range(6):
		test_nation.simulate_domestic_economy()
		test_nation.finalize_monthly_accounting()
	
	print("CPI setelah ekspansi moneter +80%%: %.2f (Inflasi: %.2f%%)" % [test_nation.cpi_index, test_nation.inflation_rate * 100.0])
	assert(test_nation.cpi_index > baseline_cpi, "CPI wajib naik ketika jumlah uang beredar ditambah drastis!")
	print("✅ Semua pengujian makroekonomi lulus!")
	quit(0)
