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
		"042700": "한미반도체",
		"000660": "SK하이닉스",
		"005930": "삼성전자",
		"403870": "HPSP",
		"058470": "리노공업",
		"007660": "이수페타시스",
		"026720": "HD현대일렉트릭",
		"034020": "두산에너빌리티",
		"010120": "LS ELECTRIC",
		"298040": "효성중공업",
		"051600": "한전KPS",
		"454910": "두산로보틱스",
		"277810": "레인보우로보",
		"035420": "NAVER",
		"035720": "카카오",
		"328130": "루닛",
		"009540": "HD한국조선해양",
		"010140": "삼성중공업",
		"042660": "한화오션",
		"071970": "HD현대마린엔진",
		"011200": "HMM",
		"247540": "에코프로비엠",
		"086520": "에코프로",
		"373220": "LG에너지솔루션",
		"005490": "POSCO홀딩스",
		"003670": "포스코퓨처엠",
		"105560": "KB금융",
		"055550": "신한지주",
		"138040": "메리츠금융지주",
		"086790": "하나금융지주",
		"028260": "삼성물산",
		"196170": "알테오젠",
		"207940": "삼성바이오로직스",
		"068270": "셀트리온",
		"000100": "유한양행",
		"028300": "HLB",
		"005380": "현대차",
		"000270": "기아",
		"012330": "현대모비스",
		"018880": "한온시스템",
		"204320": "HL만도"
	}
	
	var results = {}
	var total = symbols.size()
	var completed = [0]
	var dispatched = [false]
	
	# Fallback timeout timer (3.0 seconds)
	get_tree().create_timer(3.0).timeout.connect(func():
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
		"NVDA", "AVGO", "AMD", "TSM", "MU",
		"MSFT", "AAPL", "GOOGL", "META", "AMZN",
		"LLY", "NVO", "ABBV", "PFE",
		"TSLA", "RIVN", "LCID", "XOM"
	]
	var results = {}
	var total = symbols.size()
	var completed = [0]
	var dispatched = [false]
	
	# Fallback timeout timer (3.0 seconds)
	get_tree().create_timer(3.0).timeout.connect(func():
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
