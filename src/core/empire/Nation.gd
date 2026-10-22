class_name Nation
extends RefCounted

var id: String
var name: String
var currency_code: String
var map_color: Color
var is_player: bool = false

var provinces: Array[Province] = []
var market: Market
var technology_multiplier: float = 1.15

# --- Kebijakan Moneter (Bank Sentral) ---
var policy_interest_rate: float = 0.05   # 5.0% p.a.
var money_supply: float = 250_000.0      # M
var base_real_output_anchor: float = 250_000.0
var velocity_of_money: float = 1.0       # V
var gold_reserves: float = 50_000.0
var fx_rate_to_base: float = 1.00        # 1.00 = paritas nilai tukar awal

# --- Kebijakan Fiskal (Kementerian Keuangan) ---
var treasury_cash: float = 85_000.0
var national_debt: float = 40_000.0
var bond_yield: float = 0.055            # 5.5% p.a.
var income_tax_rate: float = 0.15        # 15%
var corporate_tax_rate: float = 0.20     # 20%
var vat_rate: float = 0.08               # 8%
var import_tariff_rate: float = 0.10     # 10%
var monthly_infra_budget: float = 6_000.0
var monthly_subsidy_budget: float = 4_000.0

# --- Indikator Makroekonomi (Bulanan & Tahunan) ---
var nominal_gdp: float = 120_000.0
var real_gdp: float = 120_000.0
var real_gdp_growth_rate: float = 0.025
var cpi_index: float = 100.0
var inflation_rate: float = 0.02         # YoY / Annualized CPI inflation
var avg_unemployment_rate: float = 0.07
var avg_standard_of_living: float = 55.0

# Komponen Pengeluaran GDP: Y = C + I + G + (X - M)
var consumption_c: float = 0.0
var investment_i: float = 0.0
var gov_spending_g: float = 0.0
var exports_x: float = 0.0
var imports_m: float = 0.0
var net_exports_nx: float = 0.0

# Akuntansi APBN Bulanan
var last_tax_revenue: float = 0.0
var last_tariff_revenue: float = 0.0
var last_bond_interest_expense: float = 0.0
var last_fiscal_balance: float = 0.0
var is_in_debt_crisis: bool = false

# --- Data Time-Series untuk Grafik Analitik (Maks 60 Bulan / 5 Tahun) ---
const MAX_HISTORY: int = 60
var history_nominal_gdp: Array[float] = []
var history_real_gdp: Array[float] = []
var history_cpi: Array[float] = []
var history_inflation: Array[float] = []
var history_interest_rate: Array[float] = []
var history_bond_yield: Array[float] = []
var history_debt_to_gdp: Array[float] = []
var history_fx_rate: Array[float] = []
var history_sol: Array[float] = []
var history_unemployment: Array[float] = []

func _init(
	p_id: String,
	p_name: String,
	p_currency: String,
	p_color: Color,
	p_catalog: Dictionary,
	p_is_player: bool = false
) -> void:
	id = p_id
	name = p_name
	currency_code = p_currency
	map_color = p_color
	is_player = p_is_player
	market = Market.new(p_catalog)

## Teori Kuantitas Uang: M * V = P * Y  ==>  P_mult = (M * V) / Y_real_anchor
func get_monetary_multiplier() -> float:
	# Suku bunga tinggi meredam Velocity of Money (V)
	velocity_of_money = clampf(1.08 - (policy_interest_rate * 1.65), 0.60, 1.35)
	var real_anchor: float = maxf(25_000.0, real_gdp)
	var raw_mult: float = (money_supply * velocity_of_money) / real_anchor
	return clampf(raw_mult, 0.40, 8.00)

func print_money_qe(amount: float) -> void:
	if amount <= 0.0:
		return
	money_supply += amount
	treasury_cash += amount

func contract_money_supply(amount: float) -> void:
	var actual: float = minf(amount, treasury_cash * 0.8)
	if actual <= 0.0:
		return
	money_supply = maxf(20_000.0, money_supply - actual)
	treasury_cash -= actual

func issue_bonds(amount: float) -> void:
	if amount <= 0.0:
		return
	national_debt += amount
	treasury_cash += amount

func repay_debt(amount: float) -> void:
	var actual: float = minf(amount, minf(treasury_cash, national_debt))
	if actual <= 0.0:
		return
	national_debt -= actual
	treasury_cash -= actual

func get_total_population() -> int:
	var total: int = 0
	for prov in provinces:
		total += prov.population
	return total

func get_debt_to_gdp_ratio() -> float:
	# Annualized Nominal GDP = monthly nominal_gdp * 12
	var annualized_gdp: float = maxf(10_000.0, nominal_gdp * 12.0)
	return national_debt / annualized_gdp

## Eksekusi Siklus Bulanan Domestik (Produksi, Konsumsi, Investasi, Fiskal)
func simulate_domestic_economy() -> void:
	market.reset_monthly_flows()
	
	consumption_c = 0.0
	investment_i = 0.0
	gov_spending_g = 0.0
	last_tax_revenue = 0.0
	
	var total_real_prod: float = 0.0
	var prov_count: int = max(1, provinces.size())
	var subsidy_per_prov: float = monthly_subsidy_budget / float(prov_count)
	
	for prov in provinces:
		prov.process_production(market, technology_multiplier)
		total_real_prod += prov.local_real_gdp
		
		var res: Dictionary = prov.process_consumption_and_investment(
			market,
			income_tax_rate,
			corporate_tax_rate,
			vat_rate,
			policy_interest_rate,
			subsidy_per_prov
		)
		last_tax_revenue += float(res["income_tax"]) + float(res["corporate_tax"]) + float(res["vat_tax"])
		consumption_c += float(res["consumption"])
		investment_i += float(res["investment"])
	
	real_gdp = maxf(10_000.0, total_real_prod)
	if history_real_gdp.is_empty():
		# Inisialisasi jangkar uang beredar agar pada bulan ke-1 M*V / Y_real ≈ 1.0
		money_supply = real_gdp
	
	# Belanja Pemerintah (G): Infrastruktur & Subsidi Sosial
	gov_spending_g = monthly_infra_budget + monthly_subsidy_budget
	if monthly_infra_budget > 0.0:
		var timber_p: float = float(market.prices.get("timber", 15.0))
		var iron_p: float = float(market.prices.get("iron", 30.0))
		var coal_p: float = float(market.prices.get("coal", 22.0))
		market.add_demand("timber", (monthly_infra_budget * 0.40) / timber_p)
		market.add_demand("iron", (monthly_infra_budget * 0.40) / iron_p)
		market.add_demand("coal", (monthly_infra_budget * 0.20) / coal_p)

## Penyelesaian Harga Pasar, Akuntansi Makro, Obligasi, dan History
func finalize_monthly_accounting() -> void:
	var mon_mult: float = get_monetary_multiplier()
	market.update_clearing_prices(mon_mult, vat_rate)
	
	net_exports_nx = exports_x - imports_m
	nominal_gdp = maxf(10_000.0, consumption_c + investment_i + gov_spending_g + net_exports_nx)
	
	# Hitung pertumbuhan Real GDP (YoY jika >= 12 bulan, atau MoM annualized)
	if history_real_gdp.size() >= 12:
		var old_real: float = history_real_gdp[history_real_gdp.size() - 12]
		real_gdp_growth_rate = (real_gdp - old_real) / maxf(1.0, old_real)
	elif not history_real_gdp.is_empty():
		var prev_real: float = history_real_gdp.back()
		real_gdp_growth_rate = ((real_gdp - prev_real) / maxf(1.0, prev_real)) * 12.0
	
	# Hitung CPI & Inflasi
	cpi_index = market.calculate_cpi()
	if history_cpi.size() >= 12:
		var old_cpi: float = history_cpi[history_cpi.size() - 12]
		inflation_rate = (cpi_index - old_cpi) / maxf(1.0, old_cpi)
	elif not history_cpi.is_empty():
		var prev_cpi: float = history_cpi.back()
		inflation_rate = ((cpi_index - prev_cpi) / maxf(1.0, prev_cpi)) * 12.0
	
	# Hitung Bond Yield Dinamis berdasarkan Suku Bunga Acuan, Inflasi, & Debt-to-GDP
	var debt_ratio: float = get_debt_to_gdp_ratio()
	var debt_risk_spread: float = maxf(0.0, (debt_ratio - 0.60) * 0.18)
	var inflation_premium: float = maxf(0.0, inflation_rate * 0.45)
	bond_yield = clampf(policy_interest_rate + debt_risk_spread + inflation_premium + 0.005, 0.01, 0.45)
	
	# Pembayaran Bunga Utang & Penyelesaian Anggaran Fiskal
	last_bond_interest_expense = national_debt * (bond_yield / 12.0)
	var total_gov_revenue: float = last_tax_revenue + last_tariff_revenue
	var total_gov_outlay: float = gov_spending_g + last_bond_interest_expense
	last_fiscal_balance = total_gov_revenue - total_gov_outlay
	
	treasury_cash += last_fiscal_balance
	if treasury_cash < 0.0:
		# Otomatis menerbitkan obligasi baru untuk menutup defisit kas
		var deficit_shortfall: float = absf(treasury_cash)
		national_debt += deficit_shortfall
		treasury_cash = 0.0
	
	is_in_debt_crisis = debt_ratio > 1.10 or bond_yield > 0.22
	
	# Rata-rata Pengangguran & Standard of Living Populasi
	var weighted_unemp: float = 0.0
	var weighted_sol: float = 0.0
	var total_pop: int = max(1, get_total_population())
	for prov in provinces:
		var w: float = float(prov.population) / float(total_pop)
		weighted_unemp += prov.unemployment_rate * w
		weighted_sol += prov.standard_of_living * w
	avg_unemployment_rate = weighted_unemp
	avg_standard_of_living = weighted_sol
	
	# Pertumbuhan uang beredar organik dari ekspansi kredit perbankan (dipengaruhi suku bunga)
	var credit_expansion_rate: float = clampf((0.055 - policy_interest_rate) * 0.12, -0.008, 0.015)
	money_supply = maxf(15_000.0, money_supply * (1.0 + credit_expansion_rate))
	
	_record_history_snapshot()

func _record_history_snapshot() -> void:
	_push_hist(history_nominal_gdp, nominal_gdp)
	_push_hist(history_real_gdp, real_gdp)
	_push_hist(history_cpi, cpi_index)
	_push_hist(history_inflation, inflation_rate * 100.0)
	_push_hist(history_interest_rate, policy_interest_rate * 100.0)
	_push_hist(history_bond_yield, bond_yield * 100.0)
	_push_hist(history_debt_to_gdp, get_debt_to_gdp_ratio() * 100.0)
	_push_hist(history_fx_rate, fx_rate_to_base)
	_push_hist(history_sol, avg_standard_of_living)
	_push_hist(history_unemployment, avg_unemployment_rate * 100.0)

func _push_hist(arr: Array[float], val: float) -> void:
	arr.append(val)
	if arr.size() > MAX_HISTORY:
		arr.pop_front()

