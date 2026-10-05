# ==============================================================================
# Stock RPG : 방치형 자동 전투 필드 (BattleField)
# ==============================================================================
# 단일 개미 플레이어의 자동 전진, 실제 종목 캔들 몬스터의 스트리밍 스폰,
# 실시간 주식 속보 이벤트 포털 생성 및 무한 차트 배경 스크롤 관리.
# ==============================================================================
class_name BattleField
extends Node2D

@export var spawn_interval: float = 1.2
var spawn_timer: float = 0.0

var player_ant_scene: PackedScene = preload("res://scenes/battle/player_ant.tscn")
var enemy_candle_scene: PackedScene = preload("res://scenes/battle/stock_candle_enemy.tscn")
var news_portal_scene: PackedScene = preload("res://scenes/battle/news_event_portal.tscn")

var player: CharacterBody2D = null
var scroll_offset_y: float = 0.0

func _ready():
	# 1. 단일 개미 플레이어 생성 (하단 앵커)
	player = player_ant_scene.instantiate()
	player.position = Vector2(540, 820)
	add_child(player)
	
	# 2. 실시간 속보 시그널 연결
	if MarketDataManager.has_signal("breaking_news_alert"):
		MarketDataManager.breaking_news_alert.connect(_on_breaking_news_received)
		
	# 3. 초기 스폰 4개 종목 (상단~중단)
	for i in range(4):
		_spawn_random_stock_enemy(Vector2(randf_range(200, 880), randf_range(150, 450)))

func _process(delta: float):
	if Global.is_game_over or Global.is_paused:
		return
		
	# 시원하게 아래로 스크롤되는 속도감 (전진하는 연출)
	scroll_offset_y += delta * 220.0
	queue_redraw()
	
	# 캔들 몬스터 주기적 스폰 (상단에서 등장)
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		var enemies_count = get_tree().get_nodes_in_group("enemies").size()
		if enemies_count < 10 and player != null:
			var spawn_pos = Vector2(randf_range(180, 900), randf_range(-60, 20))
			_spawn_random_stock_enemy(spawn_pos)

# ------------------------------------------------------------------------------
# 📈 실제 종목 데이터 기반 몬스터 스폰
# ------------------------------------------------------------------------------
func _spawn_random_stock_enemy(pos: Vector2):
	if not enemy_candle_scene:
		return
		
	var enemy = enemy_candle_scene.instantiate()
	enemy.position = pos
	
	# MarketDataManager에서 임의의 실제 종목 추출
	var stock_data = _pick_random_market_stock()
	enemy.setup_stock_data(
		stock_data.get("name", "삼성전자"),
		float(stock_data.get("rate", 1.5)),
		str(stock_data.get("price", "75,000")),
		stock_data.get("sector", "semiconductor")
	)
	add_child(enemy)

func _pick_random_market_stock() -> Dictionary:
	var sec_keys = MarketDataManager.sectors.keys()
	if sec_keys.is_empty():
		return {"name": "삼성전자", "rate": 2.5, "price": "78,000", "sector": "semiconductor"}
		
	var r_sec_key = sec_keys[randi() % sec_keys.size()]
	var sec = MarketDataManager.sectors[r_sec_key]
	if sec.has("stocks") and not sec["stocks"].is_empty():
		var stocks = sec["stocks"]
		var s = stocks[randi() % stocks.size()]
		return {
			"name": s.get("name", "우량주"),
			"rate": s.get("rate", 1.0),
			"price": MarketDataManager.get_stock_price(s),
			"sector": r_sec_key
		}
	return {"name": "SK하이닉스", "rate": 5.2, "price": "180,000", "sector": "semiconductor"}

# ------------------------------------------------------------------------------
# 🚨 주식 속보 발령 시 개미 근처에 이벤트 포털 즉각 생성
# ------------------------------------------------------------------------------
func _on_breaking_news_received(headline: String, sector_key: String, effect_type: String, duration: float):
	if player == null or not is_instance_valid(player):
		return
		
	if not news_portal_scene:
		return
		
	print("[BattleField] 주식 속보 수신! 개미 전방에 긴급 이벤트 포털을 생성합니다: ", headline)
	
	var portal = news_portal_scene.instantiate()
	# 개미 전방(위쪽) 200px 위치에 스폰
	portal.position = Vector2(player.position.x, player.position.y - 200.0)
	
	var stock_name = "관련 우량주"
	if headline.contains("한미반도체"): stock_name = "한미반도체"
	elif headline.contains("SK하이닉스"): stock_name = "SK하이닉스"
	elif headline.contains("삼성전자"): stock_name = "삼성전자"
	elif headline.contains("에코프로"): stock_name = "에코프로"
	elif headline.contains("현대"): stock_name = "HD현대일렉트릭"
	
	portal.setup_news_event(headline, stock_name, duration)
	add_child(portal)

# ------------------------------------------------------------------------------
# 🎨 배경 차트 고속도로 렌더링 (살아 숨쉬는 증시 전장)
# ------------------------------------------------------------------------------
func _draw():
	var font = ThemeDB.fallback_font
	
	# 1. 짙은 사이버 차트 배경
	var bg_rect = Rect2(0, 0, 1080, 1080)
	draw_rect(bg_rect, Color(0.03, 0.05, 0.08))
	
	# 2. 고속도로 사이드 네온 가드레일 (좌/우)
	draw_line(Vector2(120, 0), Vector2(120, 1080), Color(0.18, 0.75, 1.0, 0.6), 3.0)
	draw_line(Vector2(960, 0), Vector2(960, 1080), Color(0.18, 0.75, 1.0, 0.6), 3.0)
	
	# 3. 아래로 고속 질주하는 도로 차선 (Street Dashes)
	var dash_length = 60.0
	var gap = 50.0
	var total_step = dash_length + gap
	var scroll_y = fmod(scroll_offset_y, total_step)
	
	var lanes = [380.0, 540.0, 700.0]
	for lane_x in lanes:
		for y in range(-int(total_step), 1080 + int(total_step), int(total_step)):
			var start_pt = Vector2(lane_x, float(y) + scroll_y)
			var end_pt = Vector2(lane_x, float(y) + scroll_y + dash_length)
			draw_line(start_pt, end_pt, Color(0.3, 0.8, 1.0, 0.45), 2.5)
			
	# 4. 도로 바닥에 은은하게 흐르는 홀로그램 상승 텍스트 ("BULL RUN ▲ 떡상")
	var text_step = 360.0
	var text_scroll_y = fmod(scroll_offset_y * 0.7, text_step)
	for ty in range(-int(text_step), 1080 + int(text_step), int(text_step)):
		var pos_y = float(ty) + text_scroll_y
		draw_string(font, Vector2(500, pos_y), "▲ BULL RUN", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(1.0, 0.25, 0.25, 0.18))
