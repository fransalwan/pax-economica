class_name FormatUtils
extends RefCounted

const MONTH_NAMES: Array[String] = [
	"Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
	"Jul", "Agu", "Sep", "Okt", "Nov", "Des"
]

static func format_currency(amount: float, symbol: String = "G ") -> String:
	var sign_str: String = "-" if amount < 0.0 else ""
	var abs_val: float = absf(amount)
	if abs_val >= 1_000_000_000.0:
		return "%s%s%.2fB" % [sign_str, symbol, abs_val / 1_000_000_000.0]
	elif abs_val >= 1_000_000.0:
		return "%s%s%.2fM" % [sign_str, symbol, abs_val / 1_000_000.0]
	elif abs_val >= 1_000.0:
		return "%s%s%.1fK" % [sign_str, symbol, abs_val / 1_000.0]
	else:
		return "%s%s%.1f" % [sign_str, symbol, abs_val]

static func format_percent(rate: float, include_plus: bool = false) -> String:
	var pct: float = rate * 100.0
	if include_plus and pct > 0.0:
		return "+%.2f%%" % pct
	return "%.2f%%" % pct

static func format_population(pop: int) -> String:
	if pop >= 1_000_000:
		return "%.2f Juta" % (float(pop) / 1_000_000.0)
	elif pop >= 1_000:
		return "%.1f Ribu" % (float(pop) / 1_000.0)
	return str(pop)

static func format_date(year: int, month: int) -> String:
	var idx: int = clampi(month - 1, 0, 11)
	return "%s %d" % [MONTH_NAMES[idx], year]
