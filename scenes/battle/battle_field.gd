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
	# 1. 단일 개미 플레이어 생성
	player = player_ant_scene.instantiate()
	player.position = Vector2(540, 600)
	add_child(player)
	
	# 2. 실시간 속보 시그널 연결
	if MarketDataManager.has_signal("breaking_news_alert"):
		MarketDataManager.breaking_news_alert.connect(_on_breaking_news_received)
		
	# 3. 초기 스폰 3개 종목
	for i in range(3):
		_spawn_random_stock_enemy(Vector2(randf_range(200, 880), player.position.y - randf_range(300, 600)))

func _process(delta: float):
	if Global.is_game_over or Global.is_paused:
		return
		
	scroll_offset_y += delta * 60.0
	queue_redraw()
	
	# 캔들 몬스터 주기적 스폰
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		var enemies_count = get_tree().get_nodes_in_group("enemies").size()
		if enemies_count < 12 and player != null:
			var spawn_pos = Vector2(randf_range(160, 920), player.position.y - randf_range(350, 650))
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
	# 개미 전방 180px 위치에 스폰
	var spawn_offset = Vector2(0, -180).rotated(player.rotation)
	portal.position = player.position + spawn_offset
	
	var stock_name = "관련 우량주"
	if headline.contains("한미반도체"): stock_name = "한미반도체"
	elif headline.contains("SK하이닉스"): stock_name = "SK하이닉스"
	elif headline.contains("삼성전자"): stock_name = "삼성전자"
	elif headline.contains("에코프로"): stock_name = "에코프로"
	elif headline.contains("현대"): stock_name = "HD현대일렉트릭"
	
	portal.setup_news_event(headline, stock_name, duration)
	add_child(portal)

# ------------------------------------------------------------------------------
# 🎨 배경 차트 그리드 렌더링 (사이버틱 네온 MTS 분위기)
# ------------------------------------------------------------------------------
func _draw():
	var bg_rect = Rect2(0, 0, 1080, 1080)
	draw_rect(bg_rect, Color(0.04, 0.06, 0.10))
	
	# 네온 그리드 라인
	var grid_size = 120.0
	var offset_y = fmod(scroll_offset_y, grid_size)
	
	for y in range(int(-grid_size), 1080 + int(grid_size), int(grid_size)):
		var line_y = float(y) + offset_y
		draw_line(Vector2(0, line_y), Vector2(1080, line_y), Color(0.12, 0.20, 0.32, 0.4), 1.0)
		
	for x in range(0, 1080, int(grid_size)):
		draw_line(Vector2(x, 0), Vector2(x, 1080), Color(0.12, 0.20, 0.32, 0.3), 1.0)
