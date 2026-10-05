extends Node

# Real-Time Stock Market Data & News Fetcher
# Fetches live stock quotes from Naver / Yahoo Finance and live breaking news from Google News RSS.

signal rates_updated(market_type, stock_dict)
signal news_updated(news_list)

var is_fetching_stocks: bool = false
var is_fetching_news: bool = false

# Headers for HTTP requests
const USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

func _ready():
	pass

# -------------------------------------------------------------
# 1. Fetch Live Stock Quotes
# -------------------------------------------------------------
func fetch_market_stocks(is_korean: bool):
	if is_fetching_stocks:
		return
	is_fetching_stocks = true
	print("[MarketDataFetcher] Fetching real-time stock rates (is_korean: %s)..." % is_korean)
	
	if is_korean:
		_fetch_korean_stocks()
	else:
		_fetch_us_stocks()

func _fetch_korean_stocks():
	var symbols = {
		# 12시: 반도체
		"042700": "한미반도체", "000660": "SK하이닉스", "005930": "삼성전자", "403870": "HPSP",
		"058470": "리노공업", "007660": "이수페타시스", "080220": "제주반도체", "399720": "가온칩스",

		# 1시: 전력망 & 원전
		"026720": "HD현대일렉트릭", "034020": "두산에너빌리티", "010120": "LS ELECTRIC", "298040": "효성중공업",
		"051600": "한전KPS", "103590": "일진전기", "457550": "우진엔텍", "033100": "제룡전기",

		# 2시: 미래차 & 모빌리티
		"005380": "현대차", "000270": "기아", "012330": "현대모비스", "018880": "한온시스템",
		"204320": "HL만도", "307950": "현대오토에버", "161390": "한국타이어", "419050": "삼기이브",

		# 3시: 로봇 & AI
		"454910": "두산로보틱스", "277810": "레인보우로보", "108490": "로보티즈", "455900": "엔젤로보틱스",
		"328130": "루닛", "056080": "유진로봇", "058610": "에스피지", "389500": "에스비비테크",

		# 4시: 게임 & 플랫폼
		"259960": "크래프톤", "035420": "NAVER", "035720": "카카오", "251270": "넷마블",
		"036570": "엔씨소프트", "263750": "펄어비스", "112040": "위메이드", "293490": "카카오게임즈",

		# 5시: K-컬처 & 엔터
		"352820": "하이브", "035900": "JYP Ent.", "041510": "에스엠", "122870": "와이지엔터",
		"035760": "CJ ENM", "253450": "스튜디오드래곤", "376300": "디어유", "036420": "콘텐트리중앙",

		# 6시: 2차전지
		"247540": "에코프로비엠", "086520": "에코프로", "373220": "LG에너지솔루션", "005490": "POSCO홀딩스",
		"003670": "포스코퓨처엠", "348370": "엔켐", "078600": "대주전자재료", "001570": "금양",

		# 7시: K-푸드 & 소비재
		"003230": "삼양식품", "004370": "농심", "271560": "오리온", "097950": "CJ제일제당",
		"090430": "아모레퍼시픽", "192820": "코스맥스", "161890": "한국콜마", "005180": "빙그레",

		# 8시: 금융 & 밸류업
		"105560": "KB금융", "055550": "신한지주", "138040": "메리츠금융지주", "086790": "하나금융지주",
		"028260": "삼성물산", "032830": "삼성생명", "006800": "미래에셋증권", "316140": "우리금융지주",

		# 9시: 바이오 랩
		"196170": "알테오젠", "207940": "삼성바이오로직스", "068270": "셀트리온", "000100": "유한양행",
		"028300": "HLB", "141080": "리가켐바이오", "000250": "삼천당제약", "298380": "에이비엘바이오",

		# 10시: K-조선 & 해운
		"009540": "HD한국조선해양", "010140": "삼성중공업", "042660": "한화오션", "071970": "HD현대마린엔진",
		"011200": "HMM", "028670": "팬오션", "097230": "HJ중공업", "460930": "현대힘스",

		# 11시: K-방산 & 우주
		"012450": "한화에어로", "064350": "현대로템", "079550": "LIG넥스원", "047810": "한국항공우주",
		"103140": "풍산", "099320": "쎄트렉아이", "272210": "한화시스템", "011210": "현대위아"
	}
	
	var results = {}
	var total = symbols.size()
	var completed = [0]
	var dispatched = [false]
	
	# Fallback timeout timer (4.5 seconds)
	get_tree().create_timer(4.5).timeout.connect(func():
		if not dispatched[0]:
			dispatched[0] = true
			is_fetching_stocks = false
			if not results.is_empty():
				print("[MarketDataFetcher] Korean stock rates fetched (timeout reached with %d/%d items)" % [results.size(), total])
				emit_signal("rates_updated", MarketDataManager.MarketType.KOREA, results)
	)
	
	for code in symbols.keys():
		var http = HTTPRequest.new()
		http.timeout = 3.0
		add_child(http)
		var url = "https://m.stock.naver.com/api/stock/%s/basic" % code
		var headers = ["User-Agent: " + USER_AGENT, "Accept: application/json"]
		
		http.request_completed.connect(func(result, response_code, _resp_headers, body):
			if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
				var json_str = body.get_string_from_utf8()
				var json = JSON.new()
				if json.parse(json_str) == OK:
					var data = json.get_data()
					var ratio_str = str(data.get("fluctuationsRatio", "0.0")).replace("%", "").replace(",", "").strip_edges()
					var ratio = float(ratio_str)
					var cmp_val = data.get("compareToPreviousClosePrice", {})
					var compare_code = "3"
					if cmp_val is Dictionary:
						compare_code = str(cmp_val.get("code", "3"))
					elif cmp_val is String:
						compare_code = cmp_val
					if compare_code == "5" or compare_code == "4":
						ratio = -abs(ratio)
					elif compare_code == "2" or compare_code == "1":
						ratio = abs(ratio)
					results[code] = {
						"name": symbols[code],
						"rate": ratio,
						"price": str(data.get("closePrice", "0"))
					}
			completed[0] += 1
			http.queue_free()
			
			if completed[0] >= total and not dispatched[0]:
				dispatched[0] = true
				is_fetching_stocks = false
				if not results.is_empty():
					print("[MarketDataFetcher] All Korean stock rates successfully fetched (%d items)!" % results.size())
					emit_signal("rates_updated", MarketDataManager.MarketType.KOREA, results)
		)
		var err = http.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			completed[0] += 1
			http.queue_free()

func _fetch_us_stocks():
	var symbols = [
		# 12시: AI Chips
		"NVDA", "AVGO", "AMD", "TSM", "MU", "QCOM", "ARM", "INTC",
		# 1시: AI Power
		"CEG", "VST", "OKLO", "GEV", "NEE", "CCJ", "SMR", "NRG",
		# 2시: Defense Tech
		"PLTR", "LMT", "RTX", "NOC", "GD", "BA", "KTOS", "RKLB",
		# 3시: Big Tech
		"MSFT", "AAPL", "GOOGL", "META", "AMZN", "ORCL", "IBM", "CRM",
		# 4시: Cyber SaaS
		"CRWD", "PANW", "NOW", "SNOW", "DDOG", "MDB", "NET", "ZS",
		# 5시: Media & Entertain
		"NFLX", "DIS", "SPOT", "WBD", "EA", "TTWO", "RBLX", "APP",
		# 6시: EV & Auto
		"TSLA", "RIVN", "LCID", "ENPH", "ALB", "F", "GM", "QS",
		# 7시: Traditional Energy
		"XOM", "CVX", "COP", "SLB", "EOG", "OXY", "MPC", "VLO",
		# 8시: Wall Street
		"JPM", "GS", "BRK.B", "V", "MA", "BLK", "COIN", "MSTR",
		# 9시: Pharma & Healthcare
		"LLY", "NVO", "ABBV", "PFE", "MRK", "AMGN", "VRTX", "GILD",
		# 10시: Retail
		"WMT", "COST", "TGT", "HD", "MCD", "SBUX", "NKE", "KO",
		# 11시: Industrial & Infra
		"CAT", "DE", "UNP", "UPS", "HON", "GE", "EMR", "ETN"
	]
	
	var results = {}
	var total = symbols.size()
	var completed = [0]
	var dispatched = [false]
	
	# Fallback timeout timer (3.0 seconds)
	get_tree().create_timer(5.0).timeout.connect(func():
		if not dispatched[0]:
			dispatched[0] = true
			is_fetching_stocks = false
			if not results.is_empty():
				print("[MarketDataFetcher] US stock rates fetched (timeout reached with %d/%d items)" % [results.size(), total])
				emit_signal("rates_updated", MarketDataManager.MarketType.US, results)
	)
	
	for sym in symbols:
		var http = HTTPRequest.new()
		http.timeout = 3.0
		add_child(http)
		var url = "https://query1.finance.yahoo.com/v8/finance/chart/%s?interval=1d&range=1d" % sym
		var headers = ["User-Agent: " + USER_AGENT, "Accept: application/json"]
		
		http.request_completed.connect(func(result, response_code, _resp_headers, body):
			if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
				var json_str = body.get_string_from_utf8()
				var json = JSON.new()
				if json.parse(json_str) == OK:
					var res = json.get_data().get("chart", {}).get("result", [])
					if res.size() > 0:
						var meta = res[0].get("meta", {})
						var price = meta.get("regularMarketPrice", 0.0)
						var prev = meta.get("chartPreviousClose", price)
						var rate = 0.0
						if prev > 0.0:
							rate = ((price - prev) / prev) * 100.0
						results[sym] = {
							"name": sym,
							"rate": snapped(rate, 0.1),
							"price": "$%.2f" % price
						}
			completed[0] += 1
			http.queue_free()
			
			if completed[0] >= total and not dispatched[0]:
				dispatched[0] = true
				is_fetching_stocks = false
				if not results.is_empty():
					print("[MarketDataFetcher] All US stock rates successfully fetched (%d items)!" % results.size())
					emit_signal("rates_updated", MarketDataManager.MarketType.US, results)
		)
		var err = http.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			completed[0] += 1
			http.queue_free()

# -------------------------------------------------------------
# 2. Fetch Live Market Breaking News from Google RSS
# -------------------------------------------------------------
func fetch_market_news(is_korean: bool):
	if is_fetching_news:
		return
	is_fetching_news = true
	print("[MarketDataFetcher] Fetching real-time market news (is_korean: %s)..." % is_korean)
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = ""
	if is_korean:
		url = "https://news.google.com/rss/search?q=%EC%A3%BC%EC%8B%9D+%EC%A6%9D%EC%8B%9C+%EC%BD%94%EC%8A%A4%ED%94%BC&hl=ko&gl=KR&ceid=KR:ko"
	else:
		url = "https://news.google.com/rss/search?q=stock+market+nasdaq+nvidia&hl=en-US&gl=US&ceid=US:en"
		
	var headers = ["User-Agent: " + USER_AGENT]
	http.request_completed.connect(func(result, response_code, _resp_headers, body):
		is_fetching_news = false
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var xml_str = body.get_string_from_utf8()
			var parsed_news = _parse_rss_titles(xml_str, is_korean)
			if not parsed_news.is_empty():
				emit_signal("news_updated", parsed_news)
		http.queue_free()
	)
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		is_fetching_news = false
		http.queue_free()

func _parse_rss_titles(xml_text: String, is_korean: bool) -> Array:
	var news_list: Array = []
	var item_regex = RegEx.new()
	item_regex.compile("<item>([\\s\\S]*?)</item>")
	var title_regex = RegEx.new()
	title_regex.compile("<title>(.*?)</title>")
	
	var items = item_regex.search_all(xml_text)
	for i in range(min(items.size(), 12)):
		var item_match = items[i]
		var item_content = item_match.get_string(1)
		var title_match = title_regex.search(item_content)
		if title_match:
			var raw_title = title_match.get_string(1)
			# Clean HTML entities
			var clean_title = raw_title.replace("&quot;", "\"").replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">").replace("&#39;", "'").replace("<![CDATA[", "").replace("]]>", "").strip_edges()
			
			if clean_title.length() > 0:
				var prefix = "📢 [실시간 속보] " if (i % 2 == 0) else "🔥 [증시 핫이슈] "
				if not is_korean:
					prefix = "📢 [LIVE] " if (i % 2 == 0) else "🔥 [HOT ISSUE] "
				news_list.append(prefix + clean_title)
				
	return news_list
