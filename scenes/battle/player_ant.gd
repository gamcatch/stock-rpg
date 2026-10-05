# ==============================================================================
# Stock RPG : 단일 플레이어 개미 투자자 (PlayerAnt)
# ==============================================================================
# 100% 자율 전진 및 적 타겟팅 자동 사격,
# 보유 주식(포트폴리오) 위성 오브 공전 및 실시간 주식 정보 방치형 사냥 AI.
# ==============================================================================
class_name PlayerAnt
extends CharacterBody2D

signal level_up_ready()

@export var move_speed: float = 160.0
@export var attack_range: float = 480.0
@export var base_atk: float = 35.0

var proj_scene: PackedScene = preload("res://scenes/projectile.tscn")

# 자동 공격 타이머
var auto_fire_timer: float = 0.0
var fire_rate: float = 0.45 # 초당 약 2회 발사

# 위성 오브 회전 각도
var orbit_angle: float = 0.0

# 생명력 및 재생
var current_hp: float = 500.0
var max_hp: float = 500.0
var regen_timer: float = 0.0

func _ready():
	add_to_group("player")
	Global.player_hp = current_hp
	Global.player_max_hp = max_hp

func _physics_process(delta: float):
	if Global.is_game_over or Global.is_paused:
		return

	orbit_angle += delta * 2.5
	
	# 1. 자동 목표 탐색 및 좌우 조준 기동 (방치형 RPG 레이아웃)
	var target = _find_nearest_enemy()
	var base_y = 820.0
	
	if target and is_instance_valid(target):
		var target_x = clamp(target.global_position.x, 180.0, 900.0)
		var desired_pos = Vector2(target_x, base_y)
		global_position = global_position.lerp(desired_pos, 6.0 * delta)
		
		# 전방 적 조준
		var aim_angle = (target.global_position - global_position).angle()
		rotation = lerp_angle(rotation, aim_angle, 15.0 * delta)
	else:
		# 적이 없으면 중앙 복귀 및 전방 조준
		var center_pos = Vector2(540.0, base_y)
		global_position = global_position.lerp(center_pos, 4.0 * delta)
		rotation = lerp_angle(rotation, -PI / 2.0, 10.0 * delta)
		
	queue_redraw()
	
	# 2. 자동 사격 프로세스
	auto_fire_timer += delta
	if auto_fire_timer >= fire_rate:
		auto_fire_timer = 0.0
		_auto_fire(target)
		
	# 3. 배당금 기반 자동 체력 재생
	regen_timer += delta
	if regen_timer >= 1.0:
		regen_timer = 0.0
		var div_per_min = PortfolioManager.get_per_minute_dividends()
		var heal_amt = max(5.0, float(div_per_min) * 0.02)
		current_hp = min(max_hp, current_hp + heal_amt)
		Global.player_hp = current_hp

# ------------------------------------------------------------------------------
# 🎯 가장 가까운 적 / 속보 이벤트 포털 탐색
# ------------------------------------------------------------------------------
func _find_nearest_enemy() -> Node2D:
	# 1. 속보 이벤트 포털이 있으면 최우선 타겟팅
	var portals = get_tree().get_nodes_in_group("event_portal")
	if not portals.is_empty():
		for p in portals:
			if is_instance_valid(p):
				return p
				
	# 2. 일반 캔들 몬스터 탐색
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist: float = attack_range * 1.5
	
	for e in enemies:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
				
	return nearest

# ------------------------------------------------------------------------------
# 💥 자동 사격: 캔들스틱 빔 + 보유 주식 위성 오브 일제 사격
# ------------------------------------------------------------------------------
func _auto_fire(target: Node2D):
	if target == null or not is_instance_valid(target):
		return
		
	var dir = (target.global_position - global_position).normalized()
	
	# 메인 캔들스틱 빔
	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position + dir * 25.0
		var bullet_color = Color(1.0, 0.25, 0.25) if Global.is_korean_market_colors else Color(0.2, 0.9, 0.4)
		proj.init_directional(dir, base_atk, 650.0, 1.2, bullet_color, 1)
		get_parent().add_child(proj)
		SoundManager.play_shoot_beam()

	# 보유 주식 위성 오브 지원 사격
	var owned = PortfolioManager.owned_stocks
	var idx = 0
	for sname in owned.keys():
		var shares = owned[sname].get("shares", 0)
		if shares <= 0:
			continue
		var orb_offset = Vector2(cos(orbit_angle + idx * (TAU / max(1, owned.size()))), sin(orbit_angle + idx * (TAU / max(1, owned.size())))) * 70.0
		if proj_scene and idx < 4:
			var sub_proj = proj_scene.instantiate()
			sub_proj.global_position = global_position + orb_offset
			var sub_dir = (target.global_position - sub_proj.global_position).normalized()
			sub_proj.init_directional(sub_dir, base_atk * 0.4 * (1.0 + shares * 0.05), 550.0, 0.9, Color(1.0, 0.85, 0.2), 0)
			get_parent().add_child(sub_proj)
		idx += 1

# ------------------------------------------------------------------------------
# 🎨 캔버스 드로잉: 당찬 개미 실루엣 + 보유 주식 위성 궤도 렌더링
# ------------------------------------------------------------------------------
func _draw():
	var font = ThemeDB.fallback_font
	
	# 1. 황금 배당 오라 펄스
	var pulse = sin(Global.game_time * 4.0) * 4.0
	draw_circle(Vector2.ZERO, 36.0 + pulse, Color(1.0, 0.8, 0.2, 0.12))
	draw_arc(Vector2.ZERO, 36.0 + pulse, 0.0, TAU, 32, Color(1.0, 0.85, 0.2, 0.5), 1.5)
	
	# 2. 보유 주식 위성 궤도 (Stock Orbiters)
	var owned = PortfolioManager.owned_stocks
	var num_stocks = owned.size()
	if num_stocks > 0:
		draw_arc(Vector2.ZERO, 70.0, 0.0, TAU, 36, Color(0.3, 0.7, 1.0, 0.2), 1.0)
		var i = 0
		for sname in owned.keys():
			var item = owned[sname]
			var angle = orbit_angle + i * (TAU / float(num_stocks))
			var orb_pos = Vector2(cos(angle), sin(angle)) * 70.0
			var orb_color = Color(1.0, 0.3, 0.3) if item.get("rate", 0.0) >= 0 else Color(0.3, 0.6, 1.0)
			
			# 위성 코인 오브
			draw_circle(orb_pos, 8.0, orb_color)
			draw_circle(orb_pos, 6.0, Color(1.0, 0.9, 0.3))
			draw_string(font, orb_pos + Vector2(-25, -12), sname, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.WHITE)
			i += 1
			
	# 3. 개미 본체 렌더링 (순수 올블랙 일개미 전사 실루엣)
	var body_color = Color(0.04, 0.05, 0.07)
	
	# 복부 (Abdomen)
	draw_circle(Vector2(-14, 0), 12.0, body_color)
	# 흉부 (Thorax)
	draw_circle(Vector2(0, 0), 9.0, body_color)
	# 두부 (Head)
	draw_circle(Vector2(14, 0), 11.0, body_color)
	
	# 더듬이 (Antennae)
	draw_line(Vector2(16, -4), Vector2(25, -13), body_color, 2.0)
	draw_line(Vector2(16, 4), Vector2(25, 13), body_color, 2.0)
	draw_circle(Vector2(25, -13), 2.5, Color(1.0, 0.8, 0.2))
	draw_circle(Vector2(25, 13), 2.5, Color(1.0, 0.8, 0.2))
	
	# 양봉 캔들스틱 검 (전방 붉은 검)
	var blade_start = Vector2(10, 10)
	var blade_end = Vector2(34, 16)
	draw_line(blade_start, blade_end, Color(1.0, 0.2, 0.2), 3.5)
	draw_circle(blade_end, 3.0, Color(1.0, 0.9, 0.4))
