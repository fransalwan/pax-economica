class_name Market
extends RefCounted

var catalog: Dictionary = {}
var supply: Dictionary = {}
var demand: Dictionary = {}
var prices: Dictionary = {}
var previous_prices: Dictionary = {}
var net_trade_volume: Dictionary = {} # + berarti net export, - berarti net import
var price_history: Dictionary = {}    # commodity_id -> Array[float]

const MAX_HISTORY_LEN: int = 60
const PRICE_SENSITIVITY_K: float = 0.70
const PRICE_SMOOTHING_ALPHA: float = 0.35

func _init(p_catalog: Dictionary) -> void:
	catalog = p_catalog
	for cid in catalog.keys():
		var cdata: CommodityData = catalog[cid]
		supply[cid] = 100.0
		demand[cid] = 100.0
		prices[cid] = cdata.base_price
		previous_prices[cid] = cdata.base_price
		net_trade_volume[cid] = 0.0
		price_history[cid] = [cdata.base_price]

func reset_monthly_flows() -> void:
	for cid in catalog.keys():
		supply[cid] = 0.0
		demand[cid] = 0.0
		net_trade_volume[cid] = 0.0

func add_supply(commodity_id: String, amount: float) -> void:
	if supply.has(commodity_id):
		supply[commodity_id] += maxf(0.0, amount)

func add_demand(commodity_id: String, amount: float) -> void:
	if demand.has(commodity_id):
		demand[commodity_id] += maxf(0.0, amount)

func update_clearing_prices(monetary_multiplier: float, vat_rate: float = 0.0) -> void:
	for cid in catalog.keys():
		var cdata: CommodityData = catalog[cid]
		previous_prices[cid] = prices[cid]
		
		var s: float = maxf(supply[cid] - net_trade_volume[cid], 1.0)
		var d: float = maxf(demand[cid], 1.0)
		var imbalance_ratio: float = clampf((d - s) / maxf(s, d), -0.80, 1.50)
		
		# Harga keseimbangan dipengaruhi Supply-Demand imbalance, Pengali Moneter (M*V/Y), dan PPN (VAT)
		var target_price: float = cdata.base_price * (1.0 + PRICE_SENSITIVITY_K * imbalance_ratio) * monetary_multiplier * (1.0 + vat_rate * 0.5)
		target_price = maxf(cdata.base_price * 0.20, target_price)
		
		var new_price: float = lerpf(prices[cid], target_price, PRICE_SMOOTHING_ALPHA)
		prices[cid] = new_price
		
		var hist: Array = price_history[cid]
		hist.append(new_price)
		if hist.size() > MAX_HISTORY_LEN:
			hist.pop_front()

func calculate_cpi() -> float:
	var weighted_sum: float = 0.0
	for cid in catalog.keys():
		var cdata: CommodityData = catalog[cid]
		var price_ratio: float = prices[cid] / cdata.base_price
		weighted_sum += cdata.cpi_weight * price_ratio
	return weighted_sum * 100.0

func get_market_imbalance_pct(commodity_id: String) -> float:
	var s: float = maxf(supply.get(commodity_id, 1.0) - net_trade_volume.get(commodity_id, 0.0), 1.0)
	var d: float = maxf(demand.get(commodity_id, 1.0), 1.0)
	return (d - s) / s

func to_dict() -> Dictionary:
	return {
		"supply": supply.duplicate(),
		"demand": demand.duplicate(),
		"prices": prices.duplicate(),
		"previous_prices": previous_prices.duplicate(),
		"net_trade_volume": net_trade_volume.duplicate()
	}

func from_dict(data: Dictionary) -> void:
	if data.has("supply"):
		supply = data["supply"].duplicate()
	if data.has("demand"):
		demand = data["demand"].duplicate()
	if data.has("prices"):
		prices = data["prices"].duplicate()
	if data.has("previous_prices"):
		previous_prices = data["previous_prices"].duplicate()
	if data.has("net_trade_volume"):
		net_trade_volume = data["net_trade_volume"].duplicate()
