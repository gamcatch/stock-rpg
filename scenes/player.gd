extends CharacterBody2D

@export var move_speed: float = 240.0
var proj_scene: PackedScene = preload("res://scenes/projectile.tscn")

var green_beam_timer: float = 0.0
var stop_loss_timer: float = 0.0
var hodl_timer: float = 0.0
var is_hodl_active: bool = false
var hodl_duration: float = 0.0

var dca_orbs: Array = []
var iframe_timer: float = 0.0
var dividend_regen_timer: float = 0.0
var magnet_pulse_timer: float = 0.0

# --- 방치형 RPG AUTO-PLAY AI 시스템 ---
var is_auto_play: bool = true
var manual_override_timer: float = 0.0
var auto_target_pos: Vector2 = Vector2.ZERO
var auto_status_text: String = "🤖 AUTO 사냥 중"
var patrol_timer: float = 0.0
var current_target_stock: Dictionary = {}
var stay_at_target_timer: float = 0.0
var is_on_highway_cruise: bool = false
var visited_stock_cooldowns: Dictionary = {}
var visited_sector_cooldowns: Dictionary = {}

func _ready():
	add_to_group("player")
	var magnet_area = $MagnetArea
	if magnet_area:
		magnet_area.area_entered.connect(_on_magnet_area_entered)
	update_magnet_radius()
	
	if MarketDataManager.has_signal("breaking_news_alert"):
		MarketDataManager.breaking_news_alert.connect(_on_breaking_news_nav)
	if MarketDataManager.has_signal("stock_vi_triggered"):
		MarketDataManager.stock_vi_triggered.connect(_on_stock_vi_triggered)
	if Global.has_signal("auto_play_toggled"):
		Global.auto_play_toggled.connect(_on_auto_play_toggled)
	is_auto_play = Global.auto_play_enabled

func _rotate_to_next_sector():
	if not current_target_stock.is_empty():
		var old_stock_name = current_target_stock.get("name", "")
		var old_sec_key = current_target_stock.get("sector_key", "")
		visited_stock_cooldowns[old_stock_name] = 60.0 # 동일 종목 60초간 재방문 방지
		if not old_sec_key.is_empty():
			visited_sector_cooldowns[old_sec_key] = 45.0 # 동일 섹터 45초간 재방문 방지 (타 섹터 적극 순회!)
	current_target_stock = _select_best_rising_stock()

func _on_stock_vi_triggered(stock_name: String, _duration: float):
	if not current_target_stock.is_empty() and current_target_stock.get("name", "") == stock_name:
		visited_stock_cooldowns[stock_name] = 75.0
		stay_at_target_timer = 0.0
		_rotate_to_next_sector()
		var new_name = current_target_stock.get("name", "다음 급등주")
		var new_sec = current_target_stock.get("sector_name", "")
		auto_status_text = "🚨 [%s VI 발동] -> [%s (%s)] 즉시 이동!" % [stock_name, new_name, new_sec]
		print("[AutoPlay AI] VI 발동 감지! %s 거래 정지 -> 새로운 섹터 %s(%s)로 이동!" % [stock_name, new_name, new_sec])

func _on_auto_play_toggled(enabled: bool):
	is_auto_play = enabled
	if not enabled:
		auto_status_text = "🕹️ 수동 모드"
	else:
		manual_override_timer = 0.0
		auto_status_text = "🤖 AUTO 사냥 중"

func _on_breaking_news_nav(headline: String, sector_key: String, effect_type: String, duration: float):
	if MarketDataManager.sectors.has(sector_key):
		var sec = MarketDataManager.sectors[sector_key]
		var target = sec.get("position", Vector2.ZERO)
		if sec.has("stocks"):
			for st in sec["stocks"]:
				if st.get("name", "") in headline:
					target = st.get("world_pos", target)
					break
		auto_target_pos = target
		auto_status_text = "🚨 속보 출동: %s" % sec.get("name", sector_key)
		print("[PlayerAnt AI] 주식 속보 발생! 해당 좌표로 자동 질주: ", target)

func _draw():
	var font = ThemeDB.fallback_font

	# 0. Liquidity Magnet Area Visual Wave
	var mag_lvl = Global.skills["liquidity_magnet"]["level"] if Global.skills.has("liquidity_magnet") else 0
	if mag_lvl > 0:
		var mag_r = 180.0 + mag_lvl * 140.0
		var pulse = sin(Global.game_time * 3.5) * 8.0
		draw_arc(Vector2.ZERO, mag_r + pulse, 0.0, TAU, 36, Color(0.2, 0.75, 1.0, 0.12 + mag_lvl * 0.03), 2.0)

	# 1. Zone Buff/Debuff Auras
	if Global.player_iframe_timer > 0.0:
		# Invincible Barrier Visual
		var shield_pulse = sin(Global.game_time * 18.0) * 4.0
		draw_arc(Vector2.ZERO, 44.0 + shield_pulse, 0.0, TAU, 28, Color(1.0, 0.88, 0.3, 0.9), 3.0)
		draw_circle(Vector2.ZERO, 40.0, Color(1.0, 0.9, 0.3, 0.18))
	elif Global.in_bear_hazard:
		# Icy Frost Aura & Slowdown Indicator
		draw_circle(Vector2.ZERO, 36.0, Color(0.2, 0.55, 1.0, 0.28))
		draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 24, Color(0.4, 0.75, 1.0, 0.8), 2.5)
		draw_string(font, Vector2(-40, -38), "⚠️ 혹한기 감속 -10%", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.6, 0.85, 1.0))
	elif Global.in_bull_zone:
		# Golden Bullish Flame Aura
		draw_circle(Vector2.ZERO, 36.0, Color(1.0, 0.3, 0.2, 0.25))
		draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 24, Color(1.0, 0.8, 0.2, 0.8), 2.5)
		draw_string(font, Vector2(-40, -38), "🔥 불기둥 가속 +20%", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1.0, 0.9, 0.3))

	# 2. 360-Degree World Cyber Compass Ring (Cardinal directions: N/E/S/W without spoiler colors)
	draw_arc(Vector2.ZERO, 58.0, 0, TAU, 32, Color(0.4, 0.7, 1.0, 0.25), 1.5)
	
	# North Pointer (N needle pointing toward world North Vector2(0, -1))
	var world_north = Vector2(0, -1)
	var local_north = world_north.rotated(-rotation)
	var n_tip = local_north * 70.0
	var n_b1 = (local_north * 56.0) + Vector2(-local_north.y, local_north.x) * 6.0
	var n_b2 = (local_north * 56.0) - Vector2(-local_north.y, local_north.x) * 6.0
	draw_colored_polygon(PackedVector2Array([n_tip, n_b1, n_b2]), Color(0.85, 0.95, 1.0, 0.9))
	draw_string(font, local_north * 82.0 + Vector2(-6, 5), "N", HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color(0.85, 0.95, 1.0))
	
	# Subtle East/South/West tick marks
	var local_east = Vector2(1, 0).rotated(-rotation)
	var local_south = Vector2(0, 1).rotated(-rotation)
	var local_west = Vector2(-1, 0).rotated(-rotation)
	draw_line(local_east * 52.0, local_east * 58.0, Color(0.5, 0.8, 1.0, 0.4), 1.5)
	draw_line(local_south * 52.0, local_south * 58.0, Color(0.5, 0.8, 1.0, 0.4), 1.5)
	draw_line(local_west * 52.0, local_west * 58.0, Color(0.5, 0.8, 1.0, 0.4), 1.5)

	# 3. Draw HODL golden aura if active
	if is_hodl_active:
		draw_circle(Vector2.ZERO, 32.0, Color(1.0, 0.85, 0.2, 0.4))
		draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.1, 0.9), 3.0)
		
	# 4. Luminous Hero Backlight Aura (Ensures black ant pops brightly against dark background)
	var aura_pulse = sin(Global.game_time * 4.0) * 3.0
	# Outer soft ambient glow
	draw_circle(Vector2.ZERO, 40.0 + aura_pulse, Color(0.2, 0.7, 1.0, 0.22))
	# Mid vibrant aura
	draw_circle(Vector2.ZERO, 32.0 + aura_pulse * 0.5, Color(0.35, 0.85, 1.0, 0.35))
	# Crisp radiant halo ring
	draw_arc(Vector2.ZERO, 35.0 + aura_pulse * 0.5, 0.0, TAU, 36, Color(0.7, 0.95, 1.0, 0.85), 2.0)

	# 5. Ant Body & Limbs Color (Pure Solid Black)
	var body_black = Color(0.08, 0.08, 0.10)

	# 6. Ant Legs (All Black)
	var leg_pairs = [
		[Vector2(-6, -7), Vector2(-12, -18)],
		[Vector2(0, -8), Vector2(0, -20)],
		[Vector2(6, -7), Vector2(12, -18)],
		[Vector2(-6, 7), Vector2(-12, 18)],
		[Vector2(0, 8), Vector2(0, 20)],
		[Vector2(6, 7), Vector2(12, 18)]
	]
	for pair in leg_pairs:
		draw_line(pair[0], pair[1], body_black, 2.5)
		draw_circle(pair[1], 2.2, body_black)

	# 7. Ant Body Graphics (Pure Simple Solid Black)
	# Abdomen (back)
	var abd_pos = Vector2(-16, 0)
	draw_circle(abd_pos, 13.5, body_black)

	# Thorax (middle)
	var thx_pos = Vector2(0, 0)
	draw_circle(thx_pos, 9.5, body_black)

	# Head (front - All Black)
	var head_pos = Vector2(15, 0)
	draw_circle(head_pos, 11.5, body_black)

	# Ant Antennae (All Black)
	draw_line(head_pos + Vector2(6, -4), head_pos + Vector2(16, -13), body_black, 2.2)
	draw_line(head_pos + Vector2(6, 4), head_pos + Vector2(16, 13), body_black, 2.2)
	draw_circle(head_pos + Vector2(16, -13), 2.5, body_black)
	draw_circle(head_pos + Vector2(16, 13), 2.5, body_black)

	# 8. 방치형 AUTO-PLAY 상태 머리 위 네온 뱃지 (월드 방향 수평 유지)
	var badge_pos = Vector2(0, -44).rotated(-rotation) + Vector2(-120, 0)
	var badge_color = Color(1.0, 0.88, 0.25) if is_auto_play else Color(0.4, 0.8, 1.0)
	draw_string(font, badge_pos, auto_status_text, HORIZONTAL_ALIGNMENT_CENTER, 240, 13, badge_color)


func _physics_process(delta):
	if Global.is_game_over or Global.is_paused:
		return
		
	# 1. 수동 입력 확인 (키보드 또는 가상 조이스틱)
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO and Global.joystick_vector.length() > 0:
		input_dir = Global.joystick_vector
		
	if input_dir.length() > 0.1:
		manual_override_timer = 3.0 # 유저 터치 시 3초간 수동 조작 우선
		is_auto_play = false
		auto_status_text = "🕹️ 수동 조작 중"
	else:
		if manual_override_timer > 0:
			manual_override_timer -= delta
		elif Global.auto_play_enabled:
			is_auto_play = true # 손을 떼면 방치형 AUTO-PLAY 모드로 자동 전환!
		else:
			is_auto_play = false
			auto_status_text = "🕹️ 수동 대기 중"

	var scalping_lvl = Global.skills["scalping"]["level"] if Global.skills.has("scalping") else 0
	var speed_mult = (1.6 if is_hodl_active else 1.0) * Global.player_speed_modifier * Global.bonus_speed_multiplier * (1.0 + scalping_lvl * 0.10)
	if is_auto_play and is_on_highway_cruise:
		speed_mult *= 1.4 # 섹터 간 고속도로 이동 시 쾌속 순항 가속 +40%!
	
	if not is_auto_play:
		velocity = input_dir.normalized() * move_speed * speed_mult
		if input_dir.length() > 0:
			rotation = lerp_angle(rotation, input_dir.angle(), 15.0 * delta)
	else:
		# 🤖 방치형 AUTO-PLAY AI 계산
		var auto_dir = _calculate_auto_play_direction(delta)
		velocity = auto_dir.normalized() * move_speed * speed_mult
		if auto_dir.length() > 0.05:
			rotation = lerp_angle(rotation, auto_dir.angle(), 12.0 * delta)
		
	move_and_slide()
	queue_redraw()
	
	# Process timers
	_process_weapons(delta)
	
	if iframe_timer > 0:
		iframe_timer -= delta

# ------------------------------------------------------------------------------
# 🤖 방치형 자율 사냥 & 전국/글로벌 섹터 순회 AI (Auto-Play Logic)
# ------------------------------------------------------------------------------
func _select_best_rising_stock() -> Dictionary:
	var best_stock: Dictionary = {}
	var best_score: float = -999999.0
	
	for sec_key in MarketDataManager.sectors.keys():
		var sec = MarketDataManager.sectors[sec_key]
		if not sec.has("stocks"):
			continue
		for stock in sec["stocks"]:
			# 🚨 VI 발동(거래 정지/서킷 브레이커) 중인 종목은 즉시 제외!
			if stock.get("is_halted", false):
				continue
				
			var rate = stock.get("rate", 0.0)
			var st_pos = stock.get("world_pos", sec.get("position", Vector2.ZERO))
			var dist = global_position.distance_to(st_pos)
			
			# 1. 상승률(rate) 기본 점수 (1%당 300점)
			var score = (rate * 300.0)
			
			# 2. 양수(상승) 프리미엄
			if rate > 0.0:
				score += 3000.0
			if rate >= 8.0:
				score += 1500.0 # 고수익 급등주 추가 보너스
				
			# 3. 새로운 섹터 우선 탐방 보너스 (여러 섹터 적극 순회!)
			if not current_target_stock.is_empty():
				var cur_sec = current_target_stock.get("sector_key", "")
				if sec_key != cur_sec and not visited_sector_cooldowns.has(sec_key):
					score += 2500.0 # 다른 미방문 섹터로 이동하는 강력한 인센티브!
			
			# 4. 최근 방문 종목/섹터 감점 (방금 수확 완료한 곳 제외)
			if visited_stock_cooldowns.has(stock["name"]):
				score -= 8000.0
			if visited_sector_cooldowns.has(sec_key):
				score -= 4000.0
				
			# 5. 거리 감점 대폭 완화 (기존 dist / 10.0 -> dist * 0.015 로 98% 완화!)
			# 5000px 거리라도 감점은 고작 75점에 불과하여 전 섹터를 자유롭게 순회!
			score -= (dist * 0.015)
				
			if score > best_score:
				best_score = score
				best_stock = stock.duplicate()
				best_stock["sector_key"] = sec_key
				best_stock["sector_name"] = sec.get("name", "")
				
	return best_stock

func _calculate_auto_play_direction(delta: float) -> Vector2:
	# 1. 최근 방문 쿨다운 타이머 감쇄
	for k in visited_stock_cooldowns.keys():
		visited_stock_cooldowns[k] -= delta
		if visited_stock_cooldowns[k] <= 0.0:
			visited_stock_cooldowns.erase(k)
			
	for k in visited_sector_cooldowns.keys():
		visited_sector_cooldowns[k] -= delta
		if visited_sector_cooldowns[k] <= 0.0:
			visited_sector_cooldowns.erase(k)

	# 2. 속보 긴급 목표가 유효하고 아직 도착하지 않았을 때
	if auto_target_pos != Vector2.ZERO:
		var to_news = auto_target_pos - global_position
		if to_news.length() > 220.0:
			auto_status_text = "🚨 속보 성역으로 고속도로 질주!"
			is_on_highway_cruise = true
			return to_news.normalized()
		else:
			auto_target_pos = Vector2.ZERO # 도착 완료
			
	# 3. 현재 타겟 검증 및 없으면 즉시 선택
	if current_target_stock.is_empty() or current_target_stock.get("is_halted", false):
		current_target_stock = _select_best_rising_stock()

	# 4. 근접 위험 적 회피 & 카이팅 (< 230px)
	var enemies = get_tree().get_nodes_in_group("enemy")
	var danger_enemy: Node2D = null
	var min_danger_dist: float = 230.0
	
	for e in enemies:
		if is_instance_valid(e) and not e.is_dead:
			var d = global_position.distance_to(e.global_position)
			if d < min_danger_dist:
				min_danger_dist = d
				danger_enemy = e
				
	if danger_enemy:
		var to_danger = danger_enemy.global_position - global_position
		var e_name = danger_enemy.get("stock_name") if "stock_name" in danger_enemy else "적"
		auto_status_text = "⚔️ 근접 교전: %s" % str(e_name)
		if min_danger_dist < 120.0:
			return -to_danger.normalized() # 너무 가까우면 즉시 후퇴
		else:
			# 측면 회피 기동
			return Vector2(-to_danger.y, to_danger.x).normalized() * 0.85

	# 5. 근처 배당금 젬(EXP) 흡수 (가까운 반경 220px)
	var gems = get_tree().get_nodes_in_group("exp_gem")
	if not gems.is_empty():
		for g in gems:
			if is_instance_valid(g) and global_position.distance_to(g.global_position) < 220.0:
				return (g.global_position - global_position).normalized()

	# 6. 상승 종목 성역으로 질주 & 순회 파밍
	if not current_target_stock.is_empty():
		var st_name = current_target_stock.get("name", "상승 종목")
		var st_rate = current_target_stock.get("rate", 0.0)
		var sec_name = current_target_stock.get("sector_name", "")
		var st_pos = current_target_stock.get("world_pos", global_position)
		var to_st = st_pos - global_position
		var dist_to_st = to_st.length()
		
		# 해당 종목 성역으로 이동 중 (고속도로 쾌속 이동)
		if dist_to_st > 350.0:
			is_on_highway_cruise = true
			var sign_str = "+" if st_rate >= 0.0 else ""
			auto_status_text = "🛣️ [%s] %s (%s%.1f%%) 고속 순항" % [sec_name, st_name, sign_str, st_rate]
			return to_st.normalized()
		else:
			# 성역 도착: 해당 종목 제단 주변에서 16초간 체류하며 집중 사냥 & 배당 수확!
			is_on_highway_cruise = false
			stay_at_target_timer += delta
			var time_left = int(ceil(max(0.0, 16.0 - stay_at_target_timer)))
			auto_status_text = "🔥 [%s +%.1f%%] 수확 중 (%ds)" % [st_name, st_rate, time_left]
			
			# 16초 체류 완료 시 다음 섹터 급등주로 전환!
			if stay_at_target_timer >= 16.0:
				stay_at_target_timer = 0.0
				_rotate_to_next_sector()
				if not current_target_stock.is_empty():
					var next_st = current_target_stock.get("name", "")
					var next_sec = current_target_stock.get("sector_name", "")
					auto_status_text = "✅ [%s] 수확 완료! -> [%s (%s)] 출발!" % [st_name, next_st, next_sec]
				return Vector2.ZERO
				
			patrol_timer += delta
			var orbit_vec = Vector2(cos(patrol_timer * 1.6), sin(patrol_timer * 1.6)) * 150.0
			var patrol_target = st_pos + orbit_vec
			return (patrol_target - global_position).normalized()

	# 7. 기본 폴백: 중앙 광장 주변 완만한 패트롤
	is_on_highway_cruise = false
	patrol_timer += delta
	return Vector2(cos(patrol_timer * 0.8), sin(patrol_timer * 0.8))

func _process_weapons(delta):
	# 1. Green Candle Beam
	var gbeam_lvl = Global.skills["green_beam"]["level"]
	if gbeam_lvl > 0:
		green_beam_timer += delta
		var scalping_lvl = Global.skills["scalping"]["level"] if Global.skills.has("scalping") else 0
		var cooldown = max(0.10, (0.65 - gbeam_lvl * 0.10) * (1.0 - scalping_lvl * 0.10))
		if green_beam_timer >= cooldown:
			green_beam_timer = 0.0
			_fire_green_beam(gbeam_lvl)
			
	# 2. DCA Shield (Orbiters)
	var dca_lvl = Global.skills["dca_shield"]["level"]
	_update_dca_orbs(dca_lvl)
	
	# 3. Stop Loss Shock
	var stop_loss_lvl = Global.skills["stop_loss"]["level"]
	if stop_loss_lvl > 0:
		stop_loss_timer += delta
		var hp_percent = Global.player_hp / Global.player_max_hp
		if stop_loss_timer >= 8.0 or (hp_percent < 0.35 and stop_loss_timer >= 2.0):
			stop_loss_timer = 0.0
			_trigger_stop_loss(stop_loss_lvl)
			
	# 4. HODL Shield
	var hodl_lvl = Global.skills["hodl_shield"]["level"]
	if hodl_lvl > 0:
		if is_hodl_active:
			hodl_duration -= delta
			if hodl_duration <= 0:
				is_hodl_active = false
		else:
			hodl_timer += delta
			if hodl_timer >= 10.0:
				hodl_timer = 0.0
				is_hodl_active = true
				hodl_duration = 3.5 + hodl_lvl * 0.5
				SoundManager.play_boss_alert()

	# 5. Dividend Reinvestment Passive Healing
	if Global.skills.has("dividend_reinvest"):
		var div_lvl = Global.skills["dividend_reinvest"]["level"]
		if div_lvl > 0:
			dividend_regen_timer += delta
			if dividend_regen_timer >= 2.0:
				dividend_regen_timer = 0.0
				Global.heal_player(div_lvl * 3.5)

	# 6. Liquidity Magnet Periodic Pulse (At Lv 5: Every 10s vacuum all gems within 1800m)
	if Global.skills.has("liquidity_magnet"):
		var mag_lvl = Global.skills["liquidity_magnet"]["level"]
		if mag_lvl >= 5:
			magnet_pulse_timer += delta
			if magnet_pulse_timer >= 10.0:
				magnet_pulse_timer = 0.0
				SoundManager.play_exp_coin()
				var gems = get_tree().get_nodes_in_group("exp_gem")
				for g in gems:
					if is_instance_valid(g) and g.has_method("attract_to"):
						if global_position.distance_to(g.global_position) < 1800.0:
							g.attract_to(self)

func _fire_green_beam(level: int):
	SoundManager.play_shoot_beam()
	var quant_lvl = Global.skills["quant_ai"]["level"] if Global.skills.has("quant_ai") else 0
	
	if level >= 5:
		# Evolution: 8-Directional Barrage!
		for i in range(8):
			var angle = i * (TAU / 8.0)
			var proj = proj_scene.instantiate()
			proj.type = proj.Type.GREEN_BEAM
			proj.damage = 50.0
			proj.speed = 750.0
			proj.pierce_count = 12 + quant_lvl * 2
			proj.global_position = global_position
			proj.direction = Vector2.RIGHT.rotated(angle)
			proj.rotation = angle
			get_parent().add_child(proj)
	else:
		# Target nearest enemy or facing direction
		var target_dir = Vector2.RIGHT.rotated(rotation)
		var nearest_enemy = _find_nearest_enemy()
		if nearest_enemy:
			target_dir = (nearest_enemy.global_position - global_position).normalized()
			
		var count = 1 + int((level - 1) * 0.75)
		for i in range(count):
			var spread = (i - (count - 1) * 0.5) * 0.18
			var proj = proj_scene.instantiate()
			proj.type = proj.Type.GREEN_BEAM
			proj.damage = 30.0 + level * 8.0
			proj.speed = 700.0
			proj.pierce_count = 2 + level + quant_lvl
			proj.global_position = global_position
			proj.direction = target_dir.rotated(spread)
			proj.rotation = proj.direction.angle()
			get_parent().add_child(proj)

func _update_dca_orbs(level: int):
	var target_count = level * 2
	while dca_orbs.size() < target_count:
		var orb = proj_scene.instantiate()
		orb.type = orb.Type.DCA_ORB
		orb.damage = 15.0 + level * 5.0
		orb.parent_player = self
		orb.orb_angle = (dca_orbs.size() * TAU) / max(1, target_count)
		get_parent().add_child.call_deferred(orb)
		dca_orbs.append(orb)
		
	# Remove extra orbs if level decreased (unlikely)
	while dca_orbs.size() > target_count:
		var orb = dca_orbs.pop_back()
		if is_instance_valid(orb):
			orb.queue_free()

func _trigger_stop_loss(level: int):
	SoundManager.play_shockwave()
	Global.heal_player(15.0 + level * 10.0)
	
	var shock = proj_scene.instantiate()
	shock.type = shock.Type.STOP_LOSS_SHOCK
	shock.damage = 40.0 + level * 15.0
	shock.global_position = global_position
	get_parent().add_child(shock)

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var best_target: Node2D = null
	var best_score: float = -99999.0
	for e in enemies:
		if is_instance_valid(e) and not e.is_dead:
			var d = global_position.distance_to(e.global_position)
			if d <= 900.0:
				var score = (900.0 - d)
				if e.is_boss:
					score += 600.0
				elif e.polarity == Enemy.Polarity.BULL:
					score += 250.0 # 상승 랠리 종목 적 우선 타겟팅
				if score > best_score:
					best_score = score
					best_target = e
	return best_target

func _on_magnet_area_entered(area):
	if area.is_in_group("exp_gem") and area.has_method("attract_to"):
		area.attract_to(self)

func update_magnet_radius():
	var mag_lvl = Global.skills["liquidity_magnet"]["level"] if Global.skills.has("liquidity_magnet") else 0
	var magnet_shape = get_node_or_null("MagnetArea/CollisionShape2D")
	if magnet_shape and magnet_shape.shape is CircleShape2D:
		# Base 180px, +140px per level (Lv 5 = 880px!)
		magnet_shape.shape.radius = 180.0 + mag_lvl * 140.0
