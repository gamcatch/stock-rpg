# ==============================================================================
# Stock RPG : 포트폴리오 매니저 (PortfolioManager)
# ==============================================================================
# 단일 개미 플레이어가 보유한 실제 종목 지분, 공전하는 위성 오브,
# 종목별 배당수익률 및 분당 방치 배당금을 관리하는 싱글톤입니다.
# ==============================================================================
extends Node

signal portfolio_updated()
signal stock_purchased(stock_name: String, shares: int)
signal dividends_collected(amount: int)

const SAVE_PATH: String = "user://portfolio_stocks.json"

# 플레이어가 보유 중인 주식 포트폴리오 { "stock_name": { "shares": int, "avg_price": int, "rate": float, "dividend_yield": float } }
var owned_stocks: Dictionary = {}

# 분당 누적 배당금
var accumulated_dividends: float = 0.0

func _ready():
	load_portfolio()
	if owned_stocks.is_empty():
		_init_starter_portfolio()

# ------------------------------------------------------------------------------
# 🎁 초기 지급 포트폴리오 (국민주 삼성전자 10주, SK하이닉스 5주 기본 보유)
# ------------------------------------------------------------------------------
func _init_starter_portfolio():
	owned_stocks["삼성전자"] = {
		"code": "005930",
		"shares": 10,
		"sector": "semiconductor",
		"dividend_yield": 2.8,
		"rate": 1.5
	}
	owned_stocks["SK하이닉스"] = {
		"code": "000660",
		"shares": 5,
		"sector": "semiconductor",
		"dividend_yield": 2.1,
		"rate": 6.8
	}
	save_portfolio()
	portfolio_updated.emit()

# ------------------------------------------------------------------------------
# 🛒 종목 매수 (시드머니 소비)
# ------------------------------------------------------------------------------
func buy_stock(stock_name: String, stock_info: Dictionary, shares_to_buy: int = 1) -> bool:
	var price_val = int(str(stock_info.get("price", "50,000")).replace(",", "").replace("$", "").replace(" ", ""))
	if price_val <= 0:
		price_val = 50000
		
	var total_cost = price_val * shares_to_buy
	if Global.account_balance < total_cost:
		print("[PortfolioManager] 잔고 부족: 필요 %d원, 보유 %d원" % [total_cost, Global.account_balance])
		return false
		
	Global.account_balance -= total_cost
	
	if not owned_stocks.has(stock_name):
		owned_stocks[stock_name] = {
			"code": stock_info.get("code", ""),
			"shares": 0,
			"sector": stock_info.get("sector", "general"),
			"dividend_yield": 2.5,
			"rate": float(stock_info.get("rate", 0.0))
		}
		
	owned_stocks[stock_name]["shares"] += shares_to_buy
	owned_stocks[stock_name]["rate"] = float(stock_info.get("rate", owned_stocks[stock_name]["rate"]))
	
	save_portfolio()
	stock_purchased.emit(stock_name, shares_to_buy)
	portfolio_updated.emit()
	return true

# ------------------------------------------------------------------------------
# 📊 분당 배당금 및 보유 종목 계산
# ------------------------------------------------------------------------------
func get_per_minute_dividends() -> int:
	var total_div: float = 0.0
	for sname in owned_stocks.keys():
		var item = owned_stocks[sname]
		var shares = item.get("shares", 0)
		var dy = item.get("dividend_yield", 2.0)
		# 1주당 분당 기본 배당금 (지분 * 배당률 가산)
		total_div += float(shares) * dy * 15.0
		
	return int(total_div)

func get_total_shares_count() -> int:
	var count = 0
	for sname in owned_stocks.keys():
		count += owned_stocks[sname].get("shares", 0)
	return count

func get_owned_stock_names() -> Array:
	return owned_stocks.keys()

# ------------------------------------------------------------------------------
# 💾 저장 및 로드
# ------------------------------------------------------------------------------
func save_portfolio():
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(owned_stocks, "\t"))
		f.close()

func load_portfolio():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK:
		var d = json.get_data()
		if d is Dictionary:
			owned_stocks = d
	f.close()
