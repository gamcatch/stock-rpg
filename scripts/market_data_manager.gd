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
	# Korea 12 Sectors Stocks
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
	"현대차": "242,000", "005380": "242,000",
	"기아": "104,500", "000270": "104,500",
	"현대모비스": "238,000", "012330": "238,000",
	"한온시스템": "4,120", "018880": "4,120",
	"HL만도": "41,800", "204320": "41,800",
	"현대오토에버": "148,000", "307950": "148,000",
	"한국타이어": "48,500", "161390": "48,500",
	"삼기이브": "2,150", "419050": "2,150",
	"두산로보틱스": "73,500", "454910": "73,500",
	"레인보우로보": "148,000", "277810": "148,000",
	"로보티즈": "19,800", "108490": "19,800",
	"엔젤로보틱스": "24,500", "455900": "24,500",
	"루닛": "53,800", "328130": "53,800",
	"유진로봇": "7,150", "056080": "7,150",
	"에스피지": "29,800", "058610": "29,800",
	"에스비비테크": "18,400", "389500": "18,400",
	"NAVER": "194,500", "035420": "194,500",
	"카카오": "42,300", "035720": "42,300",
	"크래프톤": "335,000", "259960": "335,000",
	"넷마블": "58,200", "251270": "58,200",
	"엔씨소프트": "198,000", "036570": "198,000",
	"펄어비스": "36,500", "263750": "36,500",
	"위메이드": "39,400", "112040": "39,400",
	"카카오게임즈": "17,200", "293490": "17,200",
	"하이브": "192,000", "352820": "192,000",
	"JYP Ent.": "52,400", "035900": "52,400",
	"에스엠": "72,500", "041510": "72,500",
	"와이지엔터": "38,600", "122870": "38,600",
	"CJ ENM": "71,200", "035760": "71,200",
	"스튜디오드래곤": "39,800", "253450": "39,800",
	"디어유": "28,500", "376300": "28,500",
	"콘텐트리중앙": "10,400", "036420": "10,400",
	"에코프로비엠": "168,000", "247540": "168,000",
	"에코프로": "79,500", "086520": "79,500",
	"LG에너지솔루션": "385,000", "373220": "385,000",
	"POSCO홀딩스": "362,000", "005490": "362,000",
	"포스코퓨처엠": "224,000", "003670": "224,000",
	"엔켐": "185,000", "348370": "185,000",
	"대주전자재료": "98,000", "078600": "98,000",
	"금양": "42,000", "001570": "42,000",
	"삼양식품": "548,000", "003230": "548,000",
	"농심": "398,000", "004370": "398,000",
	"오리온": "98,500", "271560": "98,500",
	"CJ제일제당": "312,000", "097950": "312,000",
	"아모레퍼시픽": "138,000", "090430": "138,000",
	"코스맥스": "145,000", "192820": "145,000",
	"한국콜마": "69,500", "161890": "69,500",
	"빙그레": "78,200", "005180": "78,200",
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
	"HD한국조선해양": "198,000", "009540": "198,000",
	"삼성중공업": "11,250", "010140": "11,250",
	"한화오션": "38,400", "042660": "38,400",
	"HD현대마린엔진": "34,200", "071970": "34,200",
	"HMM": "18,200", "011200": "18,200",
	"팬오션": "3,850", "028670": "3,850",
	"HJ중공업": "3,450", "097230": "3,450",
	"현대힘스": "16,200", "460930": "16,200",
	"한화에어로": "324,000", "012450": "324,000",
	"현대로템": "52,800", "064350": "52,800",
	"LIG넥스원": "218,000", "079550": "218,000",
	"한국항공우주": "56,200", "047810": "56,200",
	"풍산": "68,500", "103140": "68,500",
	"쎄트렉아이": "46,800", "099320": "46,800",
	"한화시스템": "19,200", "272210": "19,200",
	"현대위아": "58,500", "011210": "58,500",

	# US 12 Sectors Stocks
	"NVIDIA": "$128.50", "NVDA": "$128.50",
	"Broadcom": "$165.20", "AVGO": "$165.20",
	"AMD": "$148.00",
	"TSMC": "$184.50", "TSM": "$184.50",
	"Micron": "$112.00", "MU": "$112.00",
	"Qualcomm": "$168.00", "QCOM": "$168.00",
	"Arm": "$142.00", "ARM": "$142.00",
	"Intel": "$22.50", "INTC": "$22.50",
	"Constellation": "$265.00", "CEG": "$265.00",
	"Vistra": "$128.00", "VST": "$128.00",
	"Oklo": "$18.50", "OKLO": "$18.50",
	"GE Vernova": "$260.00", "GEV": "$260.00",
	"NextEra": "$82.00", "NEE": "$82.00",
	"Cameco": "$52.50", "CCJ": "$52.50",
	"NuScale": "$19.50", "SMR": "$19.50",
	"NRG": "$88.00",
	"Palantir": "$42.50", "PLTR": "$42.50",
	"Lockheed": "$582.00", "LMT": "$582.00",
	"RTX": "$122.00",
	"Northrop": "$520.00", "NOC": "$520.00",
	"GeneralDynamics": "$295.00", "GD": "$295.00",
	"Boeing": "$154.00", "BA": "$154.00",
	"Kratos": "$22.50", "KTOS": "$22.50",
	"RocketLab": "$10.50", "RKLB": "$10.50",
	"Microsoft": "$428.00", "MSFT": "$428.00",
	"Apple": "$228.50", "AAPL": "$228.50",
	"Alphabet": "$168.00", "GOOGL": "$168.00",
	"Meta": "$578.00", "META": "$578.00",
	"Amazon": "$188.00", "AMZN": "$188.00",
	"Oracle": "$172.00", "ORCL": "$172.00",
	"IBM": "$222.00",
	"Salesforce": "$285.00", "CRM": "$285.00",
	"CrowdStrike": "$295.00", "CRWD": "$295.00",
	"PaloAlto": "$355.00", "PANW": "$355.00",
	"ServiceNow": "$875.00", "NOW": "$875.00",
	"Snowflake": "$122.00", "SNOW": "$122.00",
	"Datadog": "$118.00", "DDOG": "$118.00",
	"MongoDB": "$275.00", "MDB": "$275.00",
	"Cloudflare": "$88.50", "NET": "$88.50",
	"Zscaler": "$185.00", "ZS": "$185.00",
	"Netflix": "$720.00", "NFLX": "$720.00",
	"Disney": "$94.50", "DIS": "$94.50",
	"Spotify": "$365.00", "SPOT": "$365.00",
	"WarnerBros": "$7.80", "WBD": "$7.80",
	"EA": "$142.00",
	"TakeTwo": "$152.00", "TTWO": "$152.00",
	"Roblox": "$42.50", "RBLX": "$42.50",
	"AppLovin": "$165.00", "APP": "$165.00",
	"Tesla": "$258.00", "TSLA": "$258.00",
	"Rivian": "$11.40", "RIVN": "$11.40",
	"Lucid": "$3.25", "LCID": "$3.25",
	"Enphase": "$92.00", "ENPH": "$92.00",
	"Albemarle": "$94.00", "ALB": "$94.00",
	"Ford": "$11.20", "F": "$11.20",
	"GeneralMotors": "$46.50", "GM": "$46.50",
	"QuantumScape": "$6.20", "QS": "$6.20",
	"ExxonMobil": "$118.00", "XOM": "$118.00",
	"Chevron": "$152.00", "CVX": "$152.00",
	"ConocoPhillips": "$106.00", "COP": "$106.00",
	"Schlumberger": "$44.50", "SLB": "$44.50",
	"EOG": "$124.00",
	"Occidental": "$52.00", "OXY": "$52.00",
	"Marathon": "$168.00", "MPC": "$168.00",
	"Valero": "$138.00", "VLO": "$138.00",
	"JPMorgan": "$218.00", "JPM": "$218.00",
	"GoldmanSachs": "$495.00", "GS": "$495.00",
	"Berkshire": "$455.00", "BRK.B": "$455.00",
	"Visa": "$282.00", "V": "$282.00",
	"Mastercard": "$488.00", "MA": "$488.00",
	"BlackRock": "$985.00", "BLK": "$985.00",
	"Coinbase": "$195.00", "COIN": "$195.00",
	"MicroStrategy": "$185.00", "MSTR": "$185.00",
	"EliLilly": "$885.00", "LLY": "$885.00",
	"NovoNordisk": "$124.00", "NVO": "$124.00",
	"AbbVie": "$188.00", "ABBV": "$188.00",
	"Pfizer": "$28.50", "PFE": "$28.50",
	"Merck": "$114.00", "MRK": "$114.00",
	"Amgen": "$318.00", "AMGN": "$318.00",
	"Vertex": "$465.00", "VRTX": "$465.00",
	"Gilead": "$82.00", "GILD": "$82.00",
	"Walmart": "$82.00", "WMT": "$82.00",
	"Costco": "$890.00", "COST": "$890.00",
	"Target": "$152.00", "TGT": "$152.00",
	"HomeDepot": "$395.00", "HD": "$395.00",
	"McDonalds": "$298.00", "MCD": "$298.00",
	"Starbucks": "$96.00", "SBUX": "$96.00",
	"Nike": "$84.00", "NKE": "$84.00",
	"CocaCola": "$68.00", "KO": "$68.00",
	"Caterpillar": "$395.00", "CAT": "$395.00",
	"Deere": "$398.00", "DE": "$398.00",
	"UnionPacific": "$242.00", "UNP": "$242.00",
	"UPS": "$132.00",
	"Honeywell": "$208.00", "HON": "$208.00",
	"GEAerospace": "$186.00", "GE": "$186.00",
	"Emerson": "$108.00", "EMR": "$108.00",
	"Eaton": "$345.00", "ETN": "$345.00"
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
		# Korea 12 Sectors
		"semiconductor": ["반도체", "하이닉스", "삼성전자", "한미반도체", "hbm", "파운드리", "소부장", "웨이퍼", "hpsp", "리노공업", "이수페타시스", "제주반도체", "가온칩스"],
		"power_grid": ["전력", "변압기", "원전", "원자력", "현대일렉", "두산에너빌", "ls일렉", "ls electric", "효성중공업", "한전kps", "그리드", "배전반", "smr", "일진전기", "우진엔텍", "제룡전기"],
		"automotive": ["현대차", "기아", "모비스", "현대모비스", "자동차", "완성차", "전기차", "자율주행", "hl만도", "한온시스템", "현대오토에버", "한국타이어", "삼기이브"],
		"robot_ai": ["로봇", "협동로봇", "두산로보", "레인보우", "로보티즈", "엔젤로보틱스", "루닛", "유진로봇", "에스피지", "에스비비테크", "감속기", "액추에이터"],
		"gaming_platform": ["게임", "플랫폼", "네이버", "naver", "카카오", "크래프톤", "넷마블", "엔씨소프트", "펄어비스", "위메이드", "카카오게임즈", "신작", "mmorpg"],
		"entertainment": ["엔터", "k-pop", "하이브", "jyp", "에스엠", "sm", "와이지", "yg", "cj enm", "스튜디오드래곤", "디어유", "음반", "음원", "콘서트", "드라마"],
		"battery": ["2차전지", "배터리", "에코프로", "lg에너지", "lg엔솔", "포스코", "리튬", "양극재", "음극재", "캐즘", "엔켐", "대주전자재료", "금양"],
		"food_consumer": ["k-푸드", "라면", "불닭", "삼양식품", "농심", "오리온", "cj제일제당", "아모레", "화장품", "코스맥스", "한국콜마", "빙그레", "수출"],
		"finance": ["금융", "은행", "지주", "밸류업", "kb금융", "신한지주", "메리츠", "하나금융", "삼성물산", "배당", "자사주", "주주환원", "삼성생명", "미래에셋", "우리금융"],
		"bio": ["바이오", "제약", "신약", "임상", "fda", "알테오젠", "삼성바이오", "셀트리온", "유한양행", "hlb", "sc제형", "adc", "리가켐바이오", "삼천당제약", "에이비엘바이오"],
		"shipbuilding": ["조선", "해운", "선박", "조선해양", "삼성중공업", "한화오션", "현대마린", "hmm", "lng선", "도크", "수주잔고", "flng", "팬오션", "hj중공업", "현대힘스"],
		"defense": ["방산", "우주", "항공", "k-방산", "한화에어로", "현대로템", "lig넥스원", "한국항공우주", "kai", "풍산", "자주포", "전차", "미사일", "수출", "쎄트렉아이", "한화시스템", "현대위아"],

		# US 12 Sectors
		"ai_chips": ["nvidia", "엔비디아", "broadcom", "브로드컴", "amd", "tsmc", "micron", "마이크론", "gpu", "chip", "qualcomm", "arm", "intel", "semiconductor"],
		"ai_power": ["constellation", "vistra", "oklo", "vernova", "nextera", "smr", "nuclear", "grid", "cameco", "nuscale", "nrg", "power", "utility", "전력", "원전"],
		"defense_tech": ["palantir", "팔란티어", "lockheed", "록히드", "rtx", "northrop", "general dynamics", "boeing", "보잉", "kratos", "rocket lab", "defense", "military"],
		"big_tech": ["microsoft", "마이크로소프트", "apple", "애플", "google", "구글", "alphabet", "meta", "메타", "amazon", "아마존", "oracle", "ibm", "salesforce", "cloud"],
		"cyber_saas": ["crowdstrike", "palo alto", "servicenow", "snowflake", "datadog", "mongodb", "cloudflare", "zscaler", "보안", "saas", "cybersecurity"],
		"media_entertain": ["netflix", "넷플릭스", "disney", "디즈니", "spotify", "스포티파이", "warner", "ea", "take-two", "roblox", "로블록스", "applovin"],
		"ev_auto": ["tesla", "테슬라", "rivian", "리비안", "lucid", "루시드", "enphase", "albemarle", "ford", "gm", "quantumscape", "ev", "electric vehicle"],
		"traditional_energy": ["exxon", "엑손모빌", "chevron", "셰브론", "conocophillips", "schlumberger", "eog", "oxy", "옥시덴탈", "marathon", "valero", "oil", "정유"],
		"wall_street": ["jpmorgan", "제이피모건", "goldman", "골드만", "berkshire", "버크셔", "visa", "비자", "mastercard", "blackrock", "블랙록", "coinbase", "microstrategy", "비트코인"],
		"pharma": ["lilly", "일라이릴리", "novo", "노보노디스크", "abbvie", "애브비", "pfizer", "화이자", "merck", "머크", "amgen", "vertex", "gilead", "glp-1", "fda"],
		"retail": ["walmart", "월마트", "costco", "코스트코", "target", "home depot", "mcdonald", "맥도날드", "starbucks", "스타벅스", "nike", "나이키", "coca-cola", "코카콜라"],
		"industrial_infra": ["caterpillar", "캐터필러", "deere", "디어", "union pacific", "ups", "honeywell", "하니웰", "ge aerospace", "emerson", "eaton", "infra", "인프라"]
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
		# Korean Market 12 Radial Clock Mega Sectors (Distance ~4800)
		# 12시 (0, -4800): 반도체 밸리
		sectors["semiconductor"] = {
			"key": "semiconductor",
			"name": "반도체 밸리",
			"sub_title": "AI 반도체 & HBM 대장 붉은 숲",
			"direction_hint": "🕛 12시",
			"position": Vector2(0, -4800),
			"radius": 1250.0,
			"change_rate": 6.8,
			"lead_stock": "한미반도체 (+14.8%)",
			"stocks": [
				{"name": "한미반도체", "code": "042700", "rate": 14.8, "world_pos": Vector2(0, -5450), "desc": "🔥 [상한가 제단] TC본더 독점 수주!"},
				{"name": "SK하이닉스", "code": "000660", "rate": 9.2, "world_pos": Vector2(460, -5260), "desc": "🚀 [HBM 1위 성역] 5세대 HBM3E 공급"},
				{"name": "삼성전자", "code": "005930", "rate": 4.5, "world_pos": Vector2(650, -4800), "desc": "🟢 [국민주 쉼터] 체력 회복 샘물"},
				{"name": "HPSP", "code": "403870", "rate": 8.1, "world_pos": Vector2(460, -4340), "desc": "⚡ 고압수소열처리 독점 공급"},
				{"name": "리노공업", "code": "058470", "rate": 5.4, "world_pos": Vector2(0, -4150), "desc": "💎 글로벌 테스트 소켓 최강자"},
				{"name": "이수페타시스", "code": "007660", "rate": 11.2, "world_pos": Vector2(-460, -4340), "desc": "🌐 AI 가속기용 다층MLB 기판"},
				{"name": "제주반도체", "code": "080220", "rate": 7.8, "world_pos": Vector2(-650, -4800), "desc": "📱 온디바이스 AI 저전력 LPDDR 메모리"},
				{"name": "가온칩스", "code": "399720", "rate": 6.2, "world_pos": Vector2(-460, -5260), "desc": "📐 AI ASIC 디자인하우스 글로벌 파트너"}
			],
			"theme_color": Color(1.0, 0.2, 0.2, 0.25),
			"is_top_bull": true
		}

		# 1시 (2400, -4157): 전력망 & 원전
		sectors["power_grid"] = {
			"key": "power_grid",
			"name": "전력망 & 원전",
			"sub_title": "AI 전력 쇼티지 & 체코 원전 르네상스",
			"direction_hint": "🕐 %s",
			"position": Vector2(2400, -4157),
			"radius": 1250.0,
			"change_rate": 9.2,
			"lead_stock": "HD현대일렉트릭 (+13.5%)",
			"stocks": [
				{"name": "HD현대일렉트릭", "code": "026720", "rate": 13.5, "world_pos": Vector2(2400, -4807), "desc": "⚡ [변압기 제왕] 북미 초고압 변압기 품귀"},
				{"name": "두산에너빌리티", "code": "034020", "rate": 8.8, "world_pos": Vector2(2860, -4617), "desc": "☢️ 체코 원전 주기기 & 차세대 SMR"},
				{"name": "LS ELECTRIC", "code": "010120", "rate": 7.6, "world_pos": Vector2(3050, -4157), "desc": "🔌 AI 데이터센터 배전 시스템 수주"},
				{"name": "효성중공업", "code": "298040", "rate": 11.2, "world_pos": Vector2(2860, -3697), "desc": "🏭 미국 초고압 변압기 팩토리 풀가동"},
				{"name": "한전KPS", "code": "051600", "rate": 4.2, "world_pos": Vector2(2400, -3507), "desc": "🛠️ 원자력 및 화력 발전 정비 독점"},
				{"name": "일진전기", "code": "103590", "rate": 8.5, "world_pos": Vector2(1940, -3697), "desc": "⚡ 초고압 변압기 & 송전선로 북미 대량 수주"},
				{"name": "우진엔텍", "code": "457550", "rate": 5.9, "world_pos": Vector2(1750, -4157), "desc": "☢️ 원자력 계측제어 설비 정비 원천기술"},
				{"name": "제룡전기", "code": "033100", "rate": 9.1, "world_pos": Vector2(1940, -4617), "desc": "🔌 미국 배전 변압기 100% 수출 잭팟"}
			],
			"theme_color": Color(1.0, 0.45, 0.15, 0.25),
			"is_top_bull": false
		}

		# 2시 (4157, -2400): 미래차 & 모빌리티
		sectors["automotive"] = {
			"key": "automotive",
			"name": "미래차 & 모빌리티",
			"sub_title": "글로벌 완성차 & SDV 전장 자율주행",
			"direction_hint": "🕑 %s",
			"position": Vector2(4157, -2400),
			"radius": 1250.0,
			"change_rate": 5.2,
			"lead_stock": "현대차 (+7.2%)",
			"stocks": [
				{"name": "현대차", "code": "005380", "rate": 7.2, "world_pos": Vector2(4157, -3050), "desc": "🚗 [글로벌 Top3] 역대급 영업이익 & 인도 IPO"},
				{"name": "기아", "code": "000270", "rate": 6.5, "world_pos": Vector2(4617, -2860), "desc": "🚙 두 자릿수 영업이익률 & 주주환원 랠리"},
				{"name": "현대모비스", "code": "012330", "rate": 4.8, "world_pos": Vector2(4807, -2400), "desc": "⚙️ SDV 소프트웨어 전장 플랫폼 공급"},
				{"name": "HL만도", "code": "204320", "rate": 5.1, "world_pos": Vector2(4617, -1940), "desc": "🛰️ 북미 테슬라향 전자식 조향장치 독점"},
				{"name": "한온시스템", "code": "018880", "rate": 3.2, "world_pos": Vector2(4157, -1750), "desc": "❄️ 전기차 통합 열관리 시스템 공급"},
				{"name": "현대오토에버", "code": "307950", "rate": 6.8, "world_pos": Vector2(3697, -1940), "desc": "💻 현대차그룹 차량용 SW 모빌진 독점"},
				{"name": "한국타이어", "code": "161390", "rate": 4.2, "world_pos": Vector2(3507, -2400), "desc": "🛞 고수익 전기차(EV) 전용 타이어 1위"},
				{"name": "삼기이브", "code": "419050", "rate": 5.8, "world_pos": Vector2(3697, -2860), "desc": "🔋 배터리 팩 엔드플레이트 경량화 부품"}
			],
			"theme_color": Color(0.2, 0.8, 0.9, 0.25),
			"is_top_bull": false
		}

		# 3시 (4800, 0): 로봇 & AI 파크
		sectors["robot_ai"] = {
			"key": "robot_ai",
			"name": "로봇 & AI 파크",
			"sub_title": "지능형 피지컬 AI & 감속기 협동 지대",
			"direction_hint": "🕒 %s",
			"position": Vector2(4800, 0),
			"radius": 1250.0,
			"change_rate": 4.8,
			"lead_stock": "두산로보틱스 (+7.5%)",
			"stocks": [
				{"name": "두산로보틱스", "code": "454910", "rate": 7.5, "world_pos": Vector2(4800, -650), "desc": "🤖 협동로봇 글로벌 점유율 확대"},
				{"name": "레인보우로보", "code": "277810", "rate": 5.8, "world_pos": Vector2(5260, -460), "desc": "🦾 휴머노이드 보행 플랫폼 국책과제"},
				{"name": "로보티즈", "code": "108490", "rate": 6.7, "world_pos": Vector2(5450, 0), "desc": "🦾 실외 자율주행 배달로봇 & 액추에이터"},
				{"name": "엔젤로보틱스", "code": "455900", "rate": 5.2, "world_pos": Vector2(5260, 460), "desc": "🦿 웨어러블 재활 보행로봇 의료 상용화"},
				{"name": "루닛", "code": "328130", "rate": 6.8, "world_pos": Vector2(4800, 650), "desc": "🩺 의료 AI 암 조기진단 글로벌 공급"},
				{"name": "유진로봇", "code": "056080", "rate": 4.5, "world_pos": Vector2(4340, 460), "desc": "🧹 자율주행 물류 로봇(AMR) 솔루션"},
				{"name": "에스피지", "code": "058610", "rate": 5.9, "world_pos": Vector2(4150, 0), "desc": "⚙️ 정밀 감속기 SH/SR 로봇 부품 국산화"},
				{"name": "에스비비테크", "code": "389500", "rate": 6.1, "world_pos": Vector2(4340, -460), "desc": "🦾 초정밀 하모닉 감속기 양산 독점"}
			],
			"theme_color": Color(1.0, 0.55, 0.2, 0.22),
			"is_top_bull": false
		}

		# 4시 (4157, 2400): 게임 & 플랫폼
		sectors["gaming_platform"] = {
			"key": "gaming_platform",
			"name": "게임 & 플랫폼",
			"sub_title": "글로벌 IP & 생성형 AI 디지털 제국",
			"direction_hint": "🕓 %s",
			"position": Vector2(4157, 2400),
			"radius": 1250.0,
			"change_rate": 4.1,
			"lead_stock": "크래프톤 (+8.2%)",
			"stocks": [
				{"name": "크래프톤", "code": "259960", "rate": 8.2, "world_pos": Vector2(4157, 1750), "desc": "🔫 [배그 신화] 글로벌 배틀그라운드 트래픽 급증"},
				{"name": "NAVER", "code": "035420", "rate": 3.2, "world_pos": Vector2(4617, 1940), "desc": "🧠 생성형 AI 하이퍼클로바X 검색 서비스"},
				{"name": "카카오", "code": "035720", "rate": 2.1, "world_pos": Vector2(4807, 2400), "desc": "💬 국민 메신저 카나나 AI 에이전트 도입"},
				{"name": "넷마블", "code": "251270", "rate": 5.5, "world_pos": Vector2(4617, 2860), "desc": "⚔️ 나 혼자만 레벨업 글로벌 흥행 잭팟"},
				{"name": "엔씨소프트", "code": "036570", "rate": 3.8, "world_pos": Vector2(4157, 3050), "desc": "🏰 TL 글로벌 서비스 및 신작 IP 전환"},
				{"name": "펄어비스", "code": "263750", "rate": 6.4, "world_pos": Vector2(3697, 2860), "desc": "🏹 붉은사막 게임스컴 최고 기대작 출격"},
				{"name": "위메이드", "code": "112040", "rate": 4.9, "world_pos": Vector2(3507, 2400), "desc": "🪙 미르의 전설 블록체인 글로벌 게임"},
				{"name": "카카오게임즈", "code": "293490", "rate": 3.5, "world_pos": Vector2(3697, 1940), "desc": "🛡️ 오딘 및 크로노 오디세이 대작 라인업"}
			],
			"theme_color": Color(0.65, 0.35, 1.0, 0.25),
			"is_top_bull": false
		}

		# 5시 (2400, 4157): K-컬처 & 엔터
		sectors["entertainment"] = {
			"key": "entertainment",
			"name": "K-컬처 & 엔터",
			"sub_title": "글로벌 팬덤 & 빌보드 K-POP 콘서트",
			"direction_hint": "🕔 %s",
			"position": Vector2(2400, 4157),
			"radius": 1250.0,
			"change_rate": 5.8,
			"lead_stock": "하이브 (+7.4%)",
			"stocks": [
				{"name": "하이브", "code": "352820", "rate": 7.4, "world_pos": Vector2(2400, 3507), "desc": "👑 BTS 완전체 컴백 기대감 & 위버스 플랫폼"},
				{"name": "JYP Ent.", "code": "035900", "rate": 5.2, "world_pos": Vector2(2860, 3697), "desc": "🎤 스트레이키즈 글로벌 스타디움 투어"},
				{"name": "에스엠", "code": "041510", "rate": 6.1, "world_pos": Vector2(3050, 4157), "desc": "✨ 에스파·라이즈 음원 차트 싹쓸이"},
				{"name": "와이지엔터", "code": "122870", "rate": 4.8, "world_pos": Vector2(2860, 4617), "desc": "🖤 베이비몬스터 & 블랙핑크 월드투어"},
				{"name": "CJ ENM", "code": "035760", "rate": 4.1, "world_pos": Vector2(2400, 4807), "desc": "🎬 K-콘텐츠 티빙 OTT 흑자 전환"},
				{"name": "스튜디오드래곤", "code": "253450", "rate": 5.6, "world_pos": Vector2(1940, 4617), "desc": "📺 넷플릭스 텐트폴 드라마 제작 공급"},
				{"name": "디어유", "code": "376300", "rate": 6.5, "world_pos": Vector2(1750, 4157), "desc": "💌 글로벌 K-POP 프라이빗 메시지 구독"},
				{"name": "콘텐트리중앙", "code": "036420", "rate": 3.9, "world_pos": Vector2(1940, 3697), "desc": "🍿 메가박스 극장 및 흥행 영화 배급"}
			],
			"theme_color": Color(1.0, 0.3, 0.7, 0.24),
			"is_top_bull": false
		}

		# 6시 (0, 4800): 2차전지 광산
		sectors["battery"] = {
			"key": "battery",
			"name": "2차전지 광산",
			"sub_title": "전기차 캐즘 푸른 공매도 빙벽",
			"direction_hint": "🕕 %s",
			"position": Vector2(0, 4800),
			"radius": 1250.0,
			"change_rate": -5.6,
			"lead_stock": "에코프로비엠 (-7.1%)",
			"stocks": [
				{"name": "에코프로비엠", "code": "247540", "rate": -7.1, "world_pos": Vector2(0, 4150), "desc": "⚠️ [공매도 총본산] 하이니켈 양극재"},
				{"name": "에코프로", "code": "086520", "rate": -6.5, "world_pos": Vector2(460, 4340), "desc": "📉 배터리 소재 수직계열화 지주사"},
				{"name": "LG에너지솔루션", "code": "373220", "rate": -3.2, "world_pos": Vector2(650, 4800), "desc": "🧊 글로벌 배터리 셀 제조 1위"},
				{"name": "POSCO홀딩스", "code": "005490", "rate": -4.2, "world_pos": Vector2(460, 5260), "desc": "⛏️ 염호 리튬 생산 밸류체인"},
				{"name": "포스코퓨처엠", "code": "003670", "rate": -5.8, "world_pos": Vector2(0, 5450), "desc": "📉 양극재/음극재 원가 하락"},
				{"name": "엔켐", "code": "348370", "rate": -4.5, "world_pos": Vector2(-460, 5260), "desc": "🧪 북미 시장 점유율 1위 전해액 공급망"},
				{"name": "대주전자재료", "code": "078600", "rate": -3.8, "world_pos": Vector2(-650, 4800), "desc": "🔋 고용량 실리콘 음극재 독점 양산"},
				{"name": "금양", "code": "001570", "rate": -6.2, "world_pos": Vector2(-460, 4340), "desc": "⛏️ 원통형 4695 배터리 및 리튬 광산 개발"}
			],
			"theme_color": Color(0.2, 0.5, 1.0, 0.28),
			"is_top_bull": false
		}

		# 7시 (-2400, 4157): K-푸드 & 소비재
		sectors["food_consumer"] = {
			"key": "food_consumer",
			"name": "K-푸드 & 소비재",
			"sub_title": "불닭 열풍 & K-뷰티 글로벌 전성기",
			"direction_hint": "🕖 %s",
			"position": Vector2(-2400, 4157),
			"radius": 1250.0,
			"change_rate": 7.5,
			"lead_stock": "삼양식품 (+11.8%)",
			"stocks": [
				{"name": "삼양식품", "code": "003230", "rate": 11.8, "world_pos": Vector2(-2400, 3507), "desc": "🌶️ [불닭 신화] 미국 월마트 입점 완판 랠리"},
				{"name": "농심", "code": "004370", "rate": 5.2, "world_pos": Vector2(-1940, 3697), "desc": "🍜 신라면 해외 매출 비중 60% 돌파"},
				{"name": "오리온", "code": "271560", "rate": 4.6, "world_pos": Vector2(-1750, 4157), "desc": " 초코파이 글로벌 3조 클럽 및 탄탄한 마진"},
				{"name": "CJ제일제당", "code": "097950", "rate": 3.8, "world_pos": Vector2(-1940, 4617), "desc": "🥟 비비고 만두 북미 시장 점유율 1위"},
				{"name": "아모레퍼시픽", "code": "090430", "rate": 6.8, "world_pos": Vector2(-2400, 4807), "desc": "💄 코스알엑스 북미·유럽 K-뷰티 폭풍 성장"},
				{"name": "코스맥스", "code": "192820", "rate": 7.9, "world_pos": Vector2(-2860, 4617), "desc": "🧴 글로벌 화장품 ODM 독보적 1위 수주"},
				{"name": "한국콜마", "code": "161890", "rate": 6.2, "world_pos": Vector2(-3050, 4157), "desc": "☀️ 선크림 글로벌 독점 생산 캐시카우"},
				{"name": "빙그레", "code": "005180", "rate": 5.4, "world_pos": Vector2(-2860, 3697), "desc": "🍦 바나나맛우유 & 메로나 미국 수출 호조"}
			],
			"theme_color": Color(1.0, 0.7, 0.2, 0.25),
			"is_top_bull": false
		}

		# 8시 (-4157, 2400): 금융 & 밸류업
		sectors["finance"] = {
			"key": "finance",
			"name": "금융 & 밸류업",
			"sub_title": "자사주 소각 & 고배당 황금 요새",
			"direction_hint": "🕗 %s",
			"position": Vector2(-4157, 2400),
			"radius": 1250.0,
			"change_rate": 4.5,
			"lead_stock": "메리츠금융지주 (+6.2%)",
			"stocks": [
				{"name": "KB금융", "code": "105560", "rate": 4.8, "world_pos": Vector2(-4157, 1750), "desc": "🏦 [밸류업 대장] 1조원 자사주 매입 소각"},
				{"name": "신한지주", "code": "055550", "rate": 3.9, "world_pos": Vector2(-3697, 1940), "desc": "💰 분기 균등 배당 & 자본 효율 극대화"},
				{"name": "메리츠금융지주", "code": "138040", "rate": 6.2, "world_pos": Vector2(-3507, 2400), "desc": "👑 주주환원율 50% 배당의 제왕"},
				{"name": "하나금융지주", "code": "086790", "rate": 3.5, "world_pos": Vector2(-3697, 2860), "desc": "📈 저PBR 해소 & 글로벌 순이익 증대"},
				{"name": "삼성물산", "code": "028260", "rate": 4.1, "world_pos": Vector2(-4157, 3050), "desc": "🏛️ 지주사 가치 제고 & 자사주 전량 소각"},
				{"name": "삼성생명", "code": "032830", "rate": 5.1, "world_pos": Vector2(-4617, 2860), "desc": "🏛️ 저PBR 0.5배 극저평가 밸류업 보험 대장"},
				{"name": "미래에셋증권", "code": "006800", "rate": 4.3, "world_pos": Vector2(-4807, 2400), "desc": "📈 적극적 자사주 매입 소각 글로벌 금융투자"},
				{"name": "우리금융지주", "code": "316140", "rate": 3.8, "world_pos": Vector2(-4617, 1940), "desc": "💰 분기 배당 확대 및 비은행 포트폴리오 강화"}
			],
			"theme_color": Color(1.0, 0.8, 0.2, 0.25),
			"is_top_bull": false
		}

		# 9시 (-4800, 0): 바이오 랩
		sectors["bio"] = {
			"key": "bio",
			"name": "바이오 랩",
			"sub_title": "신약 임상 완만한 서쪽 숲",
			"direction_hint": "🕘 %s",
			"position": Vector2(-4800, 0),
			"radius": 1250.0,
			"change_rate": 3.8,
			"lead_stock": "알테오젠 (+8.6%)",
			"stocks": [
				{"name": "알테오젠", "code": "196170", "rate": 8.6, "world_pos": Vector2(-4800, -650), "desc": "💉 피하주사(SC) 플랫폼 독점 라이선스"},
				{"name": "삼성바이오로직스", "code": "207940", "rate": 1.2, "world_pos": Vector2(-4340, -460), "desc": "🧪 CDMO 글로벌 1위 대규모 생산능력"},
				{"name": "셀트리온", "code": "068270", "rate": 2.1, "world_pos": Vector2(-4150, 0), "desc": "💊 짐펜트라 미국 PBM 처방집 80% 등재"},
				{"name": "유한양행", "code": "000100", "rate": 4.8, "world_pos": Vector2(-4340, 460), "desc": "🏆 렉라자 국산 항암신약 FDA 승인"},
				{"name": "HLB", "code": "028300", "rate": 3.5, "world_pos": Vector2(-4800, 650), "desc": "🔬 리보세라닙 간암신약 승인 재도전"},
				{"name": "리가켐바이오", "code": "141080", "rate": 7.4, "world_pos": Vector2(-5260, 460), "desc": "🎯 차세대 ADC 플랫폼 글로벌 기술수출"},
				{"name": "삼천당제약", "code": "000250", "rate": 6.8, "world_pos": Vector2(-5450, 0), "desc": "💊 경구용 GLP-1 비만치료제 글로벌 계약"},
				{"name": "에이비엘바이오", "code": "298380", "rate": 5.5, "world_pos": Vector2(-5260, -460), "desc": "🧬 뇌혈관장벽(BBB) 셔틀 이중항체 파이프라인"}
			],
			"theme_color": Color(0.25, 0.85, 0.5, 0.2),
			"is_top_bull": false
		}

		# 10시 (-4157, -2400): K-조선 & 해운
		sectors["shipbuilding"] = {
			"key": "shipbuilding",
			"name": "K-조선 & 해운",
			"sub_title": "LNG선 3년 만선 & 슈퍼사이클 파도",
			"direction_hint": "🕙 %s",
			"position": Vector2(-4157, -2400),
			"radius": 1250.0,
			"change_rate": 8.1,
			"lead_stock": "HD현대마린엔진 (+12.3%)",
			"stocks": [
				{"name": "HD한국조선해양", "code": "009540", "rate": 9.6, "world_pos": Vector2(-4157, -3050), "desc": "⚓ [글로벌 1위] 친환경 고부가가치 LNG선"},
				{"name": "삼성중공업", "code": "010140", "rate": 6.4, "world_pos": Vector2(-3697, -2860), "desc": "🌊 해양 FLNG 독점 수주 릴레이"},
				{"name": "한화오션", "code": "042660", "rate": 8.1, "world_pos": Vector2(-3507, -2400), "desc": "🚢 미 해군 MRO 군함 정비 독점 진출"},
				{"name": "HD현대마린엔진", "code": "071970", "rate": 12.3, "world_pos": Vector2(-3697, -1940), "desc": "⚙️ 친환경 선박 엔진 공급망 장악"},
				{"name": "HMM", "code": "011200", "rate": 3.5, "world_pos": Vector2(-4157, -1750), "desc": "📦 글로벌 해운 운임 지수 반등 수혜"},
				{"name": "팬오션", "code": "028670", "rate": 4.1, "world_pos": Vector2(-4617, -1940), "desc": "🚢 글로벌 벌크선 운임 BDI 상승 최대 수혜"},
				{"name": "HJ중공업", "code": "097230", "rate": 5.8, "world_pos": Vector2(-4807, -2400), "desc": "⚓ 해군 특수선 및 친환경 컨테이너선 건조"},
				{"name": "현대힘스", "code": "460930", "rate": 7.2, "world_pos": Vector2(-4617, -2860), "desc": "🛠️ 선박 곡블록 및 조선 기자재 독점 생산"}
			],
			"theme_color": Color(0.2, 0.7, 0.9, 0.25),
			"is_top_bull": false
		}

		# 11시 (-2400, -4157): K-방산 & 우주
		sectors["defense"] = {
			"key": "defense",
			"name": "K-방산 & 우주",
			"sub_title": "자주포·전차·유도무기 글로벌 수출 철옹성",
			"direction_hint": "🕚 %s",
			"position": Vector2(-2400, -4157),
			"radius": 1250.0,
			"change_rate": 9.0,
			"lead_stock": "한화에어로스페이스 (+12.8%)",
			"stocks": [
				{"name": "한화에어로", "code": "012450", "rate": 12.8, "world_pos": Vector2(-2400, -4807), "desc": "🚀 [수출 대장] K9 자주포 & 천무 다연장"},
				{"name": "현대로템", "code": "064350", "rate": 10.5, "world_pos": Vector2(-1940, -4617), "desc": "🛡️ K2 흑표 전차 폴란드 수주 잭팟"},
				{"name": "LIG넥스원", "code": "079550", "rate": 8.9, "world_pos": Vector2(-1750, -4157), "desc": "🎯 천궁-II 요격 미사일 중동 수출"},
				{"name": "한국항공우주", "code": "047810", "rate": 5.2, "world_pos": Vector2(-1940, -3697), "desc": "✈️ KF-21 양산 돌입 & FA-50 경공격기"},
				{"name": "풍산", "code": "103140", "rate": 7.4, "world_pos": Vector2(-2400, -3507), "desc": "💣 전 세계 탄약 품귀 구리 방산 수혜"},
				{"name": "쎄트렉아이", "code": "099320", "rate": 6.9, "world_pos": Vector2(-2860, -3697), "desc": "🛰️ 초고해상도 지구관측 인공위성 탑재체"},
				{"name": "한화시스템", "code": "272210", "rate": 7.8, "world_pos": Vector2(-3050, -4157), "desc": "📡 AESA 능동위상배열 레이더 국방 지휘통제"},
				{"name": "현대위아", "code": "011210", "rate": 4.9, "world_pos": Vector2(-2860, -4617), "desc": "🛡️ 함포·곡사포 전술 화포 체계 및 무인 포탑"}
			],
			"theme_color": Color(0.9, 0.3, 0.5, 0.25),
			"is_top_bull": false
		}

		sector_news_dict = {
			"semiconductor": [
				"HBM4 및 3nm 초미세 공정 주문 폭증으로 글로벌 팹 가동률 95% 돌파",
				"빅테크 4사 AI 데이터센터 증설 투자(CAPEX) 전년비 +45% 증액 발표",
				"서버용 고대역폭 메모리 D램 및 eSSD 공급 부족에 판가 두 자릿수 인상"
			],
			"power_grid": [
				"미국 노후 전력망 교체 및 AI 데이터센터 전력 소비 10배 폭증... 변압기 수주 3년 밀려",
				"체코 신규 원전 24조원 본계약 체결 임박... K-원전 주기기 수출 르네상스",
				"초고압 직류송전(HVDC) 및 차세대 SMR 고속로 국가 전략 프로젝트 가동"
			],
			"automotive": [
				"현대차그룹 글로벌 판매 3위 굳히기... 북미 하이브리드 & SUV 판매 사상 최대",
				"현대차 인도 법인 IPO 사상 최대 청약 증거금 몰리며 글로벌 가치 재평가",
				"SDV 소프트웨어 중심 자동차 전환 가속... 자율주행 전장 부품 수주 10조 돌파"
			],
			"robot_ai": [
				"피지컬 AI 협동로봇 공장 자동화 수요 급증... 로봇 부품 국산화율 80% 달성",
				"실외 자율주행 배달로봇 상용화 규제 해소... 도심 물류 라스트마일 투입",
				"의료 및 보행 재활 웨어러블 로봇 글로벌 병원 처방 및 미국 FDA 승인"
			],
			"gaming_platform": [
				"크래프톤 배틀그라운드 글로벌 트래픽 역주행... 인도 및 서구권 매출 랠리",
				"네이버-카카오 생성형 AI 검색 및 비즈니스 에이전트 서비스 전면 상용화",
				"게임스컴 호평 글로벌 콘솔 대작 신작 릴리즈 임박... K-게임 수출 확대"
			],
			"entertainment": [
				"BTS 완전체 컴백 기대 및 K-POP 스타디움 월드투어 릴레이 티켓 매진",
				"글로벌 음원 스트리밍 차트 싹쓸이... K-콘텐츠 플랫폼 위버스 유료 가입자 폭증",
				"글로벌 OTT K-드라마 텐트폴 라인업 방영 및 해외 판권 계약 사상 최고가"
			],
			"battery": [
				"전기차 캐즘 장기화 우려에 양극재 판가 하락... 공매도 집중 공격",
				"글로벌 완성차 배터리 투자 속도 조절... 리튬 및 메탈 원가 변동성 확대",
				"북미 IRA 현지화 전해액 및 실리콘 음극재 공급사 중심 차별화 시도"
			],
			"food_consumer": [
				"불닭볶음면 글로벌 메가히트로 삼양식품 해외 매출 80% 돌파... 수출 신기록",
				"K-뷰티 인디 브랜드 미국·유럽 올리브영 완판 랠리... 화장품 ODM 풀가동",
				"신라면 및 K-과자 글로벌 대형마트 입점 확대로 K-푸드 세계적 위상 강화"
			],
			"finance": [
				"금융위 밸류업 프로그램 가동... 조 단위 자사주 전격 소각 및 배당 확대",
				"저PBR 은행·지주사 주주환원율 40~50% 상향 로드맵 발표",
				"외국인 순매수 지속... 금융 섹터 시가총액 사상 최고치 경신"
			],
			"bio": [
				"알테오젠 피하주사(SC) 제형 변경 플랫폼 글로벌 빅파마 독점 계약 체결",
				"국산 신약 렉라자 미국 FDA 승인 후 처방 본격 확대... 마일스톤 유입",
				"차세대 ADC 항암 플랫폼 및 비만치료제 신약 후보물질 조 단위 기술이전"
			],
			"shipbuilding": [
				"LNG 운반선 3년 치 도크 만선... 선가 사상 최고치 슈퍼사이클 도래",
				"미 해군 군함 MRO 유지보수 정비 사업 독점 계약 체결",
				"친환경 암모니아·메탄올 추진선 신규 발주 폭증으로 영업이익률 두 자릿수"
			],
			"defense": [
				"K9 자주포 및 천무 다연장 유럽·중동 30조원 수주잔고 확보",
				"K2 흑표 전차 2차 본계약 체결 임박... K-방산 방호력 세계적 입증",
				"천궁-II 중동 방공망 수출 릴레이 및 초고해상도 감시위성 우주 발사 성공"
			]
		}
		
		stock_news_dict = {
			"한미반도체": ["HBM Dual TC 본더 공급 독점 계약", "글로벌 패키징 팹라인 증설 수혜"],
			"SK하이닉스": ["5세대 HBM3E 세계 최초 대량 양산 납품", "D램 영업이익률 40% 돌파 흑자"],
			"삼성전자": ["3nm 파운드리 차세대 수율 안정화", "CXL 및 차세대 HBM4 개발 가속"],
			"HPSP": ["고압수소열처리 독점 공급망 견고", "파운드리 선단공정 필수 장비 선정"],
			"리노공업": ["글로벌 빅테크 신규 칩 테스트 소켓 독점", "영업이익률 45% 돌파 캐시카우"],
			"이수페타시스": ["AI 가속기용 초다층 MLB 기판 수주 폭증", "글로벌 빅테크향 직납 확대"],
			"제주반도체": ["온디바이스 AI 저전력 메모리 독점", "글로벌 IoT 칩셋 탑재 급증"],
			"가온칩스": ["일본 빅테크 AI ASIC 디자인하우스 수주", "삼성 파운드리 최우수 파트너"],
			"HD현대일렉트릭": ["북미 500kV 초고압 변압기 3년 수주잔고", "사상 최대 영업이익률 20% 경신"],
			"두산에너빌리티": ["체코 원전 주기기 제작 독점권 확보", "가스터빈 및 차세대 SMR 수주"],
			"LS ELECTRIC": ["북미 AI 데이터센터 배전 시스템 잭팟", "초고압 변압기 전용 공장 증설"],
			"효성중공업": ["미국 테네시 변압기 팩토리 풀가동", "유럽 해상풍력 전력망 공급"],
			"한전KPS": ["체코 원전 유지보수 및 정비 독점 계약", "국내외 화력·원자력 정비 캐시카우"],
			"일진전기": ["미국 유틸리티향 500kV 초고압 변압기 수주", "HVDC 해저케이블 생산 본격화"],
			"우진엔텍": ["원전 계측제어 설비 정비 원천기술 독점", "체코 원전 수출 참여 확정"],
			"제룡전기": ["미국 배전 PAD 변압기 수출 비중 85%", "역대 최고 영업이익률 기록"],
			"현대차": ["글로벌 하이브리드 판매 40% 급증", "인도 법인 사상 최대 규모 상장 성공"],
			"기아": ["영업이익률 13% 글로벌 완성차 1위", "EV3 전기차 유럽 판매 호조"],
			"현대모비스": ["차세대 전동화 부품 및 전장 수주 12조", "글로벌 완성차 수주 비중 확대"],
			"HL만도": ["북미 선도 EV 조향 및 제동 시스템 공급", "자율주행 주행보조 시스템 확대"],
			"한온시스템": ["글로벌 히트펌프 열관리 시스템 1위", "하이브리드·전기차 동시 수혜"],
			"현대오토에버": ["현대차그룹 차량용 SW 모빌진 표준화", "스마트팩토리 및 클라우드 매출 급증"],
			"한국타이어": ["고수익 EV 전용 아이온(iON) 타이어 1위", "글로벌 완성차 신차용 타이어 공급"],
			"삼기이브": ["고안전성 배터리 팩 엔드플레이트 독점", "북미 현지 공장 본격 가동"],
			"두산로보틱스": ["협동로봇 라인업 글로벌 점유율 확대", "스마트 팩토리 자동화 솔루션 공급"],
			"레인보우로보": ["삼성전자와 휴머노이드 로봇 협력", "사족보행 로봇 국방 솔루션 개발"],
			"로보티즈": ["실외 자율주행 배달로봇 도심 운행", "로봇 전용 액추에이터 글로벌 80% 탑재"],
			"엔젤로보틱스": ["웨어러블 재활 보행로봇 상급종합병원 공급", "산업용 근력보조 슈트 대기업 납품"],
			"루닛": ["AI 암 진단 솔루션 미국 보험 수가 등재", "글로벌 의료기기 기업과 파트너십"],
			"유진로봇": ["자율주행 물류 로봇(AMR) 유럽 수출", "스마트 물류창고 자동화 공급"],
			"에스피지": ["로봇용 초정밀 감속기 국산화 성공", "협동로봇 기업 대상 납품 확대"],
			"에스비비테크": ["하모닉 타입 초정밀 감속기 양산", "국방 및 로봇 부품 공급 가속"],
			"크래프톤": ["배틀그라운드 인도 및 글로벌 역대급 트래픽", "다크앤다커 모바일 신작 기대감"],
			"NAVER": ["생성형 AI 하이퍼클로바X 검색 적용", "클라우드 및 웹툰 글로벌 매출 성장"],
			"카카오": ["새로운 AI 에이전트 카나나 서비스 런칭", "톡비즈 광고 및 커머스 견조"],
			"넷마블": ["나 혼자만 레벨업 글로벌 매출 1위", "하반기 기대작 신작 라인업 가동"],
			"엔씨소프트": ["TL 글로벌 스팀 동접자 흥행 돌풍", "신작 슈팅 및 전략 게임 출시 예고"],
			"펄어비스": ["붉은사막 게임스컴 시연 폭발적 반응", "글로벌 콘솔 대작 퍼블리싱 가속"],
			"위메이드": ["레전드 오브 이미르 출시 기대감", "미르 IP 라이선스 및 블록체인 매출"],
			"카카오게임즈": ["오딘 및 신작 크로노 오디세이 개발", "글로벌 멀티플랫폼 퍼블리싱 강화"],
			"하이브": ["BTS 2025 완전체 컴백 플랜 본격화", "위버스 멤버십 유료 구독 모델 안착"],
			"JYP Ent.": ["스트레이키즈 빌보드 5연속 1위", "신인 걸그룹 글로벌 데뷔 프로젝트"],
			"에스엠": ["에스파 슈퍼노바 글로벌 음원 롱런", "라이즈·NCT 위시 팬덤 급성장"],
			"와이지엔터": ["베이비몬스터 글로벌 차트 진입 돌풍", "블랙핑크 완전체 활동 재개 기대"],
			"CJ ENM": ["티빙 유료 가입자 500만 돌파 흑자", "글로벌 K-콘텐츠 유통 및 스튜디오"],
			"스튜디오드래곤": ["글로벌 OTT 동시 방영 텐트폴 라인업", "해외 리메이크 판권 판매 호조"],
			"디어유": ["버블 팬덤 플랫폼 글로벌 아티스트 영입", "미국 및 일본 시장 진출 본격화"],
			"콘텐트리중앙": ["메가박스 흥행작 배급 및 관객 회복", "드라마 제작 스튜디오 실적 턴어라운드"],
			"에코프로비엠": ["하이니켈 양극재 북미 현지화 전략", "단결정 양극재 차세대 라인 가동"],
			"에코프로": ["리튬·전구체 소재 수직계열화 완성", "폐배터리 리사이클링 밸류체인"],
			"LG에너지솔루션": ["북미 합작 팩토리 가동률 순차 정상화", "LFP 배터리 및 대규모 ESS 공급"],
			"POSCO홀딩스": ["아르헨티나 리튬 염호 1단계 상업 생산", "철강 본원 경쟁력 및 밸류업"],
			"포스코퓨처엠": ["실리콘 음극재 및 고전압 미드니켈 양극재", "포스코그룹 소재 시너지 가속"],
			"엔켐": ["북미 전해액 시장 점유율 1위 선점", "미국 현지 공장 3배 증설"],
			"대주전자재료": ["글로벌 완성차향 실리콘 음극재 공급", "차세대 배터리 용량 극대화"],
			"금양": ["4695 원통형 배터리 드림팩토리 준공", "몽골 리튬 광산 채굴 추진"],
			"삼양식품": ["불닭볶음면 미국 월마트 완판 행진", "밀양 2공장 증설로 수출 물량 확대"],
			"농심": ["신라면 해외 매출 비중 60% 돌파", "미국 3공장 설립 및 글로벌 물류 확장"],
			"오리온": ["초코파이 베트남·러시아·인도 맹활약", "영업이익률 17% 글로벌 제과 1위"],
			"CJ제일제당": ["비비고 만두 북미 시장 1위 독주", "K-스트리트 푸드 글로벌 유통망 입점"],
			"아모레퍼시픽": ["코스알엑스 편입으로 서구권 매출 폭증", "라네즈 립마스크 글로벌 1위"],
			"코스맥스": ["글로벌 1위 화장품 ODM 주문 폭주", "국내외 인디 뷰티 고객사 1000곳"],
			"한국콜마": ["글로벌 선케어 자외선차단제 독점", "미국 및 캐나다 공장 현지화 생산"],
			"빙그레": ["메로나·바나나맛우유 미국 코스트코 입점", "해외 수출 실적 사상 최대 달성"],
			"KB금융": ["1조원 규모 자사주 매입 및 소각", "분기 배당 균등화 및 ROE 개선"],
			"신한지주": ["주주환원율 40% 조기 달성 로드맵", "비은행 부문 견조한 이익 체력"],
			"메리츠금융지주": ["주주환원율 50% 약속 3년 연속 이행", "자기자본이익률(ROE) 업계 최고"],
			"하나금융지주": ["저PBR 해소 및 해외 거점 순익 증대", "분기 배당 확대 및 밸류업"],
			"삼성물산": ["보유 자사주 전량 소각 계획 발표", "바이오·건설·친환경 에너지 신사업"],
			"삼성생명": ["PBR 0.5배 극저평가 해소 밸류업 수혜", "삼성전자 지분 가치 대비 매력"],
			"미래에셋증권": ["주주환원율 35% 이상 보통주 매입 소각", "해외 주식 예탁자산 사상 최대"],
			"우리금융지주": ["동양생명·ABL생명 인수로 포트폴리오 완성", "CET1 비율 개선 및 분기 배당"],
			"알테오젠": ["키트루다 피하주사(SC) 독점 라이선스", "글로벌 빅파마 5곳과 플랫폼 기술수출"],
			"삼성바이오로직스": ["송도 5공장 가동 및 글로벌 CDMO 1위", "수주잔고 16조원 돌파"],
			"셀트리온": ["짐펜트라 미국 PBM 처방집 80% 이상 등재", "유플라이마 유럽 점유율 1위"],
			"유한양행": ["렉라자 미국 FDA 승인 및 마일스톤 유입", "글로벌 얀센과 병용요법 1차 치료제"],
			"HLB": ["리보세라닙 간암신약 FDA 서류 보완 완료", "NCCN 가이드라인 등재 권고"],
			"리가켐바이오": ["얀센향 2.2조원 기술수출 계약금 수령", "차세대 ADC 링커 플랫폼 독점 공급"],
			"삼천당제약": ["경구용 GLP-1 비만치료제 글로벌 계약", "아일리아 바이오시밀러 유럽 공급 승인"],
			"에이비엘바이오": ["그랩바디 BBB 이중항체 임상 순항", "다국적 제약사 기술이전 협상"],
			"HD한국조선해양": ["LNG선 3년 치 도크 만선 및 선가 상승", "친환경 고부가가치 선박 수주 독점"],
			"삼성중공업": ["해양 FLNG 2기 연속 수주 잭팟", "연간 영업이익 4000억 흑자 전환"],
			"한화오션": ["미 해군 MRO 군함 정비 독점 사업자", "특수선 잠수함 글로벌 수출"],
			"HD현대마린엔진": ["선박 엔진 부품 및 친환경 엔진 풀가동", "영업이익률 두 자릿수 호실적"],
			"HMM": ["글로벌 해운 운임지수(SCFI) 반등", "친환경 컨테이너선 선대 확장"],
			"팬오션": ["벌크선 발틱운임지수(BDI) 급등 수혜", "LNG 벙커링선 장기 용선 계약"],
			"HJ중공업": ["해군 고속정 및 특수선 연속 수주", "친환경 컨테이너선 건조 도크 확보"],
			"현대힘스": ["선박 곡블록 생산능력 국내 1위", "도크 풀가동 및 조선 기자재 단가 인상"],
			"한화에어로": ["K9 자주포 및 천무 30조원 수주잔고", "누리호 고도화 사업 총괄 주관"],
			"현대로템": ["폴란드 K2 흑표 전차 2차 계약 8조원", "루마니아 전차 수출 협상 가속"],
			"LIG넥스원": ["사우디·이라크 천궁-II 7조원 수출", "미국 고스트로보틱스 인수로 사족보행 로봇"],
			"한국항공우주": ["KF-21 보라매 공군 1차 양산 계약 2조원", "FA-50 경공격기 글로벌 수출"],
			"풍산": ["155mm 포탄 글로벌 재고 고갈로 수출 급증", "구리 가격 상승과 방산 마진 극대화"],
			"쎄트렉아이": ["초고해상도 지구관측 위성 스페이스아이-T", "한화 우주 밸류체인 핵심 감시위성"],
			"한화시스템": ["KF-21 AESA 능동위상배열 레이더 양산", "우주 저궤도 위성통신망 해외 수출"],
			"현대위아": ["K2 전차 주포 및 K9 자주포 무장 독점", "모빌리티 및 방산 부품 동시 성장"]
		}
		
		news_pool = [
			{"headline": "📢 [속보] 12시 반도체 밸리로 전진하세요! 엔비디아 대량 수주 체결!", "sector": "semiconductor", "type": "buff", "duration": 15.0},
			{"headline": "⚡ [속보] 1시 전력망·원전에 미 빅테크 러브콜! 변압기 완판 폭등!", "sector": "power_grid", "type": "buff", "duration": 15.0},
			{"headline": "🚗 [속보] 2시 미래차 현대차·기아 글로벌 판매 신기록! 전장 부품 잭팟!", "sector": "automotive", "type": "buff", "duration": 15.0},
			{"headline": "🤖 [속보] 3시 로봇 파크 협동로봇 국책 과제 선정! 상용화 가속!", "sector": "robot_ai", "type": "buff", "duration": 15.0},
			{"headline": "🎮 [속보] 4시 게임·플랫폼 크래프톤 배그 인도 역대급 트래픽 폭발!", "sector": "gaming_platform", "type": "buff", "duration": 15.0},
			{"headline": "🎵 [속보] 5시 K-엔터 하이브 BTS 컴백 기대감! 글로벌 투어 완판!", "sector": "entertainment", "type": "buff", "duration": 15.0},
			{"headline": "⚠️ [경고] 6시 2차전지 광산에 공매도 세력 대규모 급습! 진입 주의!", "sector": "battery", "type": "debuff", "duration": 15.0},
			{"headline": "🍜 [속보] 7시 K-푸드 삼양 불닭볶음면 글로벌 품귀! 수출 신기록 랠리!", "sector": "food_consumer", "type": "buff", "duration": 15.0},
			{"headline": "💰 [속보] 8시 금융·밸류업 조 단위 자사주 전격 소각! 고배당 랠리!", "sector": "finance", "type": "buff", "duration": 15.0},
			{"headline": "💉 [속보] 9시 바이오 랩 알테오젠 SC 제형 독점 수주 랠리!", "sector": "bio", "type": "buff", "duration": 15.0},
			{"headline": "🚢 [속보] 10시 K-조선 도크 만선! 미 해군 MRO 수주 잭팟!", "sector": "shipbuilding", "type": "buff", "duration": 15.0},
			{"headline": "🚀 [속보] 11시 K-방산 유럽·중동 무기 수출 릴레이! 주가 사상 최고치!", "sector": "defense", "type": "buff", "duration": 15.0}
		]
		
	else:
		# US Market 12 Radial Clock Mega Sectors (Distance ~4800)
		# 12시 (0, -4800): 실리콘밸리 AI 칩
		sectors["ai_chips"] = {
			"key": "ai_chips",
			"name": "실리콘밸리 AI 칩",
			"sub_title": "GPU 가속 컴퓨팅 & 최첨단 파운드리 본류",
			"direction_hint": "🕛 12시",
			"position": Vector2(0, -4800),
			"radius": 1250.0,
			"change_rate": 11.4,
			"lead_stock": "NVIDIA (+14.2%)",
			"stocks": [
				{"name": "NVIDIA", "code": "NVDA", "rate": 14.2, "world_pos": Vector2(0, -5450), "desc": "🔥 [NVDA 떡상 정상] 블랙웰 주문 폭주!"},
				{"name": "Broadcom", "code": "AVGO", "rate": 8.5, "world_pos": Vector2(460, -5260), "desc": "🚀 커스텀 ASIC 칩 & 이더넷 스위치"},
				{"name": "AMD", "code": "AMD", "rate": 5.8, "world_pos": Vector2(650, -4800), "desc": "MI300X AI 가속기 빅테크 공급 확대"},
				{"name": "TSMC", "code": "TSM", "rate": 7.2, "world_pos": Vector2(460, -4340), "desc": "3나노 파운드리 및 CoWoS 풀가동"},
				{"name": "Micron", "code": "MU", "rate": 9.0, "world_pos": Vector2(0, -4150), "desc": "HBM3E 메모리 2025 완판 공급"},
				{"name": "Qualcomm", "code": "QCOM", "rate": 4.8, "world_pos": Vector2(-460, -4340), "desc": "스냅드래곤 온디바이스 AI 칩셋 1위"},
				{"name": "Arm", "code": "ARM", "rate": 6.5, "world_pos": Vector2(-650, -4800), "desc": "v9 아키텍처 로열티 라이선스 급성장"},
				{"name": "Intel", "code": "INTC", "rate": 2.1, "world_pos": Vector2(-460, -5260), "desc": "18A 차세대 파운드리 국책 보조금 수혜"}
			],
			"theme_color": Color(0.2, 1.0, 0.4, 0.28),
			"is_top_bull": true
		}

		# 1시 (2400, -4157): AI 전력망 & SMR
		sectors["ai_power"] = {
			"key": "ai_power",
			"name": "AI 전력망 & SMR",
			"sub_title": "빅테크 데이터센터 전력 품귀 & 원전 르네상스",
			"direction_hint": "🕐 %s",
			"position": Vector2(2400, -4157),
			"radius": 1250.0,
			"change_rate": 13.8,
			"lead_stock": "Oklo (+18.6%)",
			"stocks": [
				{"name": "Constellation", "code": "CEG", "rate": 15.2, "world_pos": Vector2(2400, -4807), "desc": "☢️ [MS 20년 PPA] 스리마일 원전 재가동"},
				{"name": "Vistra", "code": "VST", "rate": 12.4, "world_pos": Vector2(2860, -4617), "desc": "⚡ AI 데이터센터 전력 공급 연초대비 250% 폭등"},
				{"name": "Oklo", "code": "OKLO", "rate": 18.6, "world_pos": Vector2(3050, -4157), "desc": "🔥 샘 올트먼의 차세대 SMR 고속로 핵분열"},
				{"name": "GE Vernova", "code": "GEV", "rate": 9.1, "world_pos": Vector2(2860, -3697), "desc": "🏭 가스터빈 및 전력 그리드 장비 독점"},
				{"name": "NextEra", "code": "NEE", "rate": 4.5, "world_pos": Vector2(2400, -3507), "desc": "🔋 대규모 신재생 및 ESS 유틸리티 1위"},
				{"name": "Cameco", "code": "CCJ", "rate": 8.2, "world_pos": Vector2(1940, -3697), "desc": "⛏️ 글로벌 1위 우라늄 채굴 쇼티지 수혜"},
				{"name": "NuScale", "code": "SMR", "rate": 11.4, "world_pos": Vector2(1750, -4157), "desc": "☢️ 미국 NRC 설계 인증 유일 SMR 개발사"},
				{"name": "NRG", "code": "NRG", "rate": 6.8, "world_pos": Vector2(1940, -4617), "desc": "🔌 텍사스 전력 시장 현물 판가 급등 호재"}
			],
			"theme_color": Color(1.0, 0.65, 0.1, 0.26),
			"is_top_bull": false
		}

		# 2시 (4157, -2400): 국방 AI & 방산
		sectors["defense_tech"] = {
			"key": "defense_tech",
			"name": "국방 AI & 방산",
			"sub_title": "전장 AI 지휘소 & 스텔스 군수 우주 복합체",
			"direction_hint": "🕑 %s",
			"position": Vector2(4157, -2400),
			"radius": 1250.0,
			"change_rate": 6.2,
			"lead_stock": "Palantir (+14.6%)",
			"stocks": [
				{"name": "Palantir", "code": "PLTR", "rate": 14.6, "world_pos": Vector2(4157, -3050), "desc": "🧠 [AIP 랠리] 미 국방부 전장 AI 플랫폼 독점"},
				{"name": "Lockheed", "code": "LMT", "rate": 4.2, "world_pos": Vector2(4617, -2860), "desc": "🛩️ F-35 스텔스 전투기 & 국방 예산 최대 수혜"},
				{"name": "RTX", "code": "RTX", "rate": 3.8, "world_pos": Vector2(4807, -2400), "desc": "🛡️ 패트리어트 미사일 & 항공기 제트엔진"},
				{"name": "Northrop", "code": "NOC", "rate": 4.9, "world_pos": Vector2(4617, -1940), "desc": "🦅 B-21 차세대 스텔스 전략 폭격기"},
				{"name": "GeneralDynamics", "code": "GD", "rate": 3.1, "world_pos": Vector2(4157, -1750), "desc": "🚢 버지니아급 원자력 잠수함 제조"},
				{"name": "Boeing", "code": "BA", "rate": 2.5, "world_pos": Vector2(3697, -1940), "desc": "✈️ 상업용 민항기 인도 재개 & 방산 우주"},
				{"name": "Kratos", "code": "KTOS", "rate": 6.2, "world_pos": Vector2(3507, -2400), "desc": "🎯 발키리 스텔스 무인 전투 드론 양산"},
				{"name": "RocketLab", "code": "RKLB", "rate": 8.4, "world_pos": Vector2(3697, -2860), "desc": "🚀 일렉트론 로켓 발사 및 중대형 뉴트론"}
			],
			"theme_color": Color(0.3, 0.75, 0.7, 0.25),
			"is_top_bull": false
		}

		# 3시 (4800, 0): 매그니피센트 테크
		sectors["big_tech"] = {
			"key": "big_tech",
			"name": "매그니피센트 테크",
			"sub_title": "클라우드 & 스마트 디바이스 대로",
			"direction_hint": "🕒 %s",
			"position": Vector2(4800, 0),
			"radius": 1250.0,
			"change_rate": 3.2,
			"lead_stock": "Microsoft (+3.1%)",
			"stocks": [
				{"name": "Microsoft", "code": "MSFT", "rate": 3.1, "world_pos": Vector2(4800, -650), "desc": "Copilot 기업용 라이선스 증가"},
				{"name": "Apple", "code": "AAPL", "rate": 1.8, "world_pos": Vector2(5260, -460), "desc": "Apple Intelligence 기기 교체 슈퍼사이클"},
				{"name": "Alphabet", "code": "GOOGL", "rate": 2.5, "world_pos": Vector2(5450, 0), "desc": "Gemini AI 모델 검색 탑재"},
				{"name": "Meta", "code": "META", "rate": 4.2, "world_pos": Vector2(5260, 460), "desc": "Llama 3 AI 오픈소스 생태계"},
				{"name": "Amazon", "code": "AMZN", "rate": 2.9, "world_pos": Vector2(4800, 650), "desc": "AWS 클라우드 인프라 매출 가속"},
				{"name": "Oracle", "code": "ORCL", "rate": 5.8, "world_pos": Vector2(4340, 460), "desc": "OCI 멀티클라우드 수주잔고 사상 최대"},
				{"name": "IBM", "code": "IBM", "rate": 3.5, "world_pos": Vector2(4150, 0), "desc": "왓슨x 생성형 AI 컨설팅 및 하이브리드 클라우드"},
				{"name": "Salesforce", "code": "CRM", "rate": 2.8, "world_pos": Vector2(4340, -460), "desc": "Agentforce 자율형 비즈니스 AI 에이전트"}
			],
			"theme_color": Color(0.4, 0.8, 1.0, 0.22),
			"is_top_bull": false
		}

		# 4시 (4157, 2400): 사이버 보안 & SaaS
		sectors["cyber_saas"] = {
			"key": "cyber_saas",
			"name": "사이버 보안 & SaaS",
			"sub_title": "클라우드 제로 트러스트 & 엔터프라이즈 소프트웨어",
			"direction_hint": "🕓 %s",
			"position": Vector2(4157, 2400),
			"radius": 1250.0,
			"change_rate": 5.4,
			"lead_stock": "CrowdStrike (+8.1%)",
			"stocks": [
				{"name": "CrowdStrike", "code": "CRWD", "rate": 8.1, "world_pos": Vector2(4157, 1750), "desc": "🛡️ 팔콘 플랫폼 엔드포인트 보안 1위"},
				{"name": "PaloAlto", "code": "PANW", "rate": 5.2, "world_pos": Vector2(4617, 1940), "desc": "🔒 프리시전 AI 기반 네트워크 방화벽 통합"},
				{"name": "ServiceNow", "code": "NOW", "rate": 4.8, "world_pos": Vector2(4807, 2400), "desc": "💼 워크플로우 자동화 AI 플랫폼 고마진"},
				{"name": "Snowflake", "code": "SNOW", "rate": 6.2, "world_pos": Vector2(4617, 2860), "desc": "❄️ 데이터 클라우드 분석 AI 모델 서빙"},
				{"name": "Datadog", "code": "DDOG", "rate": 5.9, "world_pos": Vector2(4157, 3050), "desc": "📊 클라우드 인프라 모니터링 구독 성장"},
				{"name": "MongoDB", "code": "MDB", "rate": 4.1, "world_pos": Vector2(3697, 2860), "desc": "🍃 최신 NoSQL 도큐먼트 데이터베이스"},
				{"name": "Cloudflare", "code": "NET", "rate": 6.8, "world_pos": Vector2(3507, 2400), "desc": "🌐 글로벌 엣지 CDN 및 DDoS 분산 방어"},
				{"name": "Zscaler", "code": "ZS", "rate": 5.0, "world_pos": Vector2(3697, 1940), "desc": "☁️ 클라우드 제로트러스트 보안 교환소"}
			],
			"theme_color": Color(0.2, 0.9, 0.7, 0.24),
			"is_top_bull": false
		}

		# 5시 (2400, 4157): 미디어 & 엔터테인먼트
		sectors["media_entertain"] = {
			"key": "media_entertain",
			"name": "미디어 & 엔터테인먼트",
			"sub_title": "글로벌 스트리밍 & 블록버스터 게이밍 제국",
			"direction_hint": "🕔 %s",
			"position": Vector2(2400, 4157),
			"radius": 1250.0,
			"change_rate": 4.6,
			"lead_stock": "Netflix (+6.8%)",
			"stocks": [
				{"name": "Netflix", "code": "NFLX", "rate": 6.8, "world_pos": Vector2(2400, 3507), "desc": "🍿 글로벌 OTT 독점 & 광고형 요금제 흑자"},
				{"name": "Disney", "code": "DIS", "rate": 3.5, "world_pos": Vector2(2860, 3697), "desc": "🏰 디즈니+ 스트리밍 흑자 & 테마파크 수익"},
				{"name": "Spotify", "code": "SPOT", "rate": 7.2, "world_pos": Vector2(3050, 4157), "desc": "🎵 글로벌 6억 음원 스트리밍 유료 구독 1위"},
				{"name": "WarnerBros", "code": "WBD", "rate": 2.8, "world_pos": Vector2(2860, 4617), "desc": "🎬 맥스(MAX) 스트리밍 글로벌 진출"},
				{"name": "EA", "code": "EA", "rate": 3.9, "world_pos": Vector2(2400, 4807), "desc": "⚽ EA 스포츠 FC 및 글로벌 스포츠 라이선스"},
				{"name": "TakeTwo", "code": "TTWO", "rate": 5.8, "world_pos": Vector2(1940, 4617), "desc": "🎮 GTA 6 전 세계 최고 기대작 릴리즈 예고"},
				{"name": "Roblox", "code": "RBLX", "rate": 6.4, "world_pos": Vector2(1750, 4157), "desc": "🕹️ 일간 활성 이용자 8000만 메타버스 플랫폼"},
				{"name": "AppLovin", "code": "APP", "rate": 9.2, "world_pos": Vector2(1940, 3697), "desc": "📱 AI 모바일 광고 엔진 액손 2.0 폭풍 성장"}
			],
			"theme_color": Color(0.85, 0.35, 0.8, 0.24),
			"is_top_bull": false
		}

		# 6시 (0, 4800): 전기차 & 청정에너지
		sectors["ev_auto"] = {
			"key": "ev_auto",
			"name": "전기차 & 청정에너지",
			"sub_title": "가격 인하 치킨게임 & 차세대 청정 모빌리티",
			"direction_hint": "🕕 %s",
			"position": Vector2(0, 4800),
			"radius": 1250.0,
			"change_rate": -6.4,
			"lead_stock": "Tesla (-7.8%)",
			"stocks": [
				{"name": "Tesla", "code": "TSLA", "rate": -7.8, "world_pos": Vector2(0, 4150), "desc": "⚠️ [변동성 제왕] FSD 로보택시 및 옵티머스"},
				{"name": "Rivian", "code": "RIVN", "rate": -8.5, "world_pos": Vector2(460, 4340), "desc": "폭스바겐 50억달러 합작 투자 파트너십"},
				{"name": "Lucid", "code": "LCID", "rate": -9.2, "world_pos": Vector2(650, 4800), "desc": "사우디 PIF 투자 기반 럭셔리 EV 그래비티"},
				{"name": "Enphase", "code": "ENPH", "rate": -5.4, "world_pos": Vector2(460, 5260), "desc": "태양광 마이크로 인버터 수요 바닥 통과"},
				{"name": "Albemarle", "code": "ALB", "rate": -6.1, "world_pos": Vector2(0, 5450), "desc": "글로벌 전기차 배터리용 수산화리튬 공급"},
				{"name": "Ford", "code": "F", "rate": -2.8, "world_pos": Vector2(-460, 5260), "desc": "하이브리드 F-150 트럭 및 내연기관 캐시카우"},
				{"name": "GeneralMotors", "code": "GM", "rate": -1.9, "world_pos": Vector2(-650, 4800), "desc": "자사주 매입 100억달러 및 얼티엄 EV"},
				{"name": "QuantumScape", "code": "QS", "rate": -4.5, "world_pos": Vector2(-460, 4340), "desc": "차세대 전고체 배터리 상용화 프로토타입"}
			],
			"theme_color": Color(0.2, 0.5, 1.0, 0.28),
			"is_top_bull": false
		}

		# 7시 (-2400, 4157): 오일 & 천연가스
		sectors["traditional_energy"] = {
			"key": "traditional_energy",
			"name": "오일 & 천연가스",
			"sub_title": "글로벌 에너지 메이저 & 정유 배당 황금 요새",
			"direction_hint": "🕖 %s",
			"position": Vector2(-2400, 4157),
			"radius": 1250.0,
			"change_rate": 4.2,
			"lead_stock": "ExxonMobil (+4.8%)",
			"stocks": [
				{"name": "ExxonMobil", "code": "XOM", "rate": 4.8, "world_pos": Vector2(-2400, 3507), "desc": "🛢️ [에너지 제왕] 파이오니어 합병 셰일오일 1위"},
				{"name": "Chevron", "code": "CVX", "rate": 3.9, "world_pos": Vector2(-1940, 3697), "desc": "⛽ 헤스 인수 및 가이아나 유전 생산량 급증"},
				{"name": "ConocoPhillips", "code": "COP", "rate": 4.2, "world_pos": Vector2(-1750, 4157), "desc": "🌍 저원가 셰일 오일 & LNG 장기 공급 계약"},
				{"name": "Schlumberger", "code": "SLB", "rate": 3.5, "world_pos": Vector2(-1940, 4617), "desc": "🛠️ 글로벌 유전 시추 디지털 소프트웨어"},
				{"name": "EOG", "code": "EOG", "rate": 3.8, "world_pos": Vector2(-2400, 4807), "desc": "⛏️ 미국 퍼미안 분지 최고 효율 셰일 기업"},
				{"name": "Occidental", "code": "OXY", "rate": 4.5, "world_pos": Vector2(-2860, 4617), "desc": "🪙 워런 버핏 최대 보유 지분 & 탄소 포집"},
				{"name": "Marathon", "code": "MPC", "rate": 5.1, "world_pos": Vector2(-3050, 4157), "desc": "🏭 미국 정제마진 회복 & 대규모 자사주 소각"},
				{"name": "Valero", "code": "VLO", "rate": 4.6, "world_pos": Vector2(-2860, 3697), "desc": "🚚 북미 정유 및 바이오디젤 저원가 정제소"}
			],
			"theme_color": Color(0.9, 0.55, 0.1, 0.25),
			"is_top_bull": false
		}

		# 8시 (-4157, 2400): 월가 메가뱅크 & 핀테크
		sectors["wall_street"] = {
			"key": "wall_street",
			"name": "월가 메가뱅크 & 핀테크",
			"sub_title": "금리 피벗 & 사상 최대 자산운용 수수료",
			"direction_hint": "🕗 %s",
			"position": Vector2(-4157, 2400),
			"radius": 1250.0,
			"change_rate": 3.8,
			"lead_stock": "Goldman Sachs (+4.8%)",
			"stocks": [
				{"name": "JPMorgan", "code": "JPM", "rate": 3.6, "world_pos": Vector2(-4157, 1750), "desc": "🏛️ [월가 제왕] 제이미 다이먼의 사상 최대 순익"},
				{"name": "GoldmanSachs", "code": "GS", "rate": 4.8, "world_pos": Vector2(-3697, 1940), "desc": "💼 글로벌 IB 인수합병 M&A 딜 회복"},
				{"name": "Berkshire", "code": "BRK.B", "rate": 2.4, "world_pos": Vector2(-3507, 2400), "desc": "📈 버핏의 3000억 달러 현금성 자산 요새"},
				{"name": "Visa", "code": "V", "rate": 2.8, "world_pos": Vector2(-3697, 2860), "desc": "💳 글로벌 디지털 결제 수수료 독점 캐시카우"},
				{"name": "Mastercard", "code": "MA", "rate": 3.1, "world_pos": Vector2(-4157, 3050), "desc": "💳 전 세계 30억 장 카드 해외 결제 수수료"},
				{"name": "BlackRock", "code": "BLK", "rate": 5.1, "world_pos": Vector2(-4617, 2860), "desc": "🪙 비트코인 현물 ETF 1위 & 10조달러 운용"},
				{"name": "Coinbase", "code": "COIN", "rate": 7.8, "world_pos": Vector2(-4807, 2400), "desc": "🚀 가상자산 제도권 편입 기관 거래소 1위"},
				{"name": "MicroStrategy", "code": "MSTR", "rate": 9.5, "world_pos": Vector2(-4617, 1940), "desc": "🪙 비트코인 25만 개 보유 나스닥 프록시 랠리"}
			],
			"theme_color": Color(0.9, 0.75, 0.2, 0.24),
			"is_top_bull": false
		}

		# 9시 (-4800, 0): 글로벌 헬스케어
		sectors["pharma"] = {
			"key": "pharma",
			"name": "글로벌 헬스케어",
			"sub_title": "GLP-1 비만치료제 서쪽 숲 & 차세대 신약",
			"direction_hint": "🕘 %s",
			"position": Vector2(-4800, 0),
			"radius": 1250.0,
			"change_rate": 3.8,
			"lead_stock": "Eli Lilly (+5.4%)",
			"stocks": [
				{"name": "EliLilly", "code": "LLY", "rate": 5.4, "world_pos": Vector2(-4800, -650), "desc": "💉 [시총 1조달러 도전] 마운자로·젭바운드 독주"},
				{"name": "NovoNordisk", "code": "NVO", "rate": 4.2, "world_pos": Vector2(-4340, -460), "desc": "🧪 위고비·오젬픽 글로벌 공급망 확대"},
				{"name": "AbbVie", "code": "ABBV", "rate": 2.1, "world_pos": Vector2(-4150, 0), "desc": "💊 스카이리치·린버크 면역학 치료제 신기록"},
				{"name": "Pfizer", "code": "PFE", "rate": 1.8, "world_pos": Vector2(-4340, 460), "desc": "🔬 비만 치료제 신약 파이프라인 개발 가속"},
				{"name": "Merck", "code": "MRK", "rate": 2.5, "world_pos": Vector2(-4800, 650), "desc": "🏆 키트루다 항암제 전 세계 1위 매출"},
				{"name": "Amgen", "code": "AMGN", "rate": 3.8, "world_pos": Vector2(-5260, 460), "desc": "🧬 월 1회 투여 차세대 비만치료제 마리타이드"},
				{"name": "Vertex", "code": "VRTX", "rate": 4.5, "world_pos": Vector2(-5450, 0), "desc": "🧪 낭포성 섬유증 및 유전자 가위 신약 승인"},
				{"name": "Gilead", "code": "GILD", "rate": 3.2, "world_pos": Vector2(-5260, -460), "desc": "💊 연 2회 투여 차세대 에이즈(HIV) 예방약"}
			],
			"theme_color": Color(0.2, 0.9, 0.6, 0.22),
			"is_top_bull": false
		}

		# 10시 (-4157, -2400): 리테일 & 소비재
		sectors["retail"] = {
			"key": "retail",
			"name": "리테일 & 소비재",
			"sub_title": "탄탄한 미국 내수 소비 & 경기방어주 요새",
			"direction_hint": "🕙 %s",
			"position": Vector2(-4157, -2400),
			"radius": 1250.0,
			"change_rate": 3.9,
			"lead_stock": "Costco (+4.5%)",
			"stocks": [
				{"name": "Walmart", "code": "WMT", "rate": 3.2, "world_pos": Vector2(-4157, -3050), "desc": "🛒 [유통 황제] 전자상거래 고성장 사상 최고가"},
				{"name": "Costco", "code": "COST", "rate": 4.5, "world_pos": Vector2(-3697, -2860), "desc": "📦 충성 유료 멤버십 기반 마르지 않는 현금흐름"},
				{"name": "Target", "code": "TGT", "rate": 2.8, "world_pos": Vector2(-3507, -2400), "desc": "🎯 당일 픽업 배송 및 PB 브랜드 마진 개선"},
				{"name": "HomeDepot", "code": "HD", "rate": 2.9, "world_pos": Vector2(-3697, -1940), "desc": "🏠 주택 개보수 및 인프라 소비 회복"},
				{"name": "McDonalds", "code": "MCD", "rate": 1.8, "world_pos": Vector2(-4157, -1750), "desc": "🍔 전 세계 4만 개 매장 글로벌 경기방어주"},
				{"name": "Starbucks", "code": "SBUX", "rate": 4.2, "world_pos": Vector2(-4617, -1940), "desc": "☕ 치폴레 브라이언 니콜 CEO 영입 턴어라운드"},
				{"name": "Nike", "code": "NKE", "rate": 3.1, "world_pos": Vector2(-4807, -2400), "desc": "👟 혁신 러닝화 라인업 재구축 & D2C 전략"},
				{"name": "CocaCola", "code": "KO", "rate": 1.9, "world_pos": Vector2(-4617, -2860), "desc": "🥤 글로벌 필수소비재 배당왕 60년 연속 증액"}
			],
			"theme_color": Color(0.85, 0.4, 0.75, 0.22),
			"is_top_bull": false
		}

		# 11시 (-2400, -4157): 산업재 & 글로벌 인프라
		sectors["industrial_infra"] = {
			"key": "industrial_infra",
			"name": "산업재 & 글로벌 인프라",
			"sub_title": "제조업 리쇼어링 & AI 전력망 인프라 슈퍼사이클",
			"direction_hint": "🕚 %s",
			"position": Vector2(-2400, -4157),
			"radius": 1250.0,
			"change_rate": 4.8,
			"lead_stock": "Caterpillar (+6.4%)",
			"stocks": [
				{"name": "Caterpillar", "code": "CAT", "rate": 6.4, "world_pos": Vector2(-2400, -4807), "desc": "🚜 [중장비 제왕] 글로벌 광산 & 인프라 붐"},
				{"name": "Deere", "code": "DE", "rate": 3.8, "world_pos": Vector2(-1940, -4617), "desc": "🌾 정밀 농업 자율주행 트랙터 스마트 솔루션"},
				{"name": "UnionPacific", "code": "UNP", "rate": 3.2, "world_pos": Vector2(-1750, -4157), "desc": "🚂 북미 대륙 횡단 화물 철도 독점 운송"},
				{"name": "UPS", "code": "UPS", "rate": 2.5, "world_pos": Vector2(-1940, -3697), "desc": "📦 글로벌 항공 및 육상 물류 효율화 흑자"},
				{"name": "Honeywell", "code": "HON", "rate": 3.9, "world_pos": Vector2(-2400, -3507), "desc": "🛩️ 항공우주 자동화 및 빌딩 제어 시스템"},
				{"name": "GEAerospace", "code": "GE", "rate": 5.8, "world_pos": Vector2(-2860, -3697), "desc": "✈️ 상업용 제트엔진 3만 개 유지보수 MRO"},
				{"name": "Emerson", "code": "EMR", "rate": 4.1, "world_pos": Vector2(-3050, -4157), "desc": "🏭 공장 자동화 및 데이터센터 열관리 솔루션"},
				{"name": "Eaton", "code": "ETN", "rate": 7.2, "world_pos": Vector2(-2860, -4617), "desc": "🔌 데이터센터 지능형 전력 배전 시스템 완판"}
			],
			"theme_color": Color(0.5, 0.7, 0.9, 0.25),
			"is_top_bull": false
		}

		sector_news_dict = {
			"ai_chips": ["Blackwell GPU 수요 폭발로 공급 완판", "3nm 파운드리 및 첨단 패키징 풀가동"],
			"ai_power": ["AI 데이터센터 전력 소비 10배 폭증... 전력주 폭등", "NRC 차세대 소형 모듈 원자로(SMR) 승인 가속"],
			"defense_tech": ["미 국방부 차세대 전장 AI 통합 지휘 시스템 예산 집행", "스텔스 전투기·무인 편대기 자율 AI 수주"],
			"big_tech": ["빅3 클라우드 AI 워크로드 매출 30% 급증", "온디바이스 AI 스마트폰 교체 슈퍼사이클 본격화"],
			"cyber_saas": ["글로벌 제로트러스트 보안 소프트웨어 구독 급증", "엔터프라이즈 AI 자동화 SaaS 마진율 40% 돌파"],
			"media_entertain": ["글로벌 스트리밍 유료 구독자 및 광고 수익 사상 최대", "블록버스터 차세대 콘솔 신작 게임 발매 예고"],
			"ev_auto": ["글로벌 전기차 가격 인하 경쟁 완화... 마진 저점 통과", "대규모 ESS 에너지저장장치 배터리 수주 급증"],
			"traditional_energy": ["글로벌 지정학 위기로 국제 유가 및 정제마진 반등", "미국 대형 셰일오일 기업 대규모 자사주 소각"],
			"wall_street": ["금리 인하 사이클 진입... M&A 자문 및 IPO 부활", "비트코인 현물 ETF 1위 및 10조달러 운용 자산"],
			"pharma": ["GLP-1 비만 치료제 글로벌 처방 급증 설비 증설", "경구용 비만약 임상 3상 데이터 호조 기대감"],
			"retail": ["미국 견조한 내수 소비 지출로 리테일 호실적", "이커머스 당일 배송 및 멤버십 현금흐름 창출"],
			"industrial_infra": ["미국 인프라 투자법(IIJA) 집행으로 중장비 수요 폭증", "데이터센터 전력 배전 및 산업 자동화 주문 쇄도"]
		}
		
		stock_news_dict = {
			"NVIDIA": ["블랙웰 B200 칩 공급 부족 지속 빅테크 주문 폭주", "AI 데이터센터 매출 전년비 150% 폭증"],
			"Broadcom": ["빅테크 커스텀 AI ASIC 칩 및 이더넷 스위치 폭증", "VMware 클라우드 고마진 소프트웨어 창출"],
			"AMD": ["MI300X AI 가속기 빅테크 채택 가속화", "차세대 AI GPU 로드맵 엔비디아 대항마"],
			"TSMC": ["3나노 및 2나노 최선단 파운드리 웨이퍼 판가 인상", "CoWoS 첨단 패키징 생산 능력 2배 증설"],
			"Micron": ["HBM3E 메모리 2025년 생산 물량 완판", "서버용 DDR5 및 SSD 판가 급등 어닝서프라이즈"],
			"Qualcomm": ["스냅드래곤 온디바이스 AI 칩셋 글로벌 1위", "오토모티브 및 PC AI 칩 영역 확장"],
			"Arm": ["차세대 v9 아키텍처 로열티 라이선스 급성장", "빅테크 자체 칩 개발로 라이선스 매출 폭증"],
			"Intel": ["미국 반도체법 85억 달러 보조금 최종 확정", "18A 공정 외부 파운드리 고객 확보 시동"],
			"Constellation": ["MS와 스리마일 아일랜드 20년 재가동 전력 계약", "미국 최대 무탄소 원전 발전사 수주 독점"],
			"Vistra": ["데이터센터 전력 공급 계약 쇄도로 주가 폭등", "원자력 및 가스 포트폴리오 독립 발전 1위"],
			"Oklo": ["샘 올트먼의 소형 모듈 원자로(SMR) 상용화 가속", "미국 에너지부 오로라 고속로 핵연료 재활용 승인"],
			"GE Vernova": ["데이터센터 전력 백업용 가스터빈 1000억 달러 수주", "송배전 그리드 장비 쇼티지로 판가 인상"],
			"NextEra": ["미국 최대 유틸리티 태양광 및 ESS 3GW 증설", "플로리다 인구 유입 탄탄한 배당 성장"],
			"Cameco": ["글로벌 우라늄 수급 불균형 판가 사상 최고치", "원전 르네상스로 장기 공급 계약 체결"],
			"NuScale": ["미국 원자력규제위 SMR 설계 승인 유일 기업", "동유럽 및 데이터센터 전력 공급 파트너십"],
			"NRG": ["텍사스 ERCOT 전력 시장 현물 판가 상승", "소매 전력 및 데이터센터 직접 공급 협상"],
			"Palantir": ["미 국방부 전장 AI 플랫폼 AIP 수주 폭증", "기업용 부트캠프 고객 전환율 80% 달성"],
			"Lockheed": ["F-35 스텔스 전투기 글로벌 인도 재개", "극초음속 미사일 국방 예산 최대 수혜"],
			"RTX": ["패트리어트 방공 미사일 글로벌 완판 주문", "프랫앤휘트니 항공기 엔진 서비스 호조"],
			"Northrop": ["B-21 레이더 차세대 스텔스 폭격기 양산", "우주 군사 위성 및 미사일 방어 체계"],
			"GeneralDynamics": ["콜롬비아급 전략 핵잠수함 대량 건조", "미 육군 차세대 스트라이커 장갑차 공급"],
			"Boeing": ["737 맥스 생산 정상화 및 인도량 회복", "우주 방산 부문 흑자 전환 로드맵"],
			"Kratos": ["발키리 자율비행 무인 전투 드론 테스트 성공", "미 공군 협동 전투기(CCA) 프로젝트 참여"],
			"RocketLab": ["일렉트론 로켓 50회 연속 발사 성공", "중대형 재사용 로켓 뉴트론 개발 순항"],
			"Microsoft": ["Azure AI 클라우드 30% 성장 Copilot 구독 급증", "OpenAI 스타게이트 슈퍼컴퓨터 투자"],
			"Apple": ["Apple Intelligence 아이폰 슈퍼사이클 시동", "M4 Mac 라인업 및 서비스 사상 최대 매출"],
			"Alphabet": ["Gemini 1.5 검색 엔진 통합 AI 오버뷰 증가", "구글 클라우드 영업이익률 11% 돌파"],
			"Meta": ["Llama 3 AI 오픈소스 생태계 및 광고 효율 급증", "스마트 안경 레이밴 메타 판매량 폭발"],
			"Amazon": ["AWS 클라우드 인프라 매출 가속 및 AI 가속기", "북미 이커머스 배송 효율화로 역대급 영업이익"],
			"Oracle": ["OCI 멀티클라우드 수주잔고 800억 달러", "MS 및 구글 클라우드와 상호 연결 파트너십"],
			"IBM": ["왓슨x 생성형 AI 컨설팅 프로젝트 수주 20억 달러", "레드햇 오픈시프트 하이브리드 클라우드 성장"],
			"Salesforce": ["Agentforce 자율형 비즈니스 AI 에이전트 런칭", "데이터 클라우드 고객 기반 마진율 30%"],
			"CrowdStrike": ["팔콘 플랫폼 차세대 엔드포인트 보안 1위", "클라우드 보안 및 신원 보안 모듈 도입 가속"],
			"PaloAlto": ["프리시전 AI 기반 네트워크 방화벽 통합", "플랫폼화 전략으로 조 단위 연간 반복 매출(ARR)"],
			"ServiceNow": ["기업 업무 자동화 워크플로우 AI 플랫폼 독점", "재계약률 98% 마르지 않는 현금흐름"],
			"Snowflake": ["데이터 클라우드 분석 AI 모델 서빙 성장", "코텍스 AI 기능 도입으로 사용량 확대"],
			"Datadog": ["클라우드 모니터링 및 APM 시장 점유율 1위", "LLM 옵저버빌리티 AI 솔루션 매출 기여"],
			"MongoDB": ["아틀라스 클라우드 벡터 검색 AI 애플리케이션", "현대적 개발자 데이터베이스 표준 안착"],
			"Cloudflare": ["글로벌 엣지 네트워크 CDN 및 사이버 공격 방어", "워커스 AI 분산 컴퓨팅 플랫폼 가속"],
			"Zscaler": ["클라우드 제로트러스트 보안 교환소 점유율 확대", "ZTNA 원격 보안 솔루션 대기업 공급"],
			"Netflix": ["유료 구독자 분기 순증 사상 최대 오징어게임2 기대", "광고형 요금제 도입으로 추가 수익성 확보"],
			"Disney": ["디즈니+ 스트리밍 부문 흑자 전환 달성", "인사이드 아웃2 등 글로벌 박스오피스 대흥행"],
			"Spotify": ["글로벌 유료 구독자 2억 5천만 명 돌파", "가격 인상 후에도 이탈 없는 충성 팬덤"],
			"WarnerBros": ["맥스(MAX) 스트리밍 글로벌 서비스 론칭", "해리포터 및 DC 유니버스 텐트폴 제작"],
			"EA": ["EA 스포츠 FC 24 글로벌 독점 흥행 랠리", "모바일 및 라이브 서비스 탄탄한 현금흐름"],
			"TakeTwo": ["GTA 6 전 세계 최고 기대작 릴리즈 카운트다운", "NBA 2K 시리즈 탄탄한 인게임 결제"],
			"Roblox": ["일간 활성 이용자 8000만 명 메타버스 돌파", "개발자 생태계 및 브랜드 광고 플랫폼 급성장"],
			"AppLovin": ["AI 기반 모바일 광고 엔진 액손 2.0 폭풍 성장", "영업이익률 40% 돌파 전자상거래 확장"],
			"Tesla": ["사이버캡 완전 무인 로보택시 공개", "옵티머스 휴머노이드 로봇 공장 투입"],
			"Rivian": ["폭스바겐 50억 달러 합작 투자 파트너십", "R2 중형 SUV 2026년 양산 준비 순항"],
			"Lucid": ["사우디 국부펀드 지원 럭셔리 SUV 그래비티 양산", "글로벌 최고 수준 전비 효율성 기술력"],
			"Enphase": ["태양광 마이크로 인버터 재고 소진 완료", "유럽 및 미국 주거용 태양광 수요 반등"],
			"Albemarle": ["리튬 가격 바닥 통과 기대감 생산비 절감", "북미 및 칠레 고순도 리튬 공급망 장악"],
			"Ford": ["하이브리드 F-150 트럭 수요 폭증 마진 방어", "전기차 투자 속도 조절로 손실 축소"],
			"GeneralMotors": ["자사주 100억 달러 매입 및 강력한 현금흐름", "얼티엄 EV 생산 확대 및 쉐보레 판매 호조"],
			"QuantumScape": ["폭스바겐과 전고체 배터리 상용화 기술 이전", "차세대 무음극 전고체 배터리 테스트 성공"],
			"ExxonMobil": ["파이오니어 합병으로 미국 셰일오일 1위", "사상 최대 현금 창출 및 배당 42년 연속 증액"],
			"Chevron": ["헤스 인수 완료로 가이아나 유전 생산량 급증", "저원가 심해 유전 및 LNG 포트폴리오 강화"],
			"ConocoPhillips": ["마라톤 오일 인수로 퍼미안 분지 규모의 경제", "LNG 장기 수출 계약 마진 극대화"],
			"Schlumberger": ["글로벌 해상 유전 디지털 시추 소프트웨어 성장", "중동 및 남미 오프쇼어 프로젝트 수주"],
			"EOG": ["퍼미안 분지 최고 프리미엄 유전 시추 효율", "무부채에 가까운 탄탄한 재무구조"],
			"Occidental": ["워런 버핏 옥시 지분 지속 매수 신뢰", "직접 공기 포집(DAC) 탄소 제거 상용화"],
			"Marathon": ["미국 최대 정유사 정제마진 회복", "대규모 자사주 매입 소각 주주환원율 최고"],
			"Valero": ["미국 걸프만 저원가 정제설비 독보적 경쟁력", "지속가능항공유(SAF) 친환경 정유 선점"],
			"JPMorgan": ["사상 최대 순이자이익(NII) 제이미 다이먼 리더십", "자산관리 및 글로벌 IB 시장 1위"],
			"GoldmanSachs": ["글로벌 M&A 자문 수수료 회복 실적 서프라이즈", "자산운용 및 사모펀드 자금 유입 확대"],
			"Berkshire": ["워런 버핏의 3000억 달러 현금성 자산 요새", "보험 및 철도 유틸리티 탄탄한 현금흐름"],
			"Visa": ["글로벌 결제 처리 금액 15조 달러 돌파", "국경 간 거래 결제 수수료 독점 캐시카우"],
			"Mastercard": ["전 세계 30억 장 카드 결제 네트워크 장악", "사이버 보안 및 부가 서비스 두 자릿수 성장"],
			"BlackRock": ["비트코인 현물 ETF IBIT 글로벌 1위 안착", "총 운용 자산(AUM) 사상 최초 11조 달러 돌파"],
			"Coinbase": ["미국 암호화폐 제도권 수탁 기관 1위", "베이스(Base) 레이어2 네트워크 트래픽 급증"],
			"MicroStrategy": ["비트코인 25만 개 이상 보유 프록시 랠리", "전환사채 발행을 통한 비트코인 추가 매입"],
			"EliLilly": ["마운자로·젭바운드 비만약 공급 쇼티지", "시가총액 1조 달러 도전 글로벌 제약 1위"],
			"NovoNordisk": ["위고비 글로벌 처방 확대 생산 시설 3배 증설", "심혈관 질환 적응증 추가 승인 호재"],
			"AbbVie": ["스카이리치·린버크 면역학 신약 역대급 성장", "보톡스 메디컬 에스테틱 탄탄한 현금흐름"],
			"Pfizer": ["비만 치료제 후보물질 임상 파이프라인 가속", "원가 절감 40억 달러 및 배당 수익률 6%"],
			"Merck": ["키트루다 항암제 글로벌 1위 독주 체제", "피하주사(SC) 제형 전환으로 특허 방어"],
			"Amgen": ["월 1회 투여 차세대 비만치료제 마리타이드 임상 호조", "골다공증 및 희귀질환 포트폴리오 성장"],
			"Vertex": ["카스게비 세계 최초 유전자 가위 치료제 승인", "낭포성 섬유증 시장 독점적 지배력"],
			"Gilead": ["연 2회 투여 레나카파비르 HIV 예방률 100%", "항암제 트로델비 파이프라인 확장"],
			"Walmart": ["이커머스 및 광고 사업 고성장 사상 최고가", "고소득층 고객 유입으로 미국 유통 지배"],
			"Costco": ["멤버십 연회비 인상에도 갱신율 93% 신기록", "식료품 및 이커머스 매출 서프라이즈"],
			"Target": ["당일 픽업 서비스 및 PB 브랜드 마진 개선", "디지털 풀필먼트 효율화로 수익성 회복"],
			"HomeDepot": ["주택 리모델링 전문 업자(Pro) 수주 확대", "금리 인하 사이클 주택 거래 회복 수혜"],
			"McDonalds": ["5달러 세트 메뉴 프로모션으로 고객 발길 유입", "글로벌 디지털 주문 및 코스모스 음료 브랜드"],
			"Starbucks": ["치폴레 턴어라운드 주역 브라이언 니콜 CEO 영입", "매장 주문 대기 시간 단축 및 혁신"],
			"Nike": ["에어 혁신 러닝화 라인업 재구축", "도매 유통 채널 파트너십 복원으로 반등"],
			"CocaCola": ["글로벌 가격 결정력 및 탄탄한 음료 포트폴리오", "62년 연속 배당 증액 글로벌 경기방어주"],
			"Caterpillar": ["글로벌 광산 및 인프라 건설 중장비 수주 호조", "영업이익률 21% 사상 최고 마진 기록"],
			"Deere": ["자율주행 정밀 농업 트랙터 소프트웨어 구독", "글로벌 곡물 및 농가 장비 현대화 사이클"],
			"UnionPacific": ["북미 대륙 횡단 철도 독점 운송 네트워크", "정밀 일정 철도(PSR) 운영으로 영업마진 개선"],
			"UPS": ["항공 및 육상 물류 자동화 허브 효율화", "고수익 헬스케어 및 B2B 물류 비중 확대"],
			"Honeywell": ["항공우주 제트엔진 부품 수주잔고 사상 최대", "산업 자동화 및 빌딩 제어 솔루션 성장"],
			"GEAerospace": ["상업용 항공기 엔진 44,000대 MRO 서비스 잭팟", "LEAP 엔진 차세대 라인업 독점 공급"],
			"Emerson": ["데이터센터 액체 냉각 및 공장 프로세스 제어", "자동화 소프트웨어 고마진 수주 급증"],
			"Eaton": ["데이터센터 초고압 전력 인프라 장비 2년 완판", "메가프로젝트 전력망 솔루션 수주 폭증"]
		}
		
		news_pool = [
			{"headline": "🚀 [속보] 12시 실리콘밸리 AI 칩으로 가세요! NVDA 블랙웰 주문 폭주!", "sector": "ai_chips", "type": "buff", "duration": 15.0},
			{"headline": "⚡ [속보] 1시 AI 전력망·SMR 원전에 빅테크 무탄소 전력 독점 수주!", "sector": "ai_power", "type": "buff", "duration": 15.0},
			{"headline": "🎯 [속보] 2시 국방 AI 팔란티어 AIP 수주 폭증! 미 국방부 전장 장악!", "sector": "defense_tech", "type": "buff", "duration": 15.0},
			{"headline": "🧠 [속보] 3시 빅테크 M7 생성형 AI 클라우드 인프라 매출 사상 최대!", "sector": "big_tech", "type": "buff", "duration": 15.0},
			{"headline": "🔒 [속보] 4시 사이버 보안 크라우드스트라이크 제로트러스트 플랫폼 폭풍 성장!", "sector": "cyber_saas", "type": "buff", "duration": 15.0},
			{"headline": "🍿 [속보] 5시 미디어 넷플릭스 유료 구독자 분기 순증 사상 최대치 랠리!", "sector": "media_entertain", "type": "buff", "duration": 15.0},
			{"headline": "📉 [경고] 6시 전기차 지대에 공매도 투하! 마진 악화 우려로 패닉셀!", "sector": "ev_auto", "type": "debuff", "duration": 15.0},
			{"headline": "🛢️ [속보] 7시 에너지 엑손모빌 셰일오일 합병 잭팟! 배당 사상 최고치!", "sector": "traditional_energy", "type": "buff", "duration": 15.0},
			{"headline": "🏛️ [속보] 8시 월가 메가뱅크 M&A 부활 및 비트코인 자산운용 수수료 사상 최대!", "sector": "wall_street", "type": "buff", "duration": 15.0},
			{"headline": "💉 [속보] 9시 글로벌 헬스케어 일라이릴리 비만 치료제 FDA 패스트트랙 승인!", "sector": "pharma", "type": "buff", "duration": 15.0},
			{"headline": "🛒 [속보] 10시 리테일 코스트코·월마트 견조한 내수 소비 서프라이즈 랠리!", "sector": "retail", "type": "buff", "duration": 15.0},
			{"headline": "🚜 [속보] 11시 산업재 캐터필러 인프라 수주 잭팟! 중장비 주문 쇄도!", "sector": "industrial_infra", "type": "buff", "duration": 15.0}
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
