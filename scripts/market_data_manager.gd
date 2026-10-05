extends Node

signal market_mode_changed(mode_name, is_korean)
signal sector_entered(sector_data)
signal breaking_news_alert(headline, sector_key, effect_type, duration)
signal live_rates_applied(market_type)
signal live_news_received(news_list)
signal stock_vi_triggered(stock_name, duration)
signal stock_trading_resumed(stock_name)

enum MarketType {
	KOREA,   # 국장 (KOSPI / KOSDAQ)
	US,      # 미장 (NASDAQ / S&P500)
	CRYPTO   # 주말/야간 24h 가상자산
}

var current_market_type: MarketType = MarketType.KOREA
var market_name: String = "대한민국 KOSPI/KOSDAQ"

# Sector data for the current active market
# Coordinates represent world positions relative to center (0, 0)
var sectors = {}

const DEFAULT_PRICES: Dictionary = {
	# Korea Stocks
	"한미반도체": "142,500", "042700": "142,500",
	"SK하이닉스": "189,200", "000660": "189,200",
	"삼성전자": "78,400", "005930": "78,400",
	"HPSP": "41,200", "403870": "41,200",
	"리노공업": "195,000", "058470": "195,000",
	"이수페타시스": "43,800", "007660": "43,800",
	"제주반도체": "24,800", "080220": "24,800",
	"가온칩스": "48,500", "399720": "48,500",
	"HD현대일렉트릭": "312,000", "026720": "312,000",
	"두산에너빌리티": "21,400", "034020": "21,400",
	"LS ELECTRIC": "172,000", "010120": "172,000",
	"효성중공업": "415,000", "298040": "415,000",
	"한전KPS": "42,100", "051600": "42,100",
	"일진전기": "28,200", "103590": "28,200",
	"우진엔텍": "18,400", "457550": "18,400",
	"제룡전기": "48,000", "033100": "48,000",
	"두산로보틱스": "73,500", "454910": "73,500",
	"레인보우로보": "148,000", "277810": "148,000",
	"NAVER": "194,500", "035420": "194,500",
	"카카오": "42,300", "035720": "42,300",
	"루닛": "53,800", "328130": "53,800",
	"로보티즈": "19,800", "108490": "19,800",
	"엔젤로보틱스": "24,500", "455900": "24,500",
	"폴라리스AI": "2,420", "039980": "2,420",
	"HD한국조선해양": "198,000", "009540": "198,000",
	"삼성중공업": "11,250", "010140": "11,250",
	"한화오션": "38,400", "042660": "38,400",
	"HD현대마린엔진": "34,200", "071970": "34,200",
	"HMM": "18,200", "011200": "18,200",
	"팬오션": "3,850", "028670": "3,850",
	"HJ중공업": "3,450", "097230": "3,450",
	"현대힘스": "16,200", "460930": "16,200",
	"에코프로비엠": "168,000", "247540": "168,000",
	"에코프로": "79,500", "086520": "79,500",
	"LG에너지솔루션": "385,000", "373220": "385,000",
	"POSCO홀딩스": "362,000", "005490": "362,000",
	"포스코퓨처엠": "224,000", "003670": "224,000",
	"엔켐": "185,000", "348370": "185,000",
	"대주전자재료": "98,000", "078600": "98,000",
	"금양": "42,000", "001570": "42,000",
	"KB금융": "84,200", "105560": "84,200",
	"신한지주": "54,600", "055550": "54,600",
	"메리츠금융지주": "89,500", "138040": "89,500",
	"하나금융지주": "63,400", "086790": "63,400",
	"삼성물산": "148,500", "028260": "148,500",
	"삼성생명": "98,500", "032830": "98,500",
	"미래에셋증권": "8,900", "006800": "8,900",
	"우리금융지주": "15,800", "316140": "15,800",
	"알테오젠": "382,000", "196170": "382,000",
	"삼성바이오로직스": "985,000", "207940": "985,000",
	"셀트리온": "198,500", "068270": "198,500",
	"유한양행": "142,000", "000100": "142,000",
	"HLB": "84,500", "028300": "84,500",
	"리가켐바이오": "118,000", "141080": "118,000",
	"삼천당제약": "135,000", "000250": "135,000",
	"에이비엘바이오": "32,400", "298380": "32,400",
	"한화에어로": "324,000", "012450": "324,000",
	"현대로템": "52,800", "064350": "52,800",
	"LIG넥스원": "218,000", "079550": "218,000",
	"한국항공우주": "56,200", "047810": "56,200",
	"풍산": "68,500", "103140": "68,500",
	"쎄트렉아이": "46,800", "099320": "46,800",
	"한화시스템": "19,200", "272210": "19,200",
	"현대위아": "58,500", "011210": "58,500",
	"현대차": "242,000", "005380": "242,000",
	"기아": "104,500", "000270": "104,500",
	"현대모비스": "238,000", "012330": "238,000",
	"한온시스템": "4,120", "018880": "4,120",
	"HL만도": "41,800", "204320": "41,800",

	# US Stocks
	"NVIDIA": "$128.50", "NVDA": "$128.50",
	"Broadcom": "$165.20", "AVGO": "$165.20",
	"AMD": "$148.00",
	"TSMC": "$184.50", "TSM": "$184.50",
	"Micron": "$112.00", "MU": "$112.00",
	"Microsoft": "$428.00", "MSFT": "$428.00",
	"Apple": "$228.50", "AAPL": "$228.50",
	"Alphabet": "$168.00", "GOOGL": "$168.00",
	"Meta": "$578.00", "META": "$578.00",
	"Amazon": "$188.00", "AMZN": "$188.00",
	"Eli Lilly": "$885.00", "LLY": "$885.00",
	"Novo Nordisk": "$124.00", "NVO": "$124.00",
	"AbbVie": "$188.00", "ABBV": "$188.00",
	"Pfizer": "$28.50", "PFE": "$28.50",
	"Merck": "$114.00", "MRK": "$114.00",
	"Tesla": "$258.00", "TSLA": "$258.00",
	"Rivian": "$11.40", "RIVN": "$11.40",
	"Lucid": "$3.25", "LCID": "$3.25",
	"ExxonMobil": "$118.00", "XOM": "$118.00",
	"Chevron": "$152.00", "CVX": "$152.00",
	"JPMorgan": "$218.00", "JPM": "$218.00",
	"Bank of America": "$41.50", "BAC": "$41.50",
	"Visa": "$282.00", "V": "$282.00",
	"Mastercard": "$488.00", "MA": "$488.00",
	"Goldman Sachs": "$495.00", "GS": "$495.00",
	"Lockheed Martin": "$582.00", "LMT": "$582.00",
	"RTX": "$122.00",
	"Boeing": "$154.00", "BA": "$154.00",
	"Northrop": "$520.00", "NOC": "$520.00",
	"General Dynamics": "$295.00", "GD": "$295.00",
	"Walmart": "$82.00", "WMT": "$82.00",
	"Costco": "$890.00", "COST": "$890.00",
	"Netflix": "$720.00", "NFLX": "$720.00",
	"McDonalds": "$298.00", "MCD": "$298.00",
	"HomeDepot": "$395.00", "HD": "$395.00"
}

func get_stock_price(stock: Dictionary) -> String:
	var p = stock.get("price", "")
	if not p.is_empty():
		return p
	var c = stock.get("code", "")
	if DEFAULT_PRICES.has(c):
		return DEFAULT_PRICES[c]
	var n = stock.get("name", "")
	if DEFAULT_PRICES.has(n):
		return DEFAULT_PRICES[n]
	return "75,000" if current_market_type == MarketType.KOREA else "$100.00"

const CACHE_FILE_PATH: String = "user://market_cache.json"

func save_market_cache():
	var cache_data: Dictionary = {
		"updated_at": Time.get_datetime_string_from_system(false, true),
		"stocks": {}
	}
	for sec_key in sectors.keys():
		var sec = sectors[sec_key]
		if sec.has("stocks"):
			for stock in sec["stocks"]:
				var code = stock.get("code", "")
				var name = stock.get("name", "")
				var p = stock.get("price", "")
				var r = stock.get("rate", 0.0)
				var info = {
					"price": p,
					"rate": r,
					"code": code,
					"name": name
				}
				if not code.is_empty():
					cache_data["stocks"][code] = info
				if not name.is_empty():
					cache_data["stocks"][name] = info
	
	var file = FileAccess.open(CACHE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache_data, "\t"))
		file.close()

func load_market_cache():
	if not FileAccess.file_exists(CACHE_FILE_PATH):
		return
	var file = FileAccess.open(CACHE_FILE_PATH, FileAccess.READ)
	if not file:
		return
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return
	var data = json.get_data()
	if not data is Dictionary or not data.has("stocks"):
		return
		
	var cached_stocks = data["stocks"]
	var updated_any = false
	
	for sec_key in sectors.keys():
		var sec = sectors[sec_key]
		if not sec.has("stocks"):
			continue
		
		var total_rate = 0.0
		var stock_count = 0
		var best_rate = -999.0
		var best_stock_name = ""
		
		for stock in sec["stocks"]:
			var code = stock.get("code", "")
			var name = stock.get("name", "")
			var info = null
			if not code.is_empty() and cached_stocks.has(code):
				info = cached_stocks[code]
			elif not name.is_empty() and cached_stocks.has(name):
				info = cached_stocks[name]
			
			if info and info is Dictionary:
				if info.has("price") and not str(info["price"]).is_empty():
					stock["price"] = str(info["price"])
				if info.has("rate"):
					stock["rate"] = float(info["rate"])
				updated_any = true
				
			total_rate += stock["rate"]
			stock_count += 1
			if stock["rate"] > best_rate:
				best_rate = stock["rate"]
				best_stock_name = "%s (%s%.1f%%)" % [stock["name"], "+" if stock["rate"] >= 0 else "", stock["rate"]]
				
		if stock_count > 0:
			sec["change_rate"] = snapped(total_rate / float(stock_count), 0.1)
		if not best_stock_name.is_empty():
			sec["lead_stock"] = best_stock_name
			
	if updated_any:
		var max_rate = -999.0
		var top_sec_key = ""
		for sec_key in sectors.keys():
			sectors[sec_key]["is_top_bull"] = false
			if sectors[sec_key]["change_rate"] > max_rate:
				max_rate = sectors[sec_key]["change_rate"]
				top_sec_key = sec_key
		if not top_sec_key.is_empty():
			sectors[top_sec_key]["is_top_bull"] = true

# Sector and Stock specific news dictionaries
var sector_news_dict: Dictionary = {}
var stock_news_dict: Dictionary = {}
var news_cycle_timer: float = 0.0
var news_cycle_index: int = 0

# Time tracking for player in each sector during a match
var sector_stay_times = {}
var match_total_time: float = 0.0

# Breaking news queue
var news_pool = []
var news_timer: float = 0.0
var next_news_interval: float = 25.0 # Every 25~40s

var fetcher: Node = null
var live_sync_timer: float = 0.0
const LIVE_SYNC_INTERVAL: float = 45.0 # 45초마다 실제 시장 정보 실시간 동기화

func _ready():
	detect_and_set_current_market()
	init_market_data()
	load_market_cache()
	
	# Initialize Live Market Data Fetcher
	var fetcher_script = preload("res://scripts/market_data_fetcher.gd")
	fetcher = fetcher_script.new()
	add_child(fetcher)
	fetcher.rates_updated.connect(_on_live_rates_updated)
	fetcher.news_updated.connect(_on_live_news_updated)
	
	refresh_live_data()

func refresh_live_data():
	if not fetcher:
		return
	var is_kor = (current_market_type == MarketType.KOREA)
	fetcher.fetch_market_stocks(is_kor)
	fetcher.fetch_market_news(is_kor)

func _process(delta: float):
	if Global.is_game_over or Global.is_paused:
		return
		
	match_total_time += delta
	update_stock_cooldowns(delta)
	
	# 실시간 실제 시장 정보 주기적 자동 동기화 (실시간 느낌 강화)
	live_sync_timer += delta
	if live_sync_timer >= LIVE_SYNC_INTERVAL:
		live_sync_timer = 0.0
		refresh_live_data()
	
	# Rotate news headlines every 4.0 seconds for in-world billboards and HUD
	news_cycle_timer += delta
	if news_cycle_timer >= 4.0:
		news_cycle_timer = 0.0
		news_cycle_index += 1
	
	# Periodic news dispatch
	news_timer += delta
	if news_timer >= next_news_interval:
		news_timer = 0.0
		next_news_interval = randf_range(25.0, 45.0)
		trigger_random_breaking_news()

func detect_and_set_current_market():
	var dt = Time.get_datetime_dict_from_system()
	var hour = dt["hour"]
	var weekday = dt["weekday"] # 0: Sunday, 6: Saturday
	
	# Weekend fallback or night check
	if weekday == 0 or weekday == 6:
		current_market_type = MarketType.US
	elif hour >= 9 and hour < 18:
		current_market_type = MarketType.KOREA
	else:
		current_market_type = MarketType.US
		
	apply_market_theme()

func apply_market_theme():
	if current_market_type == MarketType.KOREA:
		market_name = "대한민국 KOSPI / KOSDAQ"
	else:
		market_name = "미국 NASDAQ / S&P500"
		
	# 상승=빨강, 하락=파랑으로 증시 색상 일관성 유지
	Global.is_korean_market_colors = true
	emit_signal("market_mode_changed", market_name, true)
	Global.emit_signal("color_theme_changed", true)

func switch_market(type: MarketType):
	current_market_type = type
	apply_market_theme()
	init_market_data()
	refresh_live_data()

func _on_live_rates_updated(m_type: MarketType, stock_dict: Dictionary):
	if m_type != current_market_type:
		return
		
	print("[MarketDataManager] Live stock data received! Updating sectors...")
	
	# Apply real rates to stocks
	for sec_key in sectors.keys():
		var sec = sectors[sec_key]
		if not sec.has("stocks"):
			continue
			
		var total_rate = 0.0
		var stock_count = 0
		var best_rate = -999.0
		var best_stock_name = ""
		
		for stock in sec["stocks"]:
			var lookup_key = stock.get("code", "")
			if lookup_key.is_empty() or not stock_dict.has(lookup_key):
				lookup_key = stock.get("name", "")
				
			if stock_dict.has(lookup_key):
				var real_info = stock_dict[lookup_key]
				var r = real_info["rate"]
				stock["rate"] = r
				if real_info.has("price"):
					stock["price"] = real_info["price"]
					stock["desc"] = "현재가 %s | 실시간 연동" % real_info["price"]
				total_rate += r
				stock_count += 1
				if r > best_rate:
					best_rate = r
					best_stock_name = "%s (%s%.1f%%)" % [stock["name"], "+" if r >= 0 else "", r]
			else:
				total_rate += stock["rate"]
				stock_count += 1
				
		if stock_count > 0:
			sec["change_rate"] = snapped(total_rate / float(stock_count), 0.1)
		if not best_stock_name.is_empty():
			sec["lead_stock"] = best_stock_name
			
	# Dynamically reassign Top Bull & Worst Bear based on real rates
	var max_rate = -999.0
	var top_sec_key = ""
	for sec_key in sectors.keys():
		sectors[sec_key]["is_top_bull"] = false
		if sectors[sec_key]["change_rate"] > max_rate:
			max_rate = sectors[sec_key]["change_rate"]
			top_sec_key = sec_key
			
	if not top_sec_key.is_empty():
		sectors[top_sec_key]["is_top_bull"] = true
		
	save_market_cache()
	emit_signal("market_mode_changed", market_name, Global.is_korean_market_colors)
	emit_signal("live_rates_applied", m_type)
	Global.market_event_triggered.emit("📡 [실시간 시세 동기화]", "실제 시장 최신 체결가 및 등락률 갱신 완료!")

func _on_live_news_updated(news_list: Array):
	if news_list.is_empty():
		return
	print("[MarketDataManager] Live news received (%d items)!" % news_list.size())
	
	var sector_keywords = {
		# Korea 8 Sectors
		"semiconductor": ["반도체", "하이닉스", "삼성전자", "한미반도체", "hbm", "파운드리", "소부장", "웨이퍼", "hpsp", "리노공업", "이수페타시스", "제주반도체", "가온칩스"],
		"power_grid": ["전력", "변압기", "원전", "원자력", "현대일렉", "두산에너빌", "ls일렉", "ls electric", "효성중공업", "한전kps", "그리드", "배전반", "smr", "일진전기", "우진엔텍", "제룡전기"],
		"robot_ai": ["로봇", "ai", "인공지능", "두산로보", "레인보우", "네이버", "naver", "카카오", "루닛", "의료ai", "협동로봇", "로보티즈", "엔젤로보틱스", "폴라리스ai"],
		"shipbuilding": ["조선", "해운", "선박", "조선해양", "삼성중공업", "한화오션", "현대마린", "hmm", "lng선", "도크", "수주잔고", "flng", "팬오션", "hj중공업", "현대힘스"],
		"battery": ["2차전지", "배터리", "에코프로", "lg에너지", "lg엔솔", "포스코", "리튬", "양극재", "음극재", "전기차", "캐즘", "엔켐", "대주전자재료", "금양"],
		"finance": ["금융", "은행", "지주", "밸류업", "kb금융", "신한지주", "메리츠", "하나금융", "삼성물산", "배당", "자사주", "주주환원", "삼성생명", "미래에셋", "우리금융"],
		"bio": ["바이오", "제약", "신약", "임상", "fda", "알테오젠", "삼성바이오", "셀트리온", "유한양행", "hlb", "sc제형", "adc", "리가켐바이오", "삼천당제약", "에이비엘바이오"],
		"defense": ["방산", "우주", "항공", "k-방산", "한화에어로", "현대로템", "lig넥스원", "한국항공우주", "kai", "풍산", "자주포", "전차", "미사일", "수출", "쎄트렉아이", "한화시스템", "현대위아"],

		# US 8 Sectors
		"ai_chips": ["nvidia", "엔비디아", "broadcom", "브로드컴", "amd", "tsmc", "micron", "마이크론", "gpu", "chip", "semiconductor", "ai chip"],
		"ai_power": ["constellation", "vistra", "oklo", "vernova", "nextera", "smr", "nuclear", "grid", "power", "utility", "전력", "원전"],
		"big_tech": ["microsoft", "마이크로소프트", "apple", "애플", "google", "구글", "alphabet", "meta", "메타", "amazon", "아마존", "cloud"],
		"defense_tech": ["lockheed", "palantir", "팔란티어", "rtx", "northrop", "general dynamics", "defense", "military", "방산", "미사일"],
		"ev_auto": ["tesla", "테슬라", "rivian", "리비안", "lucid", "루시드", "enphase", "albemarle", "ev", "electric vehicle"],
		"wall_street": ["jpmorgan", "goldman", "berkshire", "visa", "blackrock", "bank", "finance", "월가", "버핏", "비트코인 etf"],
		"pharma": ["lilly", "일라이릴리", "novo", "노보노디스크", "abbvie", "애브비", "pfizer", "화이자", "merck", "glp-1", "obesity", "fda"],
		"retail": ["walmart", "costco", "netflix", "mcdonald", "home depot", "retail", "consumer", "월마트", "코스트코", "넷플릭스"]
	}
	
	for item in news_list:
		var item_lower = item.to_lower()
		var matched_sector = ""
		for sec_key in sector_keywords.keys():
			for kw in sector_keywords[sec_key]:
				if item_lower.contains(kw.to_lower()):
					matched_sector = sec_key
					break
			if not matched_sector.is_empty():
				break
				
		if matched_sector.is_empty():
			matched_sector = "semiconductor" if current_market_type == MarketType.KOREA else "ai_chips"
			
		# Match stock news
		for s_name in stock_news_dict.keys():
			if item_lower.contains(s_name.to_lower()):
				if not stock_news_dict[s_name].has(item):
					stock_news_dict[s_name].insert(0, item)
					
		# Match sector news
		if sector_news_dict.has(matched_sector):
			if not sector_news_dict[matched_sector].has(item):
				sector_news_dict[matched_sector].insert(0, item)
				
		var is_buff = ("상승" in item or "돌파" in item or "급등" in item or "수주" in item or "호재" in item or "surge" in item_lower or "rally" in item_lower)
		var is_debuff = ("하락" in item or "급락" in item or "우려" in item or "경고" in item or "쇼크" in item or "crash" in item_lower or "drop" in item_lower)
		news_pool.insert(0, {
			"headline": item,
			"sector": matched_sector,
			"type": "debuff" if is_debuff else "buff",
			"duration": 14.0
		})
	emit_signal("live_news_received", news_list)

const START_POS = Vector2(0, 0)
const CENTER_POS = Vector2(0, 0)

func init_market_data():
	sectors.clear()
	sector_stay_times.clear()
	sector_news_dict.clear()
	stock_news_dict.clear()
	
	if current_market_type == MarketType.KOREA:
		# Korean Market 8 Radial Compass Mega Sectors (Distance ~4800)
		
		# 1. NORTH (0, -4800): AI & Semiconductor Valley
		sectors["semiconductor"] = {
			"key": "semiconductor",
			"name": "반도체 밸리",
			"sub_title": "AI 반도체 & HBM 대장 붉은 숲",
			"direction_hint": "⬆️ 북쪽",
			"position": Vector2(0, -4800),
			"radius": 2400.0,
			"change_rate": 6.8,
			"lead_stock": "한미반도체 (+14.8%)",
			"stocks": [
				{"name": "한미반도체", "code": "042700", "rate": 14.8, "world_pos": Vector2(0, -7200), "desc": "🔥 [상한가 제단] TC본더 독점 수주!"},
				{"name": "SK하이닉스", "code": "000660", "rate": 9.2, "world_pos": Vector2(1300, -6200), "desc": "🚀 [HBM 1위 성역] 5세대 HBM3E 공급"},
				{"name": "삼성전자", "code": "005930", "rate": 4.5, "world_pos": Vector2(-1300, -6200), "desc": "🟢 [국민주 쉼터] 체력 회복 샘물"},
				{"name": "HPSP", "code": "403870", "rate": 8.1, "world_pos": Vector2(700, -4200), "desc": "⚡ 고압수소열처리 독점 공급"},
				{"name": "리노공업", "code": "058470", "rate": 5.4, "world_pos": Vector2(-700, -4200), "desc": "💎 글로벌 테스트 소켓 최강자"},
				{"name": "이수페타시스", "code": "007660", "rate": 11.2, "world_pos": Vector2(1500, -5000), "desc": "🌐 AI 가속기용 다층MLB 기판"},
				{"name": "제주반도체", "code": "080220", "rate": 7.8, "world_pos": Vector2(-1500, -5000), "desc": "📱 온디바이스 AI 저전력 LPDDR 메모리"},
				{"name": "가온칩스", "code": "399720", "rate": 6.2, "world_pos": Vector2(0, -3800), "desc": "📐 AI ASIC 디자인하우스 글로벌 파트너"}
			],
			"theme_color": Color(1.0, 0.2, 0.2, 0.25),
			"is_top_bull": true
		}

		# 2. NORTH-EAST (3400, -3400): Power Grid & Nuclear Energy
		sectors["power_grid"] = {
			"key": "power_grid",
			"name": "전력망 & 원전",
			"sub_title": "AI 전력 쇼티지 & 체코 원전 르네상스",
			"direction_hint": "↗️ 북동",
			"position": Vector2(3400, -3400),
			"radius": 2400.0,
			"change_rate": 9.2,
			"lead_stock": "HD현대일렉트릭 (+13.5%)",
			"stocks": [
				{"name": "HD현대일렉트릭", "code": "026720", "rate": 13.5, "world_pos": Vector2(3400, -4900), "desc": "⚡ [변압기 제왕] 북미 초고압 변압기 품귀"},
				{"name": "두산에너빌리티", "code": "034020", "rate": 8.8, "world_pos": Vector2(4400, -3400), "desc": "☢️ 체코 원전 주기기 & 차세대 SMR"},
				{"name": "LS ELECTRIC", "code": "010120", "rate": 7.6, "world_pos": Vector2(3400, -2200), "desc": "🔌 AI 데이터센터 배전 시스템 수주"},
				{"name": "효성중공업", "code": "298040", "rate": 11.2, "world_pos": Vector2(2400, -3400), "desc": "🏭 미국 초고압 변압기 팩토리 풀가동"},
				{"name": "한전KPS", "code": "051600", "rate": 4.2, "world_pos": Vector2(4200, -4200), "desc": "🛠️ 원자력 및 화력 발전 정비 독점"},
				{"name": "일진전기", "code": "103590", "rate": 8.5, "world_pos": Vector2(2400, -4400), "desc": "⚡ 초고압 변압기 & 송전선로 북미 대량 수주"},
				{"name": "우진엔텍", "code": "457550", "rate": 5.9, "world_pos": Vector2(4400, -2400), "desc": "☢️ 원자력 계측제어 설비 정비 원천기술"},
				{"name": "제룡전기", "code": "033100", "rate": 9.1, "world_pos": Vector2(2600, -2400), "desc": "🔌 미국 배전 변압기 100% 수출 잭팟"}
			],
			"theme_color": Color(1.0, 0.45, 0.15, 0.25),
			"is_top_bull": false
		}
		
		# 3. EAST (4800, 0): Robot & AI Tech Park
		sectors["robot_ai"] = {
			"key": "robot_ai",
			"name": "로봇 & AI 파크",
			"sub_title": "지능형 로봇 협동 성장 지대",
			"direction_hint": "➡️ 동쪽",
			"position": Vector2(4800, 0),
			"radius": 2400.0,
			"change_rate": 3.4,
			"lead_stock": "두산로보틱스 (+7.5%)",
			"stocks": [
				{"name": "두산로보틱스", "code": "454910", "rate": 7.5, "world_pos": Vector2(7200, -700), "desc": "🤖 협동로봇 글로벌 점유율"},
				{"name": "레인보우로보", "code": "277810", "rate": 4.1, "world_pos": Vector2(7200, 700), "desc": "🦾 휴머노이드 보행 플랫폼"},
				{"name": "NAVER", "code": "035420", "rate": 3.2, "world_pos": Vector2(5800, -1400), "desc": "🧠 생성형 AI 하이퍼클로바X"},
				{"name": "카카오", "code": "035720", "rate": 1.5, "world_pos": Vector2(5800, 1400), "desc": "💬 국민 메신저 & AI 에이전트"},
				{"name": "루닛", "code": "328130", "rate": 6.8, "world_pos": Vector2(4000, -900), "desc": "🩺 의료 AI 암 조기진단"},
				{"name": "로보티즈", "code": "108490", "rate": 6.7, "world_pos": Vector2(4000, 900), "desc": "🦾 실외 자율주행 배달로봇 & 액추에이터 독점"},
				{"name": "엔젤로보틱스", "code": "455900", "rate": 5.2, "world_pos": Vector2(5000, -1800), "desc": "🦿 웨어러블 재활 보행로봇 의료 상용화"},
				{"name": "폴라리스AI", "code": "039980", "rate": 4.8, "world_pos": Vector2(5000, 1800), "desc": "🧠 생성형 AI 엔터프라이즈 솔루션 공급"}
			],
			"theme_color": Color(1.0, 0.55, 0.2, 0.22),
			"is_top_bull": false
		}

		# 4. SOUTH-EAST (3400, 3400): K-Shipbuilding & Marine Supercycle
		sectors["shipbuilding"] = {
			"key": "shipbuilding",
			"name": "K-조선 & 해운",
			"sub_title": "LNG선 3년 만선 & 슈퍼사이클 파도",
			"direction_hint": "↘️ 남동",
			"position": Vector2(3400, 3400),
			"radius": 2400.0,
			"change_rate": 8.1,
			"lead_stock": "HD현대마린엔진 (+12.3%)",
			"stocks": [
				{"name": "HD한국조선해양", "code": "009540", "rate": 9.6, "world_pos": Vector2(3400, 4900), "desc": "⚓ [글로벌 1위] 친환경 고부가가치 LNG선 도크 만선"},
				{"name": "삼성중공업", "code": "010140", "rate": 6.4, "world_pos": Vector2(4400, 3400), "desc": "🌊 해양 FLNG 독점 수주 릴레이"},
				{"name": "한화오션", "code": "042660", "rate": 8.1, "world_pos": Vector2(3400, 2200), "desc": "🚢 미 해군 MRO 군함 정비 독점 진출"},
				{"name": "HD현대마린엔진", "code": "071970", "rate": 12.3, "world_pos": Vector2(2400, 3400), "desc": "⚙️ 친환경 선박 엔진 공급망 장악"},
				{"name": "HMM", "code": "011200", "rate": 3.5, "world_pos": Vector2(4200, 4200), "desc": "📦 글로벌 해운 운임 지수 반등 수혜"},
				{"name": "팬오션", "code": "028670", "rate": 4.1, "world_pos": Vector2(2400, 4400), "desc": "🚢 글로벌 벌크선 운임 BDI 상승 최대 수혜"},
				{"name": "HJ중공업", "code": "097230", "rate": 5.8, "world_pos": Vector2(4400, 2400), "desc": "⚓ 해군 특수선 및 친환경 컨테이너선 건조"},
				{"name": "현대힘스", "code": "460930", "rate": 7.2, "world_pos": Vector2(2600, 2400), "desc": "🛠️ 선박 곡블록 및 조선 기자재 독점 생산"}
			],
			"theme_color": Color(0.2, 0.7, 0.9, 0.25),
			"is_top_bull": false
		}
		
		# 5. SOUTH (0, 4800): Secondary Battery Mines
		sectors["battery"] = {
			"key": "battery",
			"name": "2차전지 광산",
			"sub_title": "전기차 캐즘 푸른 공매도 빙벽",
			"direction_hint": "⬇️ 남쪽",
			"position": Vector2(0, 4800),
			"radius": 2400.0,
			"change_rate": -5.6,
			"lead_stock": "에코프로비엠 (-7.1%)",
			"stocks": [
				{"name": "에코프로비엠", "code": "247540", "rate": -7.1, "world_pos": Vector2(0, 7200), "desc": "⚠️ [공매도 총본산] 하이니켈 양극재"},
				{"name": "에코프로", "code": "086520", "rate": -6.5, "world_pos": Vector2(-1300, 6200), "desc": "📉 배터리 소재 수직계열화"},
				{"name": "LG에너지솔루션", "code": "373220", "rate": -3.2, "world_pos": Vector2(1300, 6200), "desc": "🧊 글로벌 배터리 셀 제조"},
				{"name": "POSCO홀딩스", "code": "005490", "rate": -4.2, "world_pos": Vector2(-800, 4400), "desc": "⛏️ 염호 리튬 생산 밸류체인"},
				{"name": "포스코퓨처엠", "code": "003670", "rate": -5.8, "world_pos": Vector2(800, 4400), "desc": "📉 양극재/음극재 원가 하락"},
				{"name": "엔켐", "code": "348370", "rate": -4.5, "world_pos": Vector2(-1500, 5000), "desc": "🧪 북미 시장 점유율 1위 전해액 공급망"},
				{"name": "대주전자재료", "code": "078600", "rate": -3.8, "world_pos": Vector2(1500, 5000), "desc": "🔋 고용량 실리콘 음극재 독점 양산"},
				{"name": "금양", "code": "001570", "rate": -6.2, "world_pos": Vector2(0, 3800), "desc": "⛏️ 원통형 4695 배터리 및 리튬 광산 개발"}
			],
			"theme_color": Color(0.2, 0.5, 1.0, 0.28),
			"is_top_bull": false
		}

		# 6. SOUTH-WEST (-3400, 3400): Finance & Value-Up Holdings
		sectors["finance"] = {
			"key": "finance",
			"name": "금융 & 밸류업",
			"sub_title": "자사주 소각 & 고배당 황금 요새",
			"direction_hint": "↙️ 남서",
			"position": Vector2(-3400, 3400),
			"radius": 2400.0,
			"change_rate": 4.5,
			"lead_stock": "메리츠금융지주 (+6.2%)",
			"stocks": [
				{"name": "KB금융", "code": "105560", "rate": 4.8, "world_pos": Vector2(-3400, 4900), "desc": "🏦 [밸류업 대장] 1조원 자사주 매입 소각"},
				{"name": "신한지주", "code": "055550", "rate": 3.9, "world_pos": Vector2(-4400, 3400), "desc": "💰 분기 균등 배당 & 자본 효율 극대화"},
				{"name": "메리츠금융지주", "code": "138040", "rate": 6.2, "world_pos": Vector2(-3400, 2200), "desc": "👑 주주환원율 50% 배당의 제왕"},
				{"name": "하나금융지주", "code": "086790", "rate": 3.5, "world_pos": Vector2(-2400, 3400), "desc": "📈 저PBR 해소 & 글로벌 순이익 증대"},
				{"name": "삼성물산", "code": "028260", "rate": 4.1, "world_pos": Vector2(-4200, 4200), "desc": "🏛️ 지주사 가치 제고 & 자사주 전량 소각"},
				{"name": "삼성생명", "code": "032830", "rate": 5.1, "world_pos": Vector2(-2400, 4400), "desc": "🏛️ 저PBR 0.5배 극저평가 밸류업 보험 대장"},
				{"name": "미래에셋증권", "code": "006800", "rate": 4.3, "world_pos": Vector2(-4400, 2400), "desc": "📈 적극적 자사주 매입 소각 글로벌 금융투자"},
				{"name": "우리금융지주", "code": "316140", "rate": 3.8, "world_pos": Vector2(-2600, 2400), "desc": "💰 분기 배당 확대 및 비은행 포트폴리오 강화"}
			],
			"theme_color": Color(1.0, 0.8, 0.2, 0.25),
			"is_top_bull": false
		}
		
		# 7. WEST (-4800, 0): Bio & Healthcare Lab
		sectors["bio"] = {
			"key": "bio",
			"name": "바이오 랩",
			"sub_title": "신약 임상 완만한 서쪽 숲",
			"direction_hint": "⬅️ 서쪽",
			"position": Vector2(-4800, 0),
			"radius": 2400.0,
			"change_rate": 0.5,
			"lead_stock": "알테오젠 (+8.6%)",
			"stocks": [
				{"name": "알테오젠", "code": "196170", "rate": 8.6, "world_pos": Vector2(-7200, -700), "desc": "💉 피하주사(SC) 플랫폼 독점"},
				{"name": "삼성바이오로직스", "code": "207940", "rate": 1.2, "world_pos": Vector2(-7200, 700), "desc": "🧪 CDMO 글로벌 1위 생산능력"},
				{"name": "셀트리온", "code": "068270", "rate": -0.8, "world_pos": Vector2(-5800, -1400), "desc": "💊 짐펜트라 미국 처방 확대"},
				{"name": "유한양행", "code": "000100", "rate": 4.8, "world_pos": Vector2(-5800, 1400), "desc": "🏆 렉라자 국산 항암신약 FDA 승인"},
				{"name": "HLB", "code": "028300", "rate": -2.1, "world_pos": Vector2(-4000, -900), "desc": "🔬 리보세라닙 간암신약 승인 재도전"},
				{"name": "리가켐바이오", "code": "141080", "rate": 7.4, "world_pos": Vector2(-4000, 900), "desc": "🎯 차세대 ADC 플랫폼 글로벌 빅파마 기술수출"},
				{"name": "삼천당제약", "code": "000250", "rate": 6.8, "world_pos": Vector2(-5000, -1800), "desc": "💊 경구용 GLP-1 비만치료제 글로벌 계약 체결"},
				{"name": "에이비엘바이오", "code": "298380", "rate": 5.5, "world_pos": Vector2(-5000, 1800), "desc": "🧬 뇌혈관장벽(BBB) 셔틀 이중항체 신약 파이프라인"}
			],
			"theme_color": Color(0.25, 0.85, 0.5, 0.2),
			"is_top_bull": false
		}

		# 8. NORTH-WEST (-3400, -3400): K-Defense & Aerospace
		sectors["defense"] = {
			"key": "defense",
			"name": "K-방산 & 우주",
			"sub_title": "자주포·전차·유도무기 글로벌 수출 철옹성",
			"direction_hint": "↖️ 북서",
			"position": Vector2(-3400, -3400),
			"radius": 2400.0,
			"change_rate": 9.0,
			"lead_stock": "한화에어로스페이스 (+12.8%)",
			"stocks": [
				{"name": "한화에어로", "code": "012450", "rate": 12.8, "world_pos": Vector2(-3400, -4900), "desc": "🚀 [수출 대장] K9 자주포 & 천무 다연장 글로벌 싹쓸이"},
				{"name": "현대로템", "code": "064350", "rate": 10.5, "world_pos": Vector2(-4400, -3400), "desc": "🛡️ K2 흑표 전차 폴란드 수주 잭팟"},
				{"name": "LIG넥스원", "code": "079550", "rate": 8.9, "world_pos": Vector2(-3400, -2200), "desc": "🎯 천궁-II 요격 미사일 중동 수출"},
				{"name": "한국항공우주", "code": "047810", "rate": 5.2, "world_pos": Vector2(-2400, -3400), "desc": "✈️ KF-21 양산 돌입 & FA-50 경공격기"},
				{"name": "풍산", "code": "103140", "rate": 7.4, "world_pos": Vector2(-4200, -4200), "desc": "💣 전 세계 탄약 품귀 구리 방산 수혜"},
				{"name": "쎄트렉아이", "code": "099320", "rate": 6.9, "world_pos": Vector2(-2400, -4400), "desc": "🛰️ 초고해상도 지구관측 인공위성 본체·탑재체 독점"},
				{"name": "한화시스템", "code": "272210", "rate": 7.8, "world_pos": Vector2(-4400, -2400), "desc": "📡 AESA 능동위상배열 레이더 & 국방 지휘통제"},
				{"name": "현대위아", "code": "011210", "rate": 4.9, "world_pos": Vector2(-2600, -2400), "desc": "🛡️ 함포·곡사포 전술 화포 체계 및 무인 포탑"}
			],
			"theme_color": Color(0.9, 0.3, 0.5, 0.25),
			"is_top_bull": false
		}
		
		# Sector-specific Curated Live Market News
		sector_news_dict = {
			"semiconductor": [
				"HBM4 및 3nm 초미세 공정 주문 폭증으로 글로벌 팹 가동률 95% 돌파",
				"빅테크 4사 AI 데이터센터 증설 투자(CAPEX) 전년비 +45% 증액 발표",
				"서버용 고대역폭 메모리 D램 및 eSSD 공급 부족에 판가 두 자릿수 인상"
			],
			"power_grid": [
				"미국 노후 전력망 교체 및 AI 데이터센터 전력 소비 10배 폭증... 변압기 수주 3년 밀려",
				"체코 24조 원전 수주 본계약 임박... SMR(소형 모듈 원자로) 파이프라인 가속",
				"구글·MS 등 빅테크, 차세대 원전 및 초고압 전력 인프라와 20년 전력 독점 계약"
			],
			"robot_ai": [
				"국제로봇연맹(IFR): 차세대 산업용 협동로봇 연평균 32% 고성장 전망",
				"국가 AI 전략위원회 출범... 초거대 AI 컴퓨팅 인프라 2조원 전격 투입",
				"피지컬 AI(휴머노이드) 시대 개막... 국내외 완성차 조립 라인 실전 투입"
			],
			"shipbuilding": [
				"글로벌 친환경 LNG선 도크 2028년까지 완전 포화... 신조선가 사상 최고치 경신",
				"미국 해군성 장관 방한, K-조선소 방문 후 함정 MRO 정비 사업 전격 발주",
				"해양 FLNG 초대형 가스선 프로젝트 수주 랠리... 조선 3사 영업익 서프라이즈"
			],
			"battery": [
				"리튬·니켈 원자재 가격 바닥 확인... 양극재 수익성 턴어라운드 분기점",
				"북미·유럽 대규모 ESS(에너지저장장치) 배터리 공급 계약 연쇄 체결",
				"차세대 전고체 배터리 파일럿 라인 가동 및 4680 폼팩터 양산 가속"
			],
			"finance": [
				"정부 밸류업 가이드라인 본격화... 4대 금융지주 자사주 매입 소각 3조원 돌파",
				"배당소득 분리과세 추진 기대감... 은행·증권주 외국인 지분율 70% 근접",
				"사상 최대 분기 순이익 행진 및 주주환원율 40%대 안착으로 배당 매력 폭발"
			],
			"bio": [
				"FDA 글로벌 신약 허가 사상 최다치... K-바이오 플랫폼 기술수출 릴레이",
				"GLP-1 비만/대사질환 치료제 시장 2030년 130조원 규모 초고속 팽창",
				"ADC(항체-약물 접합체) 및 피하주사(SC) 플랫폼 라이선스 계약 쇄도"
			],
			"defense": [
				"K-방산 올해 수출액 200억 달러 돌파... NATO 회원국 수주잔고 100조원 돌파",
				"러시아-우크라이나 및 중동 분쟁 장기화로 K9 자주포·천무 조기 납기 호평",
				"한국형 차세대 전투기 KF-21 최초 양산 계약 체결 및 우주 발사체 민간 이양"
			]
		}
		
		# Stock-specific Financial Headlines & Analyst Commentaries
		stock_news_dict = {
			"한미반도체": [
				"글로벌 1위 HBM 듀얼 TC본더 장비 독점 수주 러시... 공급 부족 심화",
				"AI 가속기 서버 증설로 장비 리드타임 10개월 확대, 분기 최대 영업익",
				"외국인/기관 쌍끌이 순매수 유입... 목표주가 20만원 상향 리포트"
			],
			"SK하이닉스": [
				"5세대 HBM3E 엔비디아 공급 주도권 공고화... 영업이익 사상 최대치",
				"차세대 HBM4 16단 2025년 조기 양산 체제 돌입 발표",
				"서버용 고성능 eSSD 수요 폭발로 낸드 부문 흑자 전환 가속"
			],
			"삼성전자": [
				"HBM3E 12단 퀄 테스트 최종 검증 진입... 하반기 납품 가시화",
				"3나노 2세대 게이트올어라운드(GAA) 공정 수율 안정화 구간 안착",
				"차세대 CXL 및 온디바이스 메모리 시장 선점 속도"
			],
			"HPSP": [
				"고압 수소 어닐링 장비 독점력 유지... 초미세 공정 필수재 입지",
				"글로벌 톱10 파운드리 중 8곳에 양산 장비 공급 완료"
			],
			"리노공업": [
				"온디바이스 AI 칩 다변화로 리노핀 및 테스트소켓 주문 급증",
				"영업이익률 40%대 초고수익성 반도체 소부장 대장주 굳건"
			],
			"이수페타시스": [
				"AI 가속기용 초고다층 MLB(인쇄회로기판) 제4공장 풀가동",
				"북미 빅테크향 고다층 기판 독점 공급으로 분기 최대 실적"
			],
			"HD현대일렉트릭": [
				"북미 초고압 변압기 수주잔고 5조원 돌파... 공장 3년치 일감 완판",
				"영업이익률 20%대 초고수익 달성... 글로벌 전력망 대장주 위상"
			],
			"두산에너빌리티": [
				"체코 24조 원전 수주 주기기 제작 착수... SMR 파운드리 본격화",
				"가스터빈 국산화 1호기 상업운전 돌입 및 수소혼소 개발 순항"
			],
			"LS ELECTRIC": [
				"북미 AI 데이터센터 배전 솔루션 공급 계약 1조원 돌파",
				"초고압 직류송전(HVDC) 변환용 변압기 글로벌 수주 가속"
			],
			"효성중공업": [
				"미국 테네시 변압기 공장 풀가동... 북미 시장점유율 급상승",
				"유럽 초고압 전력망 프로젝트 연쇄 수주로 실적 턴어라운드"
			],
			"한전KPS": [
				"국내외 원자력 발전소 정비 단독 수행으로 독점적 현금흐름 창출",
				"해외 원전 수출 프로젝트 가동 시 경상정비 매출 대폭 성장"
			],
			"두산로보틱스": [
				"북미 식음료 및 물류 자동화 협동로봇 솔루션 대규모 공급 계약",
				"소프트웨어 플랫폼 '다트스위트' 결합으로 로봇 생태계 확장"
			],
			"레인보우로보": [
				"양팔형 이동 매니퓰레이터 및 휴머노이드 상용화 박차",
				"삼성전자 제조공장 협동로봇 자동화 라인 실전 투입 확대"
			],
			"NAVER": [
				"생성형 AI 하이퍼클로바X B2B 엔터프라이즈 솔루션 수주 가속",
				"검색 및 커머스 AI 타겟팅 고도화로 광고 클릭률 30% 개선"
			],
			"카카오": [
				"카카오톡 신규 AI 에이전트 서비스 '카나나' 생태계 론칭",
				"모빌리티 및 페이 흑자 기조 안착 및 주주환원 확대 발표"
			],
			"루닛": [
				"루닛 인사이트 AI 암 진단 솔루션 글로벌 3000개 병원 도입 돌파",
				"미국 캔서X 프로젝트 핵심 파트너사로 AI 바이오마커 공동 개발"
			],
			"HD한국조선해양": [
				"올해 수주 목표 140% 조기 초과 달성... 고가 LNG선 선별 수주",
				"암모니아·메탄올 친환경 이중연료 추진선 시장 70% 장악"
			],
			"삼성중공업": [
				"해양 FLNG(부유식 LNG 생산설비) 글로벌 시장 사실상 독점 체제",
				"연간 영업이익 4000억원 돌파... 10년 만의 최대 흑자 사이클"
			],
			"한화오션": [
				"미 해군 군수지원함 창정비(MRO) 국내 최초 수주 성공",
				"잠수함 및 수상함 특수선 방산 라인업 글로벌 수출 추진"
			],
			"HD현대마린엔진": [
				"친환경 선박 엔진 공급망 일원화로 마진율 두 자릿수 도약",
				"선박 애프터마켓(AM) 부품 매출 확대로 안정적 수익 확보"
			],
			"HMM": [
				"상하이컨테이너운임지수(SCFI) 고공행진에 분기 1조 흑자",
				"초대형 친환경 컨테이너선단 확충 및 물류 다변화"
			],
			"에코프로비엠": [
				"하이니켈 양극재 고객사 재고 소진 후 출하량 반등 모색",
				"현대차·기아 및 북미 완성차향 중저가 LFP 양극재 라인 증설"
			],
			"에코프로": [
				"포항 블루밸리 캠퍼스 리튬·전구체 수직 계열화 효율화 달성",
				"폐배터리 리사이클링 핵심 원자재 추출 원가 경쟁력 우위"
			],
			"LG에너지솔루션": [
				"차세대 4680 원통형 배터리 3분기 양산 본격화",
				"글로벌 완성차 합작공장(JV) 가동률 회복 및 대규모 ESS 수주"
			],
			"POSCO홀딩스": [
				"아르헨티나 옴브레 무에르토 염호 1단계 수산화리튬 준공 가동",
				"친환경 미래소재 풀 밸류체인 구축으로 원자재 사이클 턴어라운드"
			],
			"포스코퓨처엠": [
				"고성능 단결정 양극재 공급 확대 및 음극재 국산화 선도",
				"GM 합작 얼티엄캠 캐나다 양극재 공장 시운전 성공"
			],
			"KB금융": [
				"총주주환원율 40% 공식 선언... 자사주 1조원 매입 소각",
				"비이자이익 포트폴리오 다변화로 사상 최대 5조원 순익 전망"
			],
			"신한지주": [
				"분기 균등 배당 도입으로 주주 가치 극대화",
				"글로벌 사업 부문 순이익 1조원 돌파... 자본적정성 최상위"
			],
			"메리츠금융지주": [
				"당기순이익 50% 주주환원 원칙 철저 이행... 한국판 버크셔",
				"화재·증권 통합 원메리츠 시너지로 ROE 25% 업계 최고"
			],
			"하나금융지주": [
				"주가순자산비율(PBR) 0.4배 극심한 저평가 해소 밸류업 계획 발표",
				"중간배당 및 자사주 소각 규모 대폭 확대"
			],
			"삼성물산": [
				"보유 자사주 전량 소각 발표... 주주가치 제고 리더십",
				"건설·바이오·상사 삼각편대 호실적으로 배당 재원 확대"
			],
			"알테오젠": [
				"MSD 키트루다 피하주사(SC) 독점 라이선스 변경 계약 마일스톤 유입",
				"글로벌 빅파마 5곳과 피하주사 제형 변경 플랫폼 기술수출 협상"
			],
			"삼성바이오로직스": [
				"송도 제5공장 조기 가동 추진... 글로벌 1위 78.4만 리터 생산력",
				"글로벌 빅파마 20곳 중 16곳 고객사 확보, 수주잔고 16조원 돌파"
			],
			"셀트리온": [
				"미국 출시 피하주사제 '짐펜트라' 대형 PBM 처방집 80% 이상 등재",
				"유플라이마·베그젤마 등 후속 바이오시밀러 유럽 점유율 1위"
			],
			"유한양행": [
				"국산 항암신약 최초 '렉라자' 미국 FDA 1차 치료제 최종 승인",
				"글로벌 얀센과 리브리반트 병용요법으로 마일스톤 800억원 수령"
			],
			"HLB": [
				"간암 신약 리보세라닙+캄렐리주맙 병용요법 FDA 재승인 서류 제출 완료",
				"글로벌 임상 3상 데이터 미국 종합암네트워크(NCCN) 가이드라인 권고"
			],
			"한화에어로": [
				"폴란드·루마니아 K9 자주포 및 천무 30조원 수주잔고 확보",
				"누리호 4호기 고도화 총괄 주관 및 차세대 발사체 사업자 선정"
			],
			"현대로템": [
				"폴란드 K2 흑표 전차 2차 계약 8조원 체결 임박",
				"루마니아 및 중동 전차 수출 협상 가속화... 방산 매출 비중 70%"
			],
			"LIG넥스원": [
				"사우디·이라크 천궁-II 7조원 중동 방공망 수출 독점",
				"미국 고스트로보틱스 인수로 사족보행 로봇 국방 솔루션 진출"
			],
			"한국항공우주": [
				"KF-21 보라매 공군 1차 양산 계약 2조원 전격 체결",
				"FA-50 경공격기 폴란드·말레이시아 수출 물량 순차 인도"
			],
			"풍산": [
				"글로벌 155mm 포탄 재고 고갈로 탄약 수출 판가 급등",
				"구리 가격 상승과 방산 부문 최대 마진으로 역대급 실적"
			],
			"제주반도체": [
				"글로벌 팹리스 온디바이스 AI 저전력 LPDDR 메모리 독점 공급",
				"퀄컴·미디어텍 5G IoT 칩셋 공식 인증 및 매출 급성장"
			],
			"가온칩스": [
				"일본·미국 빅테크향 첨단 AI ASIC 디자인하우스 프로젝트 잇단 수주",
				"삼성 파운드리 및 ARM 토탈 디자인 핵심 파트너십 강화"
			],
			"일진전기": [
				"미국 대형 유틸리티향 500kV 초고압 변압기 4000억 수주",
				"HVDC 초고압 해저케이블 및 지중 송전선로 공장 풀가동"
			],
			"우진엔텍": [
				"체코·폴란드 한국형 원전 수출 정비 및 계측제어 공급 계약",
				"원전 해체 핵심 기술 확보 및 국가 전략과제 총괄"
			],
			"제룡전기": [
				"북미 지상 변압기 PAD 쇼티지로 수출 비중 85% 역대 최대 마진",
				"미국 배전망 노후화 교체 사이클로 2년치 일감 확보"
			],
			"로보티즈": [
				"실외 이동로봇 규제 완화 수혜... 자율주행 배달로봇 지능형 양산",
				"로봇 전용 다이나믹셀 액추에이터 글로벌 로봇 기업 80% 탑재"
			],
			"엔젤로보틱스": [
				"웨어러블 보행 재활 로봇 엔젤메디 상급종합병원 처방 확대",
				"산업용 근력보조 슈트 엔젤기어 현대차·CJ 등 대기업 공급"
			],
			"폴라리스AI": [
				"공공·금융 엔터프라이즈 생성형 AI 거대언어모델(LLM) 공급",
				"자체 AI 오피스 문서 솔루션 구독자 100만 돌파"
			],
			"팬오션": [
				"글로벌 원자재 물동량 회복... 발틱건화물지수(BDI) 급반등 호재",
				"친환경 LNG 벙커링선 및 초대형 벌크선 장기 대선 계약 체결"
			],
			"HJ중공업": [
				"해군 차기고속정 및 해경 경비함 등 특수선 방산 수주 독점",
				"친환경 메탄올 추진 컨테이너선 연속 건조 도크 확보"
			],
			"현대힘스": [
				"조선 빅3 선박 블록 물량 쏟아지며 도크 풀가동 및 단가 인상",
				"선박 독립형 곡블록 생산능력 국내 1위... 영업이익률 20% 돌파"
			],
			"엔켐": [
				"북미 조지아·테네시 배터리 공장향 전해액 단독 공급망 선점",
				"미국 IRA 해외우려기관(FEOC) 규제 최대 수혜로 시장점유율 1위"
			],
			"대주전자재료": [
				"글로벌 완성차 포르쉐·현대차 탑재 실리콘 음극재 독점 납품",
				"실리콘 함량 15% 차세대 배터리 소재 대량 양산 가동"
			],
			"금양": [
				"부산 기장 4695 원통형 배터리 드림팩토리 2공장 준공 임박",
				"몽골 몬라 리튬 광산 채굴 및 정제 가공 밸류체인 가시화"
			],
			"삼성생명": [
				"기업 밸류업 프로그램 최대 수혜... PBR 0.5배 저평가 매력",
				"삼성전자 등 보유 지분 가치 대비 역대급 자사주 소각 기대감"
			],
			"미래에셋증권": [
				"주주환원율 35% 달성... 보통주 1000만주 이상 소각 지속",
				"해외 주식 예탁자산 30조 돌파 및 글로벌 브로커리지 수익 1위"
			],
			"우리금융지주": [
				"동양생명·ABL생명 인수로 비은행 포트폴리오 완성 및 배당 매력",
				"보통주 자본비율(CET1) 12% 조기 달성 및 분기 배당 확대"
			],
			"리가켐바이오": [
				"얀센 대상 2.2조원 ADC 후보물질 기술수출 계약금 수령",
				"차세대 항체-약물접합체(ADC) 링커 플랫폼 글로벌 독점 공급"
			],
			"삼천당제약": [
				"경구용 GLP-1 비만치료제 서구권 5개국 독점 판매 계약",
				"아일리아 바이오시밀러 유럽 공급 승인 및 캐시카우 확보"
			],
			"에이비엘바이오": [
				"그랩바디-B 플랫폼 기반 뇌혈관장벽(BBB) 통과 파킨슨병 신약 임상",
				"사노피 대상 추가 마일스톤 달성 및 다국적 제약사 기술이전 협상"
			],
			"쎄트렉아이": [
				"초고해상도 지구관측 위성 스페이스아이-T 발사 및 상용화",
				"한화에어로스페이스와 우주 밸류체인 구축 및 국방 감시위성 독점"
			],
			"한화시스템": [
				"한국형 차세대 전투기 KF-21 AESA 능동위상배열 레이더 양산",
				"우주 저궤도 위성통신망 및 다기능 레이다 해외 수출 잭팟"
			],
			"현대위아": [
				"K2 전차 주포 및 K9 자주포 무장 체계 독점 제작 납품",
				"모빌리티 로봇 및 전기차 열관리 시스템 방산-민수 융합 시너지"
			]
		}
		
		news_pool = [
			{"headline": "📢 [속보] 북쪽 반도체 밸리로 전진하세요! 엔비디아 대량 수주 체결!", "sector": "semiconductor", "type": "buff", "duration": 15.0},
			{"headline": "⚡ [속보] 북동쪽 전력망·원전에 미 빅테크 러브콜! 변압기 완판 폭등!", "sector": "power_grid", "type": "buff", "duration": 15.0},
			{"headline": "🚢 [속보] 남동쪽 K-조선 도크 만선! 미 해군 MRO 수주 잭팟!", "sector": "shipbuilding", "type": "buff", "duration": 15.0},
			{"headline": "🚀 [속보] 북서쪽 K-방산 유럽·중동 무기 수출 릴레이! 주가 사상 최고치!", "sector": "defense", "type": "buff", "duration": 15.0},
			{"headline": "💰 [속보] 남서쪽 금융·밸류업 조 단위 자사주 전격 소각! 고배당 랠리!", "sector": "finance", "type": "buff", "duration": 15.0},
			{"headline": "⚠️ [경고] 남쪽 2차전지 광산에 공매도 세력 대규모 급습! 진입 주의!", "sector": "battery", "type": "debuff", "duration": 15.0},
			{"headline": "💉 [속보] 서쪽 바이오 랩 알테오젠 SC 제형 독점 수주 랠리!", "sector": "bio", "type": "buff", "duration": 12.0},
			{"headline": "🤖 [속보] 동쪽 로봇 파크 협동로봇 국책 과제 선정! 성장 가속!", "sector": "robot_ai", "type": "buff", "duration": 12.0}
		]
		
	else:
		# US Market 8 Radial Compass Mega Sectors (Distance ~4800)
		
		# 1. NORTH (0, -4800): Silicon Valley AI Chip Giants
		sectors["ai_chips"] = {
			"key": "ai_chips",
			"name": "실리콘밸리 AI 칩",
			"sub_title": "GPU 가속 컴퓨팅 황금 본류",
			"direction_hint": "⬆️ 북쪽",
			"position": Vector2(0, -4800),
			"radius": 2400.0,
			"change_rate": 11.4,
			"lead_stock": "NVIDIA (+14.2%)",
			"stocks": [
				{"name": "NVIDIA", "code": "NVDA", "rate": 14.2, "world_pos": Vector2(0, -7200), "desc": "🔥 [NVDA 떡상 정상] 블랙웰 주문 폭주!"},
				{"name": "Broadcom", "code": "AVGO", "rate": 8.5, "world_pos": Vector2(1300, -6200), "desc": "🚀 커스텀 ASIC 칩 호실적"},
				{"name": "AMD", "code": "AMD", "rate": 5.8, "world_pos": Vector2(-1300, -6200), "desc": "MI300X 가속기 공급 확대"},
				{"name": "TSMC", "code": "TSM", "rate": 7.2, "world_pos": Vector2(700, -4200), "desc": "3나노 파운드리 풀가동"},
				{"name": "Micron", "code": "MU", "rate": 9.0, "world_pos": Vector2(-700, -4200), "desc": "HBM 메모리 품귀 공급"}
			],
			"theme_color": Color(0.2, 1.0, 0.4, 0.28),
			"is_top_bull": true
		}

		# 2. NORTH-EAST (3400, -3400): AI Power Grid & SMR Nuclear
		sectors["ai_power"] = {
			"key": "ai_power",
			"name": "AI 전력망 & SMR",
			"sub_title": "빅테크 데이터센터 전력 품귀 랠리",
			"direction_hint": "↗️ 북동",
			"position": Vector2(3400, -3400),
			"radius": 2400.0,
			"change_rate": 13.8,
			"lead_stock": "Oklo (+18.6%)",
			"stocks": [
				{"name": "Constellation", "code": "CEG", "rate": 15.2, "world_pos": Vector2(3400, -4900), "desc": "☢️ [MS 20년 PPA] 스리마일 원전 재가동"},
				{"name": "Vistra", "code": "VST", "rate": 12.4, "world_pos": Vector2(4400, -3400), "desc": "⚡ AI 데이터센터 전력 공급 연초대비 250% 폭등"},
				{"name": "Oklo", "code": "OKLO", "rate": 18.6, "world_pos": Vector2(3400, -2200), "desc": "🔥 샘 올트먼의 차세대 SMR 고속로 핵분열"},
				{"name": "GE Vernova", "code": "GEV", "rate": 9.1, "world_pos": Vector2(2400, -3400), "desc": "🏭 가스터빈 및 전력 그리드 장비 독점"},
				{"name": "NextEra", "code": "NEE", "rate": 4.5, "world_pos": Vector2(4200, -4200), "desc": "🔋 대규모 신재생 및 ESS 유틸리티 1위"}
			],
			"theme_color": Color(1.0, 0.65, 0.1, 0.26),
			"is_top_bull": false
		}
		
		# 3. EAST (4800, 0): Big Tech Magnificent 7
		sectors["big_tech"] = {
			"key": "big_tech",
			"name": "매그니피센트 테크",
			"sub_title": "클라우드 & 스마트 디바이스 대로",
			"direction_hint": "➡️ 동쪽",
			"position": Vector2(4800, 0),
			"radius": 2400.0,
			"change_rate": 2.6,
			"lead_stock": "Microsoft (+3.1%)",
			"stocks": [
				{"name": "Microsoft", "code": "MSFT", "rate": 3.1, "world_pos": Vector2(7200, -700), "desc": "Copilot 기업용 라이선스 증가"},
				{"name": "Apple", "code": "AAPL", "rate": 1.8, "world_pos": Vector2(7200, 700), "desc": "Apple Intelligence 기기 교체"},
				{"name": "Alphabet", "code": "GOOGL", "rate": 2.5, "world_pos": Vector2(5800, -1400), "desc": "Gemini AI 모델 검색 탑재"},
				{"name": "Meta", "code": "META", "rate": 4.2, "world_pos": Vector2(5800, 1400), "desc": "Llama 3 AI 오픈소스 생태계"},
				{"name": "Amazon", "code": "AMZN", "rate": 2.9, "world_pos": Vector2(4000, 0), "desc": "AWS 클라우드 인프라 매출 가속"}
			],
			"theme_color": Color(0.4, 0.8, 1.0, 0.22),
			"is_top_bull": false
		}

		# 4. SOUTH-EAST (3400, 3400): Defense Tech & Military AI
		sectors["defense_tech"] = {
			"key": "defense_tech",
			"name": "국방 AI & 방산",
			"sub_title": "전장 AI 지휘소 & 스텔스 군수 복합체",
			"direction_hint": "↘️ 남동",
			"position": Vector2(3400, 3400),
			"radius": 2400.0,
			"change_rate": 6.2,
			"lead_stock": "Palantir (+14.6%)",
			"stocks": [
				{"name": "Palantir", "code": "PLTR", "rate": 14.6, "world_pos": Vector2(3400, 4900), "desc": "🧠 [AIP 랠리] 미 국방부 전장 AI 플랫폼 독점"},
				{"name": "Lockheed", "code": "LMT", "rate": 4.2, "world_pos": Vector2(4400, 3400), "desc": "🛩️ F-35 스텔스 전투기 & 국방 예산 최대 수혜"},
				{"name": "RTX", "code": "RTX", "rate": 3.8, "world_pos": Vector2(3400, 2200), "desc": "🛡️ 패트리어트 미사일 & 항공기 엔진"},
				{"name": "Northrop", "code": "NOC", "rate": 4.9, "world_pos": Vector2(2400, 3400), "desc": "🦅 B-21 차세대 스텔스 전략 폭격기"},
				{"name": "GeneralDynamics", "code": "GD", "rate": 3.1, "world_pos": Vector2(4200, 4200), "desc": "🚢 버지니아급 원자력 잠수함 제조"}
			],
			"theme_color": Color(0.3, 0.75, 0.7, 0.25),
			"is_top_bull": false
		}
		
		# 5. SOUTH (0, 4800): EV Price War Bear Crash
		sectors["ev_auto"] = {
			"key": "ev_auto",
			"name": "전기차 & 기가팩토리",
			"sub_title": "가격 인하 치킨게임 푸른 폭락 지대",
			"direction_hint": "⬇️ 남쪽",
			"position": Vector2(0, 4800),
			"radius": 2400.0,
			"change_rate": -6.4,
			"lead_stock": "Tesla (-7.8%)",
			"stocks": [
				{"name": "Tesla", "code": "TSLA", "rate": -7.8, "world_pos": Vector2(0, 7200), "desc": "⚠️ 마진 쇼크 음봉 투하"},
				{"name": "Rivian", "code": "RIVN", "rate": -8.5, "world_pos": Vector2(1200, 6200), "desc": "인도량 부진 현금 소진"},
				{"name": "Lucid", "code": "LCID", "rate": -9.2, "world_pos": Vector2(-1200, 6200), "desc": "고가 전기차 수요 둔화"},
				{"name": "Enphase", "code": "ENPH", "rate": -5.4, "world_pos": Vector2(800, 4400), "desc": "태양광 인버터 수요 위축"},
				{"name": "Albemarle", "code": "ALB", "rate": -6.1, "world_pos": Vector2(-800, 4400), "desc": "글로벌 리튬 판가 급락"}
			],
			"theme_color": Color(0.2, 0.5, 1.0, 0.28),
			"is_top_bull": false
		}

		# 6. SOUTH-WEST (-3400, 3400): Wall Street Mega Banks & Fintech
		sectors["wall_street"] = {
			"key": "wall_street",
			"name": "월가 메가뱅크",
			"sub_title": "금리 피벗 & 사상 최대 자산운용 수수료",
			"direction_hint": "↙️ 남서",
			"position": Vector2(-3400, 3400),
			"radius": 2400.0,
			"change_rate": 3.8,
			"lead_stock": "Goldman Sachs (+4.8%)",
			"stocks": [
				{"name": "JPMorgan", "code": "JPM", "rate": 3.6, "world_pos": Vector2(-3400, 4900), "desc": "🏛️ [월가 제왕] 제이미 다이먼의 사상 최대 순익"},
				{"name": "Goldman Sachs", "code": "GS", "rate": 4.8, "world_pos": Vector2(-4400, 3400), "desc": "💼 글로벌 IB 인수합병 M&A 딜 회복"},
				{"name": "Berkshire", "code": "BRK.B", "rate": 2.4, "world_pos": Vector2(-3400, 2200), "desc": "📈 버핏의 3000억 달러 현금성 자산 요새"},
				{"name": "Visa", "code": "V", "rate": 2.8, "world_pos": Vector2(-2400, 3400), "desc": "💳 글로벌 디지털 결제 수수료 독점 캐시카우"},
				{"name": "BlackRock", "code": "BLK", "rate": 5.1, "world_pos": Vector2(-4200, 4200), "desc": "🪙 비트코인 현물 ETF 1위 & 10조달러 운용"}
			],
			"theme_color": Color(0.9, 0.75, 0.2, 0.24),
			"is_top_bull": false
		}
		
		# 7. WEST (-4800, 0): Healthcare & GLP-1
		sectors["pharma"] = {
			"key": "pharma",
			"name": "글로벌 헬스케어",
			"sub_title": "GLP-1 비만치료제 서쪽 숲",
			"direction_hint": "⬅️ 서쪽",
			"position": Vector2(-4800, 0),
			"radius": 2400.0,
			"change_rate": 3.8,
			"lead_stock": "Eli Lilly (+5.4%)",
			"stocks": [
				{"name": "Eli Lilly", "code": "LLY", "rate": 5.4, "world_pos": Vector2(-7200, -700), "desc": "마운자로 공급 품귀 지속"},
				{"name": "Novo Nordisk", "code": "NVO", "rate": 4.2, "world_pos": Vector2(-7200, 700), "desc": "위고비 글로벌 처방 확대"},
				{"name": "AbbVie", "code": "ABBV", "rate": 2.1, "world_pos": Vector2(-5800, -1400), "desc": "면역학 치료제 특허 방어"},
				{"name": "Pfizer", "code": "PFE", "rate": -1.2, "world_pos": Vector2(-5800, 1400), "desc": "코로나 백신 기저효과 둔화"},
				{"name": "Merck", "code": "MRK", "rate": 2.5, "world_pos": Vector2(-4000, 0), "desc": "키트루다 항암제 글로벌 1위 매출"}
			],
			"theme_color": Color(0.2, 0.9, 0.6, 0.22),
			"is_top_bull": false
		}

		# 8. NORTH-WEST (-3400, -3400): Retail & Consumer Titans
		sectors["retail"] = {
			"key": "retail",
			"name": "리테일 & 소비재",
			"sub_title": "탄탄한 미국 내수 소비 & 경기방어주 요새",
			"direction_hint": "↖️ 북서",
			"position": Vector2(-3400, -3400),
			"radius": 2400.0,
			"change_rate": 3.9,
			"lead_stock": "Netflix (+6.8%)",
			"stocks": [
				{"name": "Walmart", "code": "WMT", "rate": 3.2, "world_pos": Vector2(-3400, -4900), "desc": "🛒 [유통 황제] 전자상거래 고성장 & 사상 최고가"},
				{"name": "Costco", "code": "COST", "rate": 4.5, "world_pos": Vector2(-4400, -3400), "desc": "📦 충성 유료 멤버십 기반 마르지 않는 현금흐름"},
				{"name": "Netflix", "code": "NFLX", "rate": 6.8, "world_pos": Vector2(-3400, -2200), "desc": "🍿 글로벌 OTT 독점 & 광고형 요금제 흑자"},
				{"name": "McDonalds", "code": "MCD", "rate": 1.8, "world_pos": Vector2(-2400, -3400), "desc": "🍔 전 세계 4만 개 매장 글로벌 경기방어주"},
				{"name": "HomeDepot", "code": "HD", "rate": 2.9, "world_pos": Vector2(-4200, -4200), "desc": "🏠 주택 개보수 및 인프라 소비 회복"}
			],
			"theme_color": Color(0.85, 0.4, 0.75, 0.22),
			"is_top_bull": false
		}
		
		# US Sector News
		sector_news_dict = {
			"ai_chips": [
				"Blackwell GPU 수요 폭발로 2025년 공급 완판... 빅테크 주문 쟁탈전",
				"빅테크 4사 AI 데이터센터 CAPEX 투자액 2000억 달러 사상 최고치",
				"3nm 최선단 파운드리 및 2.5D 첨단 패키징 라인 100% 가동률 기록"
			],
			"ai_power": [
				"AI 데이터센터 전력 소비 10배 폭증으로 미국 전력주 연초 대비 200% 폭등",
				"원자력 규제 위원회(NRC), 차세대 소형 모듈 원자로(SMR) 설계 승인 가속",
				"마이크로소프트·아마존, 원전 기업과 사상 최초 20년 무탄소 전력 직거래 계약"
			],
			"big_tech": [
				"빅3 클라우드(AWS·Azure·GCP) AI 결합 워크로드 매출 30% 급증",
				"온디바이스 AI 스마트폰 및 AI 에이전트 교체 슈퍼사이클 본격화",
				"빅테크 자체 ASIC AI 가속기 칩 내재화 확대로 마진 방어"
			],
			"defense_tech": [
				"미 국방부 차세대 전장 AI 통합 지휘 시스템(CJADC2) 조 단위 예산 집행",
				"글로벌 지정학 위기 심화로 NATO 방위비 지출 GDP 2% 의무화 압박",
				"스텔스 전투기·무인 편대기(CCA) 자율비행 AI 소프트웨어 테스트 성공"
			],
			"ev_auto": [
				"글로벌 전기차 가격 인하 경쟁 완화... 마진율 저점 통과 기대",
				"유럽 및 북미 대규모 ESS(에너지저장장치) 배터리 수요 급증",
				"자율주행 FSD 완전 무인 로보택시 시범 운행 승인 추진"
			],
			"wall_street": [
				"연준 금리 인하 사이클 진입... M&A 자문 수수료 및 주식 발행(IPO) 시장 부활",
				"월가 대형 은행들 사상 최대 예대마진 및 비트코인 수탁 자산 폭증",
				"버크셔 해서웨이 사상 최초 시가총액 1조 달러 돌파... 가치투자 승리"
			],
			"pharma": [
				"GLP-1 비만 치료제 시장 글로벌 처방 급증... 생산 설비 4배 증설",
				"경구용(먹는) 차세대 비만약 임상 3상 데이터 호조 기대감 고조",
				"글로벌 빅파마 ADC 및 이중항체 바이오텍 M&A 인수전 치열"
			],
			"retail": [
				"미국 견조한 고용 지표와 탄탄한 소비자 지출로 리테일 실적 서프라이즈",
				"월마트 전자상거래 매출 22% 급증... 아마존과의 이커머스 격차 축소",
				"넷플릭스 유료 구독자 분기 순증 사상 최대치... 오징어 게임2 흥행 기대"
			]
		}
		
		# US Stock News
		stock_news_dict = {
			"NVIDIA": [
				"블랙웰(Blackwell) B200 칩 공급 부족 지속... 빅테크 주문 폭주",
				"AI 슈퍼클러스터 데이터센터 매출 전년비 150% 폭증"
			],
			"Broadcom": [
				"빅테크 커스텀 AI ASIC 칩 및 이더넷 스위치 매출 300% 폭증",
				"VMware 클라우드 통합으로 고마진 소프트웨어 현금흐름 창출"
			],
			"AMD": [
				"MI300X AI 가속기 마이크로소프트 및 메타 채택 가속화",
				"차세대 AI GPU 로드맵 공개... 엔비디아 대항마 입지 강화"
			],
			"TSMC": [
				"3나노 및 2나노 최선단 파운드리 공정 웨이퍼 판가 인상 합의",
				"CoWoS 첨단 패키징 생산 능력 2배 증설 완료"
			],
			"Micron": [
				"HBM3E 메모리 2025년 생산 물량 완판 기록",
				"서버용 고용량 DDR5 및 SSD 판가 급등으로 실적 어닝서프라이즈"
			],
			"Constellation": [
				"마이크로소프트와 3마일 아일랜드 원전 1호기 20년 재가동 전력 계약 체결",
				"미국 최대 원자력 발전사로 빅테크 PPA 수주 독점"
			],
			"Vistra": [
				"텍사스 및 동부 데이터센터 전력 공급 계약 쇄도로 주가 연초 대비 3배 폭등",
				"천연가스 및 원자력 포트폴리오를 갖춘 고수익 독립 발전사"
			],
			"Oklo": [
				"샘 올트먼 지원 차세대 소형 모듈 원자로(SMR) 데이터센터 상용화 가속",
				"미 에너지부(DOE) 오로라 고속로 핵연료 재활용 승인"
			],
			"GE Vernova": [
				"AI 데이터센터 전력 백업용 가스터빈 수주잔고 1000억 달러 돌파",
				"글로벌 송배전 그리드 현대화 장비 쇼티지로 판가 인상"
			],
			"NextEra": [
				"미국 최대 유틸리티 기업... 태양광 및 배터리 ESS 설비 3GW 추가 증설",
				"플로리다 인구 유입에 따른 탄탄한 전력 수요 및 배당 성장"
			],
			"Microsoft": [
				"Azure AI 클라우드 성장률 30% 돌파, Copilot 기업용 유료 구독 급증",
				"OpenAI와 차세대 AI 슈퍼컴퓨터 '스타게이트' 1000억 달러 투자"
			],
			"Apple": [
				"Apple Intelligence 탑재로 아이폰 교체 슈퍼사이클 시동",
				"M4 칩 탑재 Mac 라인업 및 서비스 부문 사상 최대 매출"
			],
			"Alphabet": [
				"Gemini 1.5 Pro 검색 엔진 통합으로 AI 오버뷰 트래픽 증가",
				"구글 클라우드 분기 영업이익률 11% 돌파... AI 인프라 수주 호조"
			],
			"Meta": [
				"오픈소스 Llama 3 생태계 장악... AI 추천 알고리즘으로 체류시간 20% 증가",
				"Ray-Ban Meta 스마트 안경 판매 호조... AR 글래스 공개 임박"
			],
			"Amazon": [
				"AWS 클라우드 연환산 매출 1000억 달러 돌파... 생성형 AI 수혜 본격화",
				"물류센터 로봇 자동화 도입으로 배송 비용 20% 절감"
			],
			"Palantir": [
				"AIP(인공지능 플랫폼) 상용 고객 전년비 80% 폭증... S&P500 편입",
				"미 국방부 타이탄 프로젝트 및 나토 전장 AI 데이터 독점 계약"
			],
			"Lockheed": [
				"F-35 5세대 스텔스 전투기 글로벌 인도량 1000대 돌파",
				"극초음속 미사일 방어 시스템 개발 및 록히드 마틴 수주잔고 사상 최대"
			],
			"RTX": [
				"패트리어트 미사일 요격 시스템 글로벌 동맹국 추가 발주 폭주",
				"프랫&휘트니 기어드 터보팬(GTF) 엔진 정비 정상화"
			],
			"Northrop": [
				"B-21 레이더 차세대 스텔스 폭격기 저율 초도 생산 본격화",
				"우주 군사 위성 및 차세대 ICBM 센티넬 프로그램 주도"
			],
			"GeneralDynamics": [
				"컬럼비아급 차세대 탄도미사일 원자력 잠수함 건조 순항",
				"걸프스트림 비즈니스 제트기 신기종 인도 개시로 마진 급등"
			],
			"Tesla": [
				"로보택시(Cybercab) 완전 자율주행 시범 운행 발표",
				"메가팩 에너지 저장장치(ESS) 분기 배터리 설치량 150% 급증"
			],
			"Rivian": [
				"폭스바겐 그룹 50억 달러 전략적 지분 투자 유치로 현금 확보",
				"중형 전기 SUV 'R2' 사전 예약 10만 대 돌파... 2026년 양산"
			],
			"Lucid": [
				"사우디 국부펀드(PIF) 15억 달러 추가 지원 확보",
				"럭셔리 전기 SUV '그래비티' 사전 주문 개시"
			],
			"Enphase": [
				"유럽 및 캘리포니아 태양광 인버터 재고 소진 후 출하량 바닥 통과",
				"가정용 배터리 백업 시스템 신제품 출시"
			],
			"Albemarle": [
				"글로벌 리튬 생산 1위... 배터리 원자재 가격 안정화 기대",
				"칠레 및 호주 광산 채굴 원가 절감 프로젝트 추진"
			],
			"JPMorgan": [
				"제이미 다이먼 회장 '미국 경제 연착륙 자신'... 분기 순이익 130억 달러",
				"월가 트레이딩 및 신용카드 소비 지표 호조로 목표주가 상향"
			],
			"Goldman Sachs": [
				"글로벌 투자은행(IB) 자문 수수료 전년비 40% 급증",
				"사모펀드 및 자산관리(AUM) 부문 역대 최고 수익 기록"
			],
			"Berkshire": [
				"워런 버핏의 현금 보유액 3000억 달러 돌파... 애플 지분 일부 차익실현",
				"보험 및 철도, 에너지 핵심 사업부의 안정적 현금흐름 유지"
			],
			"Visa": [
				"글로벌 해외 여행 결제액 및 국경 간 결제 거래량 두 자릿수 증가",
				"생성형 AI 결제 사기 방지 솔루션으로 금융 보안 강화"
			],
			"BlackRock": [
				"비트코인 현물 ETF(IBIT) 자산 200억 달러 최단기 돌파",
				"글로벌 총 운용자산(AUM) 10.6조 달러 사상 최고치 경신"
			],
			"Eli Lilly": [
				"비만치료제 젭바운드 주간 처방량 신기록 갱신... 생산 시설 4배 확장",
				"경구용 비만 치료제 올포글리프론 임상 3상 데이터 호조 기대"
			],
			"Novo Nordisk": [
				"위고비 글로벌 50개국 출시 확대 및 심혈관 질환 적응증 승인",
				"카탈란트 생산 시설 인수로 공급 병목 현상 해소 가속"
			],
			"AbbVie": [
				"자가면역 치료제 스카이리치·린버크 매출이 휴미라 공백 완벽 대체",
				"신경과학 및 표적항암제 신약 파이프라인 임상 순항"
			],
			"Pfizer": [
				"시젠(Seagen) 인수를 통한 차세대 항암제 포트폴리오 가동",
				"원가 절감 프로그램 가동으로 수익성 회복 및 배당 수익률 방어"
			],
			"Merck": [
				"면역항암제 키트루다 글로벌 단일 의약품 매출 1위 기록",
				"심혈관 및 폐동맥 고혈압 신약 윈레베어 FDA 승인 후 처방 급증"
			],
			"Walmart": [
				"미국 내 온라인 픽업 및 배송 매출 급증으로 실적 어닝 서프라이즈",
				"광고 사업부 월마트 커넥트 고마진 성장... 51년 연속 배당 증액"
			],
			"Costco": [
				"연회비 인상에도 유료 회원 갱신율 93% 경이적 충성도",
				"글로벌 신규 매장 오픈 가속 및 골드바/은화 판매 흥행"
			],
			"Netflix": [
				"유료 구독자 2억 8000만 명 돌파... 계정 공유 유료화 안착",
				"라이브 스포츠 중계(NFL, WWE) 진출로 광고 단가 상승"
			],
			"McDonalds": [
				"5달러 세트 메뉴 프로모션으로 고객 발길 유입 반등",
				"글로벌 디지털 주문 및 코스모스 신규 음료 브랜드 확장"
			],
			"HomeDepot": [
				"금리 인하 시작으로 주택 담보 대출 및 리모델링 수요 개선 기대",
				"전문 건축업자(Pro) 전용 공급망 인수로 점유율 확대"
			]
		}
		
		news_pool = [
			{"headline": "🚀 [속보] 북쪽 실리콘밸리 AI 칩으로 가세요! NVDA 블랙웰 주문 폭주!", "sector": "ai_chips", "type": "buff", "duration": 15.0},
			{"headline": "⚡ [속보] 북동쪽 AI 전력망·SMR 원전에 빅테크 무탄소 전력 독점 수주!", "sector": "ai_power", "type": "buff", "duration": 15.0},
			{"headline": "🎯 [속보] 남동쪽 국방 AI 팔란티어 AIP 수주 폭증! 미 국방부 전장 장악!", "sector": "defense_tech", "type": "buff", "duration": 15.0},
			{"headline": "🏛️ [속보] 남서쪽 월가 메가뱅크 M&A 부활 및 자산운용 수수료 사상 최대!", "sector": "wall_street", "type": "buff", "duration": 15.0},
			{"headline": "🛒 [속보] 북서쪽 리테일 월마트·넷플릭스 내수 소비 서프라이즈 랠리!", "sector": "retail", "type": "buff", "duration": 15.0},
			{"headline": "📉 [경고] 남쪽 전기차 지대에 공매도 투하! 마진 악화 우려로 패닉셀!", "sector": "ev_auto", "type": "debuff", "duration": 15.0},
			{"headline": "💉 [속보] 일라이릴리 비만 치료제 FDA 패스트트랙 승인! 서쪽 숲 급등!", "sector": "pharma", "type": "buff", "duration": 12.0}
		]

	for k in sectors.keys():
		sector_stay_times[k] = 0.0
		var sec = sectors[k]
		if sec.has("stocks"):
			for stock in sec["stocks"]:
				stock["spawn_count"] = 0
				stock["spawn_quota"] = 28
				stock["cooldown_timer"] = 0.0
				stock["is_halted"] = false
				stock["price"] = get_stock_price(stock)

func get_news_for_sector(sec_key: String) -> String:
	if sector_news_dict.has(sec_key) and not sector_news_dict[sec_key].is_empty():
		var list = sector_news_dict[sec_key]
		return list[news_cycle_index % list.size()]
	return "글로벌 거시경제 동향 및 섹터 수급 분석 진행 중"

func get_news_for_stock(stock_name: String) -> String:
	if stock_news_dict.has(stock_name) and not stock_news_dict[stock_name].is_empty():
		var list = stock_news_dict[stock_name]
		return list[news_cycle_index % list.size()]
	# Fallback if stock has desc
	for sec_key in sectors.keys():
		var sec = sectors[sec_key]
		if sec.has("stocks"):
			for st in sec["stocks"]:
				if st.get("name", "") == stock_name:
					return st.get("desc", "실시간 호가 및 수급 모니터링 진행 중")
	return "실시간 호가 및 수급 모니터링 진행 중"

func reset_match_data():
	match_total_time = 0.0
	news_timer = 0.0
	for k in sectors.keys():
		sector_stay_times[k] = 0.0
		var sec = sectors[k]
		if sec.has("stocks"):
			for stock in sec["stocks"]:
				stock["spawn_count"] = 0
				stock["spawn_quota"] = 28
				stock["cooldown_timer"] = 0.0
				stock["is_halted"] = false

func record_player_position(pos: Vector2, delta: float):
	var current = get_sector_at(pos)
	if current != null and current.has("key"):
		var key = current["key"]
		if sector_stay_times.has(key):
			sector_stay_times[key] += delta

func get_sector_at(pos: Vector2) -> Dictionary:
	# Central Exchange Plaza check (Expanded to 1200m)
	if pos.distance_to(CENTER_POS) <= 1200.0:
		return {
			"key": "plaza",
			"name": "중앙 마켓 광장",
			"sub_title": "360도 증시 대교차로 (안전 지대)",
			"change_rate": 0.0,
			"is_top_bull": false,
			"lead_stock": market_name
		}
		
	var closest_sector = {}
	var min_dist = 999999.0
	
	for key in sectors.keys():
		var sec = sectors[key]
		var dist = pos.distance_to(sec["position"])
		if dist <= sec["radius"] and dist < min_dist:
			min_dist = dist
			closest_sector = sec
			
	if closest_sector.is_empty():
		return {
			"key": "plaza",
			"name": "증시 외곽 완충지",
			"sub_title": "자유 탐색 구역",
			"change_rate": 0.0,
			"is_top_bull": false,
			"lead_stock": market_name
		}
	return closest_sector

func get_nearest_stock_at(pos: Vector2) -> Dictionary:
	var closest_stock = {}
	var min_dist = 600.0 # Wide 600px radius for stock sanctuaries
	
	for key in sectors.keys():
		var sec = sectors[key]
		if not sec.has("stocks"):
			continue
		for stock in sec["stocks"]:
			var stock_world_pos = stock.get("world_pos", Vector2.ZERO)
			var d = pos.distance_to(stock_world_pos)
			if d < min_dist:
				min_dist = d
				closest_stock = stock.duplicate()
				closest_stock["sector_name"] = sec["name"]
				closest_stock["sector_key"] = key
				
	return closest_stock

func get_stocks_near(pos: Vector2, max_dist: float = 2400.0) -> Array:
	var list = []
	for key in sectors.keys():
		var sec = sectors[key]
		if not sec.has("stocks"):
			continue
		for stock in sec["stocks"]:
			var stock_world_pos = stock.get("world_pos", Vector2.ZERO)
			if pos.distance_to(stock_world_pos) <= max_dist:
				var s = stock.duplicate()
				s["sector_name"] = sec["name"]
				s["sector_key"] = key
				list.append(s)
	return list

func get_top_bull_sector() -> Dictionary:
	var top_sec = {}
	var max_rate = -999.0
	for key in sectors.keys():
		var sec = sectors[key]
		if sec["change_rate"] > max_rate:
			max_rate = sec["change_rate"]
			top_sec = sec
	return top_sec

func get_worst_bear_sector() -> Dictionary:
	var worst_sec = {}
	var min_rate = 999.0
	for key in sectors.keys():
		var sec = sectors[key]
		if sec["change_rate"] < min_rate:
			min_rate = sec["change_rate"]
			worst_sec = sec
	return worst_sec

func get_all_sector_guides(player_pos: Vector2) -> Array:
	var guides = []
	for key in sectors.keys():
		var sec = sectors[key]
		var dist = player_pos.distance_to(sec["position"])
		guides.append({
			"key": sec["key"],
			"name": sec["name"],
			"dir_hint": sec.get("direction_hint", ""),
			"rate": sec["change_rate"],
			"dist": int(dist),
			"is_bull": sec.get("is_top_bull", false),
			"position": sec["position"]
		})
	return guides

func trigger_random_breaking_news():
	if news_pool.is_empty():
		return
	var item = news_pool[randi() % news_pool.size()]
	emit_signal("breaking_news_alert", item["headline"], item["sector"], item["type"], item["duration"])
	SoundManager.play_level_up() # Alert chime

func get_retrospective_data() -> Dictionary:
	var top_sector = get_top_bull_sector()
	var top_stay_time = sector_stay_times.get(top_sector.get("key", ""), 0.0)
	var stay_ratio = 0.0
	if match_total_time > 5.0:
		stay_ratio = clamp(top_stay_time / match_total_time, 0.0, 1.0)
		
	var bonus_multiplier = 1.0 + (stay_ratio * 0.5) # Up to +50% Smart Money Bonus!
	
	var user_title = "침착한 관망 개미"
	if stay_ratio >= 0.6:
		user_title = "주도주 완벽 포착! 슈퍼 스마트 개미 🚀"
	elif stay_ratio >= 0.3:
		user_title = "트렌드 감각 있는 트레이더 📈"
	else:
		user_title = "갈 길을 잃은 물타기 개미 🐜"
		
	return {
		"market_name": market_name,
		"top_sector_name": top_sector.get("name", "주도 섹터"),
		"top_stock": top_sector.get("lead_stock", ""),
		"top_sector_ratio": int(stay_ratio * 100),
		"bonus_multiplier": bonus_multiplier,
		"user_title": user_title
	}

# ==============================================================================
# Stock VI (Volatility Interruption) & Cooldown Methods
# ==============================================================================
func record_stock_spawn(stock_name: String, amount: int = 1) -> bool:
	for sec_key in sectors.keys():
		var sec = sectors[sec_key]
		if not sec.has("stocks"):
			continue
		for stock in sec["stocks"]:
			if stock["name"] == stock_name:
				if stock.get("is_halted", false):
					return false
				stock["spawn_count"] = stock.get("spawn_count", 0) + amount
				if stock["spawn_count"] >= stock.get("spawn_quota", 28):
					trigger_stock_vi(stock)
					return true
	return false

func trigger_stock_vi(stock: Dictionary):
	stock["is_halted"] = true
	stock["cooldown_timer"] = 20.0 # 20 seconds VI cooling halt
	emit_signal("stock_vi_triggered", stock["name"], 20.0)
	Global.market_event_triggered.emit(
		"🚨 [VI 발동] %s 과열 지정!" % stock["name"],
		"20초간 거래 일시 정지(단일가 냉각)! 다른 급등 종목으로 이동하세요!"
	)
	SoundManager.play_boss_alert()

func update_stock_cooldowns(delta: float):
	for sec_key in sectors.keys():
		var sec = sectors[sec_key]
		if not sec.has("stocks"):
			continue
		for stock in sec["stocks"]:
			if stock.get("is_halted", false):
				stock["cooldown_timer"] -= delta
				if stock["cooldown_timer"] <= 0.0:
					stock["cooldown_timer"] = 0.0
					stock["is_halted"] = false
					stock["spawn_count"] = 0
					emit_signal("stock_trading_resumed", stock["name"])
					Global.market_event_triggered.emit(
						"🔔 [%s 거래 재개]" % stock["name"],
						"단기 과열 냉각 완료! 정상 거래 및 스폰이 재개되었습니다."
					)
					SoundManager.play_level_up()
