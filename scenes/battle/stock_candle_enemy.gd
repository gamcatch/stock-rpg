# ==============================================================================
# Stock RPG : 실제 종목 캔들 몬스터 (StockCandleEnemy)
# ==============================================================================
# 실제 주식 데이터(종목명, 등락률, 가격)가 몬스터로 시각화되어
# 개미 플레이어의 전장에 실시간 스폰되는 핵심 유닛입니다.
# ==============================================================================
class_name StockCandleEnemy
extends CharacterBody2D

signal enemy_defeated(stock_name: String, rate: float, is_bull: bool)

@export var move_speed: float = 70.0
@export var max_hp: float = 80.0
var current_hp: float = 80.0

var stock_name: String = "SK하이닉스"
var rate: float = 4.5
var price_str: String = "180,000"
var sector: String = "semiconductor"
var is_bull: bool = true

var hit_flash_timer: float = 0.0
var exp_gem_scene: PackedScene = preload("res://scenes/exp_gem.tscn")

var floating_damages: Array = [] # { text, pos, alpha, life }

func _ready():
	add_to_group("enemy")
	add_to_group("enemies")
	current_hp = max_hp
	is_bull = (rate >= 0.0)

func setup_stock_data(s_name: String, s_rate: float, s_price: String, s_sector: String):
	stock_name = s_name
	rate = s_rate
	price_str = s_price
	sector = s_sector
	is_bull = (rate >= 0.0)
	
	# 등락률에 따른 스탯 조정 (상한가일수록 더 큰 보너스)
	if is_bull:
		max_hp = 50.0 + min(rate * 10.0, 200.0)
	else:
		max_hp = 70.0 + min(abs(rate) * 12.0, 250.0)
	current_hp = max_hp
	queue_redraw()

func _physics_process(delta: float):
	if Global.is_game_over or Global.is_paused:
		return
		
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		
	# 플로팅 데미지 텍스트 갱신
	for i in range(floating_damages.size() - 1, -1, -1):
		var fd = floating_damages[i]
		fd["life"] -= delta
		fd["pos"].y -= 40.0 * delta
		fd["alpha"] = clamp(fd["life"] / 0.8, 0.0, 1.0)
		if fd["life"] <= 0:
			floating_damages.remove_at(i)
		
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		# 플레이어 방향으로 전진
		var to_player = (player.global_position - global_position)
		var dir = to_player.normalized()
		velocity = dir * move_speed
		
		# 플레이어 접촉 시 약한 피해
		if to_player.length() < 36.0:
			if player.has_method("take_hit"):
				player.take_hit(12.0 * delta)
			elif "current_hp" in player:
				player.current_hp -= 12.0 * delta
				Global.player_hp = player.current_hp
	else:
		# 플레이어가 없으면 화면 아래로 이동
		velocity = Vector2(0, move_speed)
		
	move_and_slide()
	queue_redraw()

func take_damage(amount: float, extra_arg = null):
	current_hp -= amount
	hit_flash_timer = 0.15
	SoundManager.play_hit()
	
	# 플로팅 데미지 숫자 생성
	floating_damages.append({
		"text": "-%d" % int(amount),
		"pos": Vector2(randf_range(-15, 15), -20),
		"color": Color(1.0, 0.9, 0.2) if is_bull else Color(0.4, 0.8, 1.0),
		"life": 0.8,
		"alpha": 1.0
	})
	
	if current_hp <= 0:
		_die()
		_die()

func _die():
	enemy_defeated.emit(stock_name, rate, is_bull)
	
	# 수익률 가산
	if is_bull:
		Global.current_return_rate += rate * 0.15
	else:
		Global.current_return_rate += 0.05 # 하락 극복 보너스
		
	# 경험치 및 배당금 젬 드랍
	if exp_gem_scene:
		var gem = exp_gem_scene.instantiate()
		gem.global_position = global_position
		gem.exp_value = 25 + int(abs(rate) * 5)
		get_parent().add_child(gem)
		
	SoundManager.play_enemy_death()
	queue_free()

func _draw():
	var font = ThemeDB.fallback_font
	var candle_color = Color(1.0, 0.25, 0.25) if is_bull else Color(0.25, 0.6, 1.0)
	if hit_flash_timer > 0:
		candle_color = Color.WHITE
		
	# 1. 캔들 몸체 (차트 캔들스틱 사각형)
	var body_rect = Rect2(-14, -20, 28, 40)
	draw_rect(body_rect, candle_color, true)
	draw_rect(body_rect, Color.WHITE, false, 1.5)
	
	# 2. 캔들 심지 (상/하단 꼬리선)
	draw_line(Vector2(0, -32), Vector2(0, -20), candle_color, 2.5)
	draw_line(Vector2(0, 20), Vector2(0, 32), candle_color, 2.5)
	
	# 3. 상단 종목명 & 등락률 정보 텍스트 (시각화의 핵심!)
	var sign_str = "▲+" if is_bull else "▼"
	var rate_text = "%s (%s%.1f%%)" % [stock_name, sign_str, rate]
	var text_color = Color(1.0, 0.9, 0.3) if is_bull else Color(0.6, 0.85, 1.0)
	draw_string(font, Vector2(-60, -42), rate_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 13, text_color)
	
	# 4. 체력 게이지
	var hp_ratio = clamp(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-20, 36, 40, 5), Color(0.1, 0.1, 0.1, 0.8))
	draw_rect(Rect2(-20, 36, 40 * hp_ratio, 5), candle_color)
	
	# 5. 플로팅 데미지 텍스트 렌더링
	for fd in floating_damages:
		var c = fd.get("color", Color.YELLOW)
		c.a = fd.get("alpha", 1.0)
		draw_string(font, fd["pos"], fd["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, c)
	draw_rect(Rect2(-20, 36, 40 * hp_ratio, 5), candle_color)
