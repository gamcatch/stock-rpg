# ==============================================================================
# Stock RPG : 주식 속보 돌발 이벤트 포털 (NewsEventPortal)
# ==============================================================================
# 인게임 주식 속보 발생 시 개미 플레이어 근처에 즉각 스폰되어
# 터치 또는 개미의 자동 접근 시 대량 배당금과 지분을 제공하는 이벤트 노드입니다.
# ==============================================================================
class_name NewsEventPortal
extends Area2D

signal portal_claimed(headline: String, stock_name: String)

@export var duration: float = 120.0 # 2분 유지
var remaining_time: float = 120.0

var headline: String = "[속보] 한미반도체, 북미 1조 원 수주 잭팟!"
var stock_name: String = "한미반도체"
var bonus_shares: int = 5

var pulse_time: float = 0.0
var exp_gem_scene: PackedScene = preload("res://scenes/exp_gem.tscn")

func _ready():
	add_to_group("event_portal")
	body_entered.connect(_on_body_entered)
	remaining_time = duration
	SoundManager.play_boss_alert()

func setup_news_event(p_headline: String, p_stock_name: String, p_duration: float = 120.0):
	headline = p_headline
	stock_name = p_stock_name
	duration = p_duration
	remaining_time = duration
	queue_redraw()

func _process(delta: float):
	if Global.is_game_over or Global.is_paused:
		return
		
	pulse_time += delta * 4.0
	remaining_time -= delta
	queue_redraw()
	
	if remaining_time <= 0:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_claim_rewards()

func _claim_rewards():
	# 1. 포트폴리오에 보너스 지분 추가
	var info = {
		"name": stock_name,
		"rate": 10.0,
		"price": "100,000",
		"sector": "semiconductor"
	}
	PortfolioManager.buy_stock(stock_name, info, bonus_shares)
	Global.account_balance += 500000 # 50만 원 보너스 배당
	Global.current_return_rate += 5.0
	
	# 2. 전방에 황금 배당 젬 클러스터 폭발
	if exp_gem_scene:
		for i in range(8):
			var gem = exp_gem_scene.instantiate()
			var spread = Vector2(cos(i * TAU / 8.0), sin(i * TAU / 8.0)) * 60.0
			gem.global_position = global_position + spread
			gem.exp_value = 100
			get_parent().add_child(gem)
			
	SoundManager.play_level_up()
	portal_claimed.emit(headline, stock_name)
	queue_free()

func _draw():
	var font = ThemeDB.fallback_font
	var pulse = sin(pulse_time) * 6.0
	
	# 1. 황금빛 수급 소용돌이 포털 링
	draw_circle(Vector2.ZERO, 40.0 + pulse, Color(1.0, 0.85, 0.2, 0.25))
	draw_arc(Vector2.ZERO, 40.0 + pulse, 0.0, TAU, 32, Color(1.0, 0.9, 0.3, 0.9), 3.0)
	draw_arc(Vector2.ZERO, 25.0 - pulse * 0.5, 0.0, TAU, 24, Color(1.0, 0.3, 0.3, 0.7), 2.0)
	
	# 2. 상단 홀로그램 속보 헤드라인 배너
	var banner_rect = Rect2(-140, -75, 280, 26)
	draw_rect(banner_rect, Color(0.08, 0.12, 0.2, 0.85), true)
	draw_rect(banner_rect, Color(1.0, 0.85, 0.2), false, 1.5)
	draw_string(font, Vector2(-135, -57), "🚨 " + headline, HORIZONTAL_ALIGNMENT_LEFT, 270, 12, Color(1.0, 0.95, 0.6))
	
	# 3. 잔여 시간 타이머
	var timer_text = "⏱️ 긴급 수급 획득 찬스: %ds" % int(remaining_time)
	draw_string(font, Vector2(-100, 56), timer_text, HORIZONTAL_ALIGNMENT_CENTER, 200, 13, Color(1.0, 0.4, 0.4))
