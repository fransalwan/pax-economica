class_name Province
extends RefCounted

var id: int
var name: String
var owner_nation_id: String
var color_id: Color
var terrain_type: String
var polygon_points: PackedVector2Array = PackedVector2Array()
var center_pos: Vector2 = Vector2.ZERO

# Demografi & Kesejahteraan
var population: int = 120_000
var employed_pop: int = 105_000
var unemployment_rate: float = 0.08
var standard_of_living: float = 55.0 # Skala 0 - 100
var household_savings: float = 25_000.0
var capitalist_capital_pool: float = 40_000.0

# Kapasitas Produksi & Infrastruktur
var infrastructure_level: int = 2 # Level 1 - 10
var buildings: Dictionary = {}    # commodity_id -> int (level pabrik/pertanian)
var resource_multipliers: Dictionary = {} # Keunggulan komparatif geografis (0.5x s/d 2.0x)
var supply_shock_modifier: float = 1.0    # Untuk event gagal panen / bencana / boom

# Akuntansi Provinsi Bulanan
var local_nominal_gdp: float = 0.0
var local_real_gdp: float = 0.0
var local_wages_paid: float = 0.0
var local_corporate_profits: float = 0.0
var local_consumption_value: float = 0.0
var local_private_investment: float = 0.0
var last_production_volume: Dictionary = {}

const WORKERS_PER_BUILDING_LEVEL: int = 12_000
const COBB_DOUGLAS_ALPHA: float = 0.38

func _init(
	p_id: int,
	p_name: String,
	p_owner: String,
	p_color_id: Color,
	p_terrain: String = "Dataran Subur"
) -> void:
	id = p_id
	name = p_name
	owner_nation_id = p_owner
	color_id = p_color_id
	terrain_type = p_terrain
	
	for cid in ["grain", "timber", "coal", "iron", "cloth", "tools", "luxury"]:
		buildings[cid] = 1
		resource_multipliers[cid] = 1.0
		last_production_volume[cid] = 0.0

func get_infrastructure_efficiency() -> float:
	var total_building_levels: int = get_total_building_levels()
	var required_infra: float = maxf(1.0, float(total_building_levels) / 4.5)
	var ratio: float = float(infrastructure_level) / required_infra
	return clampf(0.45 + 0.45 * ratio, 0.35, 1.35)

func get_total_building_levels() -> int:
	var total: int = 0
	for cid in buildings.keys():
		total += int(buildings[cid])
	return total

## 1. Fase Produksi Cobb-Douglas: Y = A * K^alpha * L^(1-alpha) * Infra_eff
func process_production(market: Market, tech_multiplier: float) -> void:
	local_nominal_gdp = 0.0
	local_real_gdp = 0.0
	local_wages_paid = 0.0
	local_corporate_profits = 0.0
	
	var total_levels: int = max(1, get_total_building_levels())
	var total_labor_demand: int = total_levels * WORKERS_PER_BUILDING_LEVEL
	var active_workforce: int = int(float(population) * 0.65) # 65% usia produktif
	
	employed_pop = mini(active_workforce, total_labor_demand)
	unemployment_rate = clampf(1.0 - (float(employed_pop) / maxf(1.0, float(active_workforce))), 0.01, 0.85)
	
	var labor_fill_ratio: float = clampf(float(employed_pop) / float(total_labor_demand), 0.15, 1.0)
	var infra_eff: float = get_infrastructure_efficiency()
	
	for cid in buildings.keys():
		var b_level: int = int(buildings[cid])
		if b_level <= 0:
			last_production_volume[cid] = 0.0
			continue
		
		var capital_k: float = float(b_level) * 18.0
		var labor_l: float = float(b_level) * 22.0 * labor_fill_ratio
		var geo_mult: float = float(resource_multipliers.get(cid, 1.0))
		
		# Output produksi Cobb-Douglas
		var output_qty: float = (
			tech_multiplier
			* geo_mult
			* pow(capital_k, COBB_DOUGLAS_ALPHA)
			* pow(labor_l, 1.0 - COBB_DOUGLAS_ALPHA)
			* infra_eff
			* supply_shock_modifier
		)
		
		# Manufaktur butuh input alat kerja & energi secara implisit
		if cid in ["cloth", "tools", "luxury"]:
			var tools_price_ratio: float = market.prices.get("tools", 45.0) / 45.0
			var input_cost_drag: float = clampf(1.15 - 0.15 * tools_price_ratio, 0.65, 1.20)
			output_qty *= input_cost_drag
		
		last_production_volume[cid] = output_qty
		market.add_supply(cid, output_qty)
		
		var current_price: float = float(market.prices.get(cid, 10.0))
		var base_price: float = (market.catalog[cid] as CommodityData).base_price
		
		var revenue_nominal: float = output_qty * current_price
		var revenue_real: float = output_qty * base_price
		
		local_nominal_gdp += revenue_nominal
		local_real_gdp += revenue_real
		
		# Pembagian pendapatan antara Upah Pekerja (62%) dan Laba Pemilik Modal (38%)
		var wage_share: float = revenue_nominal * 0.62
		var profit_share: float = revenue_nominal * 0.38
		local_wages_paid += wage_share
		local_corporate_profits += profit_share

	# Pemulihan bertahap supply shock kembali ke 1.0
	supply_shock_modifier = lerpf(supply_shock_modifier, 1.0, 0.15)

## 2. Fase Pajak, Konsumsi Rumah Tangga (C), & Investasi Swasta (I)
func process_consumption_and_investment(
	market: Market,
	income_tax_rate: float,
	corporate_tax_rate: float,
	vat_rate: float,
	central_bank_rate: float,
	social_subsidy_transfer: float
) -> Dictionary:
	var income_tax_collected: float = local_wages_paid * income_tax_rate
	var corporate_tax_collected: float = local_corporate_profits * corporate_tax_rate
	
	var disposable_household_income: float = (local_wages_paid - income_tax_collected) + social_subsidy_transfer
	var net_corporate_profit: float = local_corporate_profits - corporate_tax_collected
	
	# Suku bunga tinggi mendorong rumah tangga menabung (Marginal Propensity to Consume turun)
	var mpc: float = clampf(0.86 - (central_bank_rate * 1.45), 0.50, 0.94)
	var planned_consumption_budget: float = disposable_household_income * mpc + (household_savings * 0.04)
	
	household_savings += (disposable_household_income - planned_consumption_budget) + (household_savings * (central_bank_rate / 12.0))
	household_savings = maxf(0.0, household_savings)
	
	# Alokasikan anggaran konsumsi ke komoditas di pasar
	local_consumption_value = 0.0
	var total_needs_satisfied_ratio: float = 0.0
	var pop_scale: float = float(population) / 100_000.0
	
	for cid in market.catalog.keys():
		var cdata: CommodityData = market.catalog[cid]
		var weight: float = cdata.cpi_weight
		if weight <= 0.0:
			continue
		
		var spend_on_good: float = planned_consumption_budget * weight
		var effective_price: float = float(market.prices[cid]) * (1.0 + vat_rate)
		var qty_demanded: float = spend_on_good / maxf(1.0, effective_price)
		
		# Kebutuhan dasar minimal berdasarkan populasi
		var min_subsistence_qty: float = pop_scale * weight * 38.0
		var final_demand_qty: float = maxf(qty_demanded, min_subsistence_qty * 0.65)
		
		market.add_demand(cid, final_demand_qty)
		local_consumption_value += final_demand_qty * float(market.prices[cid])
		
		var fulfillment: float = clampf(qty_demanded / maxf(1.0, min_subsistence_qty), 0.2, 1.8)
		total_needs_satisfied_ratio += fulfillment * weight
	
	var vat_collected: float = local_consumption_value * vat_rate
	
	# 3. Investasi Sektor Swasta (I) — sangat sensitif terhadap Suku Bunga Bank Sentral (r)
	capitalist_capital_pool += net_corporate_profit
	var investment_appetite: float = clampf(0.65 - (central_bank_rate * 3.2), 0.05, 0.80)
	local_private_investment = capitalist_capital_pool * investment_appetite
	capitalist_capital_pool -= local_private_investment
	
	# Investasi swasta membeli Kayu, Besi, dan Mesin (Tools) di pasar
	if local_private_investment > 0.0:
		var timber_p: float = float(market.prices.get("timber", 15.0))
		var iron_p: float = float(market.prices.get("iron", 30.0))
		var tools_p: float = float(market.prices.get("tools", 45.0))
		
		market.add_demand("timber", (local_private_investment * 0.30) / timber_p)
		market.add_demand("iron", (local_private_investment * 0.35) / iron_p)
		market.add_demand("tools", (local_private_investment * 0.35) / tools_p)
	
	# Update Standard of Living (0 - 100) & Pertumbuhan Populasi
	var target_sol: float = clampf(total_needs_satisfied_ratio * 58.0 * (1.0 - unemployment_rate * 0.5), 10.0, 99.0)
	standard_of_living = lerpf(standard_of_living, target_sol, 0.20)
	
	var monthly_pop_growth_rate: float = clampf((standard_of_living - 35.0) * 0.00005, -0.002, 0.004)
	population = maxi(10_000, int(float(population) * (1.0 + monthly_pop_growth_rate)))
	
	return {
		"income_tax": income_tax_collected,
		"corporate_tax": corporate_tax_collected,
		"vat_tax": vat_collected,
		"consumption": local_consumption_value,
		"investment": local_private_investment
	}

