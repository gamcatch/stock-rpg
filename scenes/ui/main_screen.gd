# ==============================================================================
# Stock RPG : 세로 모드 메인 화면 컨트롤러 (MainScreen)
# ==============================================================================
# 상단 방치 사냥 뷰포트 + 중단 실시간 속보 티커 + 하단 개미 육성/종목 매수 대시보드
# ==============================================================================
extends Control

@onready var header_market_label = $TopSafeContainer/VBox/HeaderBar/MarketLabel
@onready var header_balance_label = $TopSafeContainer/VBox/HeaderBar/BalanceLabel
@onready var ticker_label = $MiddleBar/TickerBox/TickerLabel
@onready var dividend_btn = $MiddleBar/DividendBox/DividendClaimBtn
@onready var dividend_val_label = $MiddleBar/DividendBox/DividendValLabel

# 하단 탭 컨테이너
@onready var tab_stats = $BottomDashboard/TabStats
@onready var tab_portfolio = $BottomDashboard/TabPortfolio
@onready var tab_market = $BottomDashboard/TabMarket

# 스펙업 버튼 및 라벨
@onready var atk_lvl_label = $BottomDashboard/TabStats/VBox/AtkRow/LvlLabel
@onready var hp_lvl_label = $BottomDashboard/TabStats/VBox/HpRow/LvlLabel
@onready var crit_lvl_label = $BottomDashboard/TabStats/VBox/CritRow/LvlLabel

var atk_level: int = 1
var hp_level: int = 1
var crit_level: int = 1

# 분당 배당금 축적 타이머
var accumulated_dividends: float = 0.0

func _ready():
	_apply_safe_area()
	_update_header()
	_update_stats_ui()
	_populate_stock_list()
	
	PortfolioManager.portfolio_updated.connect(_on_portfolio_updated)
	if MarketDataManager.has_signal("breaking_news_alert"):
		MarketDataManager.breaking_news_alert.connect(_on_breaking_news)

func _process(delta: float):
	# 1. 배당금 실시간 누적 (1초마다)
	var per_min = PortfolioManager.get_per_minute_dividends()
	accumulated_dividends += (float(per_min) / 60.0) * delta
	if dividend_val_label:
		dividend_val_label.text = "%s ₩" % _format_number(int(accumulated_dividends))
		
	# 2. 티커 뉴스 롤링
	if ticker_label and MarketDataManager.news_pool.size() > 0:
		var idx = MarketDataManager.news_cycle_index % MarketDataManager.news_pool.size()
		var news_item = MarketDataManager.news_pool[idx]
		var news_text = ""
		if news_item is Dictionary:
			news_text = news_item.get("headline", news_item.get("title", str(news_item)))
		else:
			news_text = str(news_item)
		ticker_label.text = "📢 " + news_text
		
	_update_header()

func _update_header():
	if header_balance_label:
		header_balance_label.text = "자산: %s ₩ (▲+%.1f%%)" % [_format_number(Global.account_balance), Global.current_return_rate]
	if header_market_label:
		var kor = (MarketDataManager.current_market_type == MarketDataManager.MarketType.KOREA)
		header_market_label.text = "🇰🇷 KOSPI 2,750 ▲1.4%" if kor else "🇺🇸 NASDAQ 18,200 ▲0.8%"

# ------------------------------------------------------------------------------
# 📱 Safe Area 적용
# ------------------------------------------------------------------------------
func _apply_safe_area():
	var safe_rect = DisplayServer.get_display_safe_area()
	var screen_size = DisplayServer.screen_get_size()
	
	var top_margin = max(40, safe_rect.position.y)
	var bottom_margin = max(40, screen_size.y - (safe_rect.position.y + safe_rect.size.y))
	
	$TopSafeContainer.add_theme_constant_override("margin_top", top_margin)
	$BottomSafeContainer.add_theme_constant_override("margin_bottom", bottom_margin)

# ------------------------------------------------------------------------------
# 🎁 배당금 수령 버튼
# ------------------------------------------------------------------------------
func _on_dividend_claim_btn_pressed():
	var claim_amount = int(accumulated_dividends)
	if claim_amount > 0:
		Global.account_balance += claim_amount
		accumulated_dividends = 0.0
		SoundManager.play_exp_coin()
		_update_header()

# ------------------------------------------------------------------------------
# ⚔️ 개미 스펙업 로직
# ------------------------------------------------------------------------------
func _on_atk_upgrade_pressed():
	var cost = atk_level * 50000
	if Global.account_balance >= cost:
		Global.account_balance -= cost
		atk_level += 1
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.base_atk += 8.0
		SoundManager.play_level_up()
		_update_stats_ui()

func _on_hp_upgrade_pressed():
	var cost = hp_level * 40000
	if Global.account_balance >= cost:
		Global.account_balance -= cost
		hp_level += 1
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.max_hp += 80.0
			player.current_hp += 80.0
		SoundManager.play_level_up()
		_update_stats_ui()

func _on_crit_upgrade_pressed():
	var cost = crit_level * 100000
	if Global.account_balance >= cost:
		Global.account_balance -= cost
		crit_level += 1
		SoundManager.play_level_up()
		_update_stats_ui()

func _update_stats_ui():
	if atk_lvl_label:
		atk_lvl_label.text = "공격력 Lv.%d (비용: %s ₩)" % [atk_level, _format_number(atk_level * 50000)]
	if hp_lvl_label:
		hp_lvl_label.text = "최대체력 Lv.%d (비용: %s ₩)" % [hp_level, _format_number(hp_level * 40000)]
	if crit_lvl_label:
		crit_lvl_label.text = "치명타율 Lv.%d (비용: %s ₩)" % [crit_level, _format_number(crit_level * 100000)]
	_update_header()

# ------------------------------------------------------------------------------
# 📈 종목 매수 리스트 채우기
# ------------------------------------------------------------------------------
func _populate_stock_list():
	var list_container = $BottomDashboard/TabPortfolio/Scroll/StockVBox
	if not list_container:
		return
		
	# 기존 목록 정리
	for child in list_container.get_children():
		child.queue_free()
		
	var target_stocks = [
		{"name": "삼성전자", "code": "005930", "price": "78,400", "rate": 1.5, "sector": "semiconductor"},
		{"name": "SK하이닉스", "code": "000660", "price": "189,200", "rate": 6.8, "sector": "semiconductor"},
		{"name": "한미반도체", "code": "042700", "price": "142,500", "rate": 14.8, "sector": "semiconductor"},
		{"name": "HD현대일렉트릭", "code": "026720", "price": "312,000", "rate": 9.2, "sector": "power_grid"},
		{"name": "KB금융", "code": "105560", "price": "84,200", "rate": 2.8, "sector": "finance"},
		{"name": "에코프로", "code": "086520", "price": "79,500", "rate": -3.2, "sector": "battery"},
		{"name": "NVIDIA", "code": "NVDA", "price": "$128.50", "rate": 4.2, "sector": "us_ai_chips"},
		{"name": "Tesla", "code": "TSLA", "price": "$258.00", "rate": -1.8, "sector": "us_ev_robotaxi"}
	]
	
	for s in target_stocks:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 56)
		
		var name_lbl = Label.new()
		name_lbl.custom_minimum_size = Vector2(280, 0)
		name_lbl.text = "%s (%s%.1f%%)" % [s["name"], "+" if s["rate"] >= 0 else "", s["rate"]]
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if s["rate"] >= 0 else Color(0.3, 0.6, 1.0))
		row.add_child(name_lbl)
		
		var owned_shares = 0
		if PortfolioManager.owned_stocks.has(s["name"]):
			owned_shares = PortfolioManager.owned_stocks[s["name"]].get("shares", 0)
			
		var shares_lbl = Label.new()
		shares_lbl.custom_minimum_size = Vector2(200, 0)
		shares_lbl.text = "보유: %d주" % owned_shares
		row.add_child(shares_lbl)
		
		var buy_btn = Button.new()
		buy_btn.text = "매수 (%s)" % s["price"]
		buy_btn.custom_minimum_size = Vector2(180, 44)
		buy_btn.pressed.connect(func():
			if PortfolioManager.buy_stock(s["name"], s, 1):
				SoundManager.play_level_up()
				_populate_stock_list()
		)
		row.add_child(buy_btn)
		
		list_container.add_child(row)

func _on_portfolio_updated():
	_populate_stock_list()

func _on_breaking_news(headline: String, stock_name: String, sector_key: String, effect: String, dur: float):
	if ticker_label:
		ticker_label.text = "🚨 " + headline

# ------------------------------------------------------------------------------
# 📑 탭 전환
# ------------------------------------------------------------------------------
func _on_tab_btn_pressed(tab_idx: int):
	tab_stats.visible = (tab_idx == 0)
	tab_portfolio.visible = (tab_idx == 1)
	tab_market.visible = (tab_idx == 2)
	SoundManager.play_button_click()

func _format_number(n: int) -> String:
	var s = str(n)
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return res
