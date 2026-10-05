extends Node2D

@onready var player: Node2D = $Player
@onready var enemy_container: Node2D = $EnemyContainer

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

var spawn_timer: float = 0.0
var spawn_interval: float = 1.8

# Background visual elements
var chart_points: Array = []
var bg_candlesticks: Array = []
var floating_tickers: Array = []
var bear_boss_spawned: bool = false
var powell_boss_spawned: bool = false

func _ready():
	# 1. Main moving average chart graph points
	for i in range(50):
		chart_points.append(Vector2(i * 90 - 2200, randf_range(-400, 400)))

	# 2. Background Candlestick Columns (Green & Red candles in background depth)
	for i in range(30):
		bg_candlesticks.append({
			"pos": Vector2(randf_range(-2500, 2500), randf_range(-2500, 2500)),
			"height": randf_range(40, 160),
			"width": randf_range(16, 28),
			"is_bull": randf() > 0.35, # 65% green candles
			"phase": randf() * TAU
		})

	# 3. Floating Holographic Ticker Labels
	var stock_names = ["KOSPI ▲ 3,200", "NVDA 🚀 +150%", "TO THE MOON 🌕", "TSLA ▲ +25%", "AAPL ▲ +12%", "상한가 빔 🟢", "BTC ▲ $100K", "DCA WINNER 💧"]
	for i in range(20):
		floating_tickers.append({
			"pos": Vector2(randf_range(-2000, 2000), randf_range(-2000, 2000)),
			"text": stock_names[i % stock_names.size()],
			"speed": randf_range(15.0, 35.0),
			"alpha": randf_range(0.25, 0.6)
		})

func _draw():
	var cam_pos = $Camera2D.global_position if has_node("Camera2D") else Vector2.ZERO
	var viewport_size = Vector2(1280, 720)
	
	# A. Vibrant Deep Midnight Blue / Cyberpunk Base Fill
	var base_rect = Rect2(cam_pos - viewport_size * 1.5, viewport_size * 3.0)
	draw_rect(base_rect, Color(0.04, 0.05, 0.12, 1.0))
	
	# B. Player Radiant Radial Aura (Bull Market Golden & Emerald Glow)
	var is_low_hp = Global.player_hp < Global.player_max_hp * 0.3
	var aura_color = Color(1.0, 0.2, 0.2, 0.12) if is_low_hp else Color(0.0, 1.0, 0.5, 0.15)
	draw_circle(cam_pos, 450.0, aura_color)
	draw_circle(cam_pos, 250.0, Color(1.0, 0.85, 0.2, 0.1) if not is_low_hp else Color(1.0, 0.1, 0.1, 0.1))

	# C. Dual-Tone Cyberpunk Grid (Neon Emerald Green + Magenta Grid lines)
	var grid_size = 120
	var start_x = int(cam_pos.x - 1600) / grid_size * grid_size
	var end_x = int(cam_pos.x + 1600) / grid_size * grid_size
	var start_y = int(cam_pos.y - 1000) / grid_size * grid_size
	var end_y = int(cam_pos.y + 1000) / grid_size * grid_size
	
	var grid_time = fmod(Global.game_time * 40.0, float(grid_size))
	
	for x in range(start_x, end_x, grid_size):
		var is_major = (x / grid_size) % 4 == 0
		var line_col = Color(0.0, 1.0, 0.6, 0.35) if is_major else Color(0.8, 0.1, 0.6, 0.2)
		var thickness = 2.0 if is_major else 1.0
		draw_line(Vector2(x, start_y), Vector2(x, end_y), line_col, thickness)
		
	for y in range(start_y, end_y, grid_size):
		var is_major = (y / grid_size) % 4 == 0
		var line_col = Color(0.0, 1.0, 0.6, 0.35) if is_major else Color(0.8, 0.1, 0.6, 0.2)
		var thickness = 2.0 if is_major else 1.0
		draw_line(Vector2(start_x, y), Vector2(end_x, y), line_col, thickness)

	# D. Render Background Candlestick Columns
	for candle in bg_candlesticks:
		var c_pos = candle["pos"]
		if cam_pos.distance_to(c_pos) < 1800.0:
			var h = candle["height"] + sin(Global.game_time * 2.0 + candle["phase"]) * 12.0
			var w = candle["width"]
			var is_bull = candle["is_bull"]
			
			var fill_color = Color(0.0, 0.9, 0.4, 0.3) if is_bull else Color(0.9, 0.15, 0.2, 0.3)
			var border_color = Color(0.4, 1.0, 0.6, 0.6) if is_bull else Color(1.0, 0.4, 0.4, 0.6)
			
			# Wick line
			draw_line(c_pos + Vector2(0, -h * 0.7), c_pos + Vector2(0, h * 0.7), border_color, 2.0)
			# Candle body
			var rect = Rect2(c_pos - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
			draw_rect(rect, fill_color)
			draw_rect(rect, border_color, false, 2.0)
			
			# Glowing flame tip for bull candles
			if is_bull:
				draw_circle(c_pos + Vector2(0, -h * 0.7), 4.0, Color(1.0, 0.9, 0.2, 0.8))

	# E. Render Parallax Moving Average Neon Chart Line Graph
	for i in range(chart_points.size() - 1):
		var p1 = chart_points[i]
		var p2 = chart_points[i+1]
		var line_color = Color(0.0, 1.0, 0.5, 0.7) if p2.y < p1.y else Color(1.0, 0.2, 0.3, 0.7)
		draw_line(p1, p2, line_color, 4.0)
		# Glowing dot on chart peaks
		if i % 3 == 0:
			draw_circle(p1, 5.0, Color(1.0, 0.9, 0.3, 0.8))

	# F. Floating Holographic Stock Tickers
	var font = ThemeDB.fallback_font
	for ticker in floating_tickers:
		var t_pos = ticker["pos"]
		if cam_pos.distance_to(t_pos) < 1500.0:
			draw_string(font, t_pos, ticker["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.2, 1.0, 0.6, ticker["alpha"]))

func _process(delta):
	queue_redraw()
	
	if Global.is_game_over or Global.is_paused:
		return
		
	# Update background graph line animation
	for i in range(chart_points.size()):
		chart_points[i].y += sin(Global.game_time * 2.5 + i * 0.5) * 16.0 * delta
		
	# Float tickers upward
	for ticker in floating_tickers:
		ticker["pos"].y -= ticker["speed"] * delta
		if ticker["pos"].y < -2200.0:
			ticker["pos"].y = 2200.0
			ticker["pos"].x = randf_range(-2000, 2000)
			
	_process_enemy_spawning(delta)

func _process_enemy_spawning(delta):
	spawn_timer += delta
	spawn_interval = max(0.4, 2.0 - (Global.game_time / 180.0) * 1.5)
	
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy_wave()
		
	# Check Mid Boss (3m = 180s)
	if Global.game_time >= 180.0 and not bear_boss_spawned:
		bear_boss_spawned = true
		_spawn_boss(enemy_scene.instantiate().EnemyType.BEAR_BOSS)
		SoundManager.play_boss_alert()
		
	# Check Final Boss (5m = 300s)
	if Global.game_time >= 300.0 and not powell_boss_spawned:
		powell_boss_spawned = true
		_spawn_boss(enemy_scene.instantiate().EnemyType.POWELL_BOSS)
		SoundManager.play_boss_alert()

func _spawn_enemy_wave():
	var t = Global.game_time
	var type_to_spawn = enemy_scene.instantiate().EnemyType.PANIC_SELL
	var rand_val = randf()
	if t < 60.0:
		type_to_spawn = enemy_scene.instantiate().EnemyType.PANIC_SELL
	elif t < 120.0:
		type_to_spawn = enemy_scene.instantiate().EnemyType.FAKE_NEWS if rand_val > 0.5 else enemy_scene.instantiate().EnemyType.PANIC_SELL
	else:
		if rand_val < 0.4:
			type_to_spawn = enemy_scene.instantiate().EnemyType.PANIC_SELL
		elif rand_val < 0.7:
			type_to_spawn = enemy_scene.instantiate().EnemyType.FAKE_NEWS
		else:
			type_to_spawn = enemy_scene.instantiate().EnemyType.RED_CANDLE
			
	_spawn_single_enemy(type_to_spawn)

func _spawn_single_enemy(e_type):
	if not is_instance_valid(player):
		return
	var angle = randf() * TAU
	var spawn_dist = randf_range(650.0, 800.0)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_dist
	
	var enemy = enemy_scene.instantiate()
	enemy.type = e_type
	enemy.global_position = spawn_pos
	enemy_container.add_child(enemy)

func _spawn_boss(b_type):
	if not is_instance_valid(player):
		return
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 600.0
	
	var boss = enemy_scene.instantiate()
	boss.type = b_type
	boss.global_position = spawn_pos
	enemy_container.add_child(boss)

				var badge_str = "%s%s %s%.1f%%" % [badge_icon, stock["name"], st_sign, abs(stock["rate"])]
				var badge_col = Color(1.0, 0.9, 0.2) if is_super_bull else (Color(0.4, 0.8, 1.0) if is_deep_bear else Color(1, 1, 1))
				
				draw_string(font, st_pos + Vector2(-230, -56), badge_str, HORIZONTAL_ALIGNMENT_CENTER, 460, 42, badge_col)
				draw_string(font, st_pos + Vector2(-230, 88), stock.get("desc", ""), HORIZONTAL_ALIGNMENT_CENTER, 460, 28, st_col)

func _process(delta):
	queue_redraw()
	
	if Global.is_game_over or Global.is_paused:
		return
		
	# Update background graph line animation
	for i in range(chart_points.size()):
		chart_points[i].y += sin(Global.game_time * 2.0 + i) * 12.0 * delta
		
	if is_instance_valid(player):
		MarketDataManager.record_player_position(player.global_position, delta)
		_process_sector_mechanics(delta)
		
	_process_enemy_spawning(delta)
	_process_market_events(delta)

func _process_sector_mechanics(delta):
	sector_tick_timer += delta
	if sector_tick_timer < 0.2:
		return
	sector_tick_timer = 0.0
	
	var cur_sec = MarketDataManager.get_sector_at(player.global_position)
	var near_stock = MarketDataManager.get_nearest_stock_at(player.global_position)
	
	# Determine if player is in a BULL zone or BEAR hazard zone
	var effective_rate = cur_sec.get("change_rate", 0.0)
	if not near_stock.is_empty():
		effective_rate = near_stock.get("rate", effective_rate)
		
	if effective_rate >= 3.0:
		# 🟢/🔴 BULL ZONE: Massive Rewards!
		Global.in_bull_zone = true
		Global.in_bear_hazard = false
		Global.player_speed_modifier = 1.20 # +20% Move Speed!
		Global.exp_multiplier = 1.6 # +60% EXP!
		
		# Super Bull Stock (e.g. Hanmi Semiconductor / NVDA): Periodic Bonus Dividend Gem drop!
		if effective_rate >= 10.0 and randf() < 0.40:
			var gem = gem_scene.instantiate()
			gem.exp_value = 16
			var angle = randf() * TAU
			gem.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(60, 200)
			call_deferred("add_child", gem)
			
	elif effective_rate <= -2.5:
		# 🔵 BEAR HAZARD ZONE: Severe Penalties for going the wrong way!
		Global.in_bear_hazard = true
		Global.in_bull_zone = false
		Global.player_speed_modifier = 0.80 # -20% Speed Penalty (Slowed down in panic fog)
		Global.exp_multiplier = 0.6 # -40% EXP Penalty
		
		# Severe damage & rapid portfolio bleed!
		Global.take_player_damage(1.5 * 0.2 * 2.5)
		Global.portfolio_return = max(0.0, Global.portfolio_return - 4.0 * 0.2)
		
		# Catastrophic Stock Hazard (e.g. EcoproBM / Tesla): Extra severe bleed!
		if effective_rate <= -6.0:
			Global.portfolio_return = max(0.0, Global.portfolio_return - 6.0 * 0.2)
			
	else:
		# Neutral Plaza / Outskirts
		Global.in_bull_zone = false
		Global.in_bear_hazard = false
		Global.player_speed_modifier = 1.0
		if Global.current_market_event == "":
			Global.exp_multiplier = 1.0

func _process_market_events(delta):
	# Handle active event timeout
	if Global.event_remaining_time > 0:
		Global.event_remaining_time -= delta
		if Global.event_remaining_time <= 0:
			_end_current_event()
			
	event_timer += delta
	if event_timer >= next_event_time:
		event_timer = 0.0
		next_event_time = randf_range(40.0, 55.0)
		_trigger_random_market_event()

func _trigger_random_market_event():
	var roll = randi() % 3
	match roll:
		0:
			# Circuit Breaker: Freeze all enemies for 5 seconds
			Global.current_market_event = "CIRCUIT_BREAKER"
			Global.enemy_speed_multiplier = 0.0
			Global.event_remaining_time = 5.0
			SoundManager.play_boss_alert()
			Global.market_event_triggered.emit("🚨 [서킷 브레이커 발동]", "5초간 모든 거래 정지! 프리 딜 찬스!")
		1:
			# Dividend Party: Drop 16 EXP gems around player
			Global.current_market_event = "DIVIDEND"
			SoundManager.play_level_up()
			Global.market_event_triggered.emit("🎁 [특별 배당금 파티]", "주변에 황금 배당금 젬 대량 투하!")
			if is_instance_valid(player):
				for i in range(16):
					var gem = gem_scene.instantiate()
					gem.exp_value = 8
					var angle = randf() * TAU
					var dist = randf_range(80.0, 300.0)
					gem.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
					call_deferred("add_child", gem)
		2:
			# Earnings Shock: 8s enemies fast, 2x exp
			Global.current_market_event = "EARNINGS_SHOCK"
			Global.enemy_speed_multiplier = 1.3
			Global.exp_multiplier = 2.0
			Global.event_remaining_time = 8.0
			SoundManager.play_shockwave()
			Global.market_event_triggered.emit("💣 [어닝 쇼크 발생]", "적 공격성 급증! (수익 획득 2배 구간)")

func _end_current_event():
	Global.current_market_event = ""
	Global.enemy_speed_multiplier = 1.0
	Global.exp_multiplier = 1.0
	Global.market_event_triggered.emit("📊 [증시 정상화]", "특별 증시 이벤트가 종료되었습니다.")

func _process_enemy_spawning(delta):
	spawn_timer += delta
	
	# Spawn rate increases with game time
	spawn_interval = max(0.4, 2.0 - (Global.game_time / 180.0) * 1.5)
	
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy_wave()
		
	# Check Mid Boss (3m = 180s)
	if Global.game_time >= 180.0 and not bear_boss_spawned:
		bear_boss_spawned = true
		_spawn_boss(enemy_scene.instantiate().EnemyType.BEAR_BOSS)
		SoundManager.play_boss_alert()
		
	# Check Final Boss (5m = 300s)
	Global.market_event_triggered.emit("📊 [증시 정상화]", "특별 증시 이벤트가 종료되었습니다.")

func _process_enemy_spawning(delta):
	spawn_timer += delta
	
	# Spawn rate increases with game time
	spawn_interval = max(0.4, 2.0 - (Global.game_time / 180.0) * 1.5)
	
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy_wave()
		
	# Check Mid Boss (3m = 180s)
	if Global.game_time >= 180.0 and not bear_boss_spawned:
		bear_boss_spawned = true
		_spawn_boss(enemy_scene.instantiate().EnemyType.BEAR_BOSS)
		SoundManager.play_boss_alert()
		
	# Check Final Boss (5m = 300s)
	if Global.game_time >= 300.0 and not powell_boss_spawned:
		powell_boss_spawned = true
		_spawn_boss(enemy_scene.instantiate().EnemyType.POWELL_BOSS)
		SoundManager.play_boss_alert()

func _spawn_enemy_wave():
	var t = Global.game_time
	var type_to_spawn = enemy_scene.instantiate().EnemyType.PANIC_SELL
	
	var rand_val = randf()
	if t < 60.0:
		type_to_spawn = enemy_scene.instantiate().EnemyType.PANIC_SELL
	elif t < 120.0:
		type_to_spawn = enemy_scene.instantiate().EnemyType.FAKE_NEWS if rand_val > 0.5 else enemy_scene.instantiate().EnemyType.PANIC_SELL
	else:
		if rand_val < 0.4:
			type_to_spawn = enemy_scene.instantiate().EnemyType.PANIC_SELL
		elif rand_val < 0.7:
			type_to_spawn = enemy_scene.instantiate().EnemyType.FAKE_NEWS
		else:
			type_to_spawn = enemy_scene.instantiate().EnemyType.RED_CANDLE
			
	_spawn_single_enemy(type_to_spawn)

func _spawn_single_enemy(e_type):
	if not is_instance_valid(player):
		return
		
	var angle = randf() * TAU
	var spawn_dist = randf_range(800.0, 1100.0)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_dist
	
	var enemy = enemy_scene.instantiate()
	enemy.type = e_type
	
	# Determine Polarity based on player's chosen branch & stock!
	var cur_sec = MarketDataManager.get_sector_at(player.global_position)
	var is_bull_sector = cur_sec.get("change_rate", 0.0) >= 0.0
	enemy.polarity = Enemy.Polarity.BULL if is_bull_sector else Enemy.Polarity.BEAR
	enemy.global_position = spawn_pos
	enemy_container.add_child(enemy)

func _spawn_boss(b_type):
	if not is_instance_valid(player):
		return
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 700.0
	
	var boss = enemy_scene.instantiate()
	boss.type = b_type
	boss.global_position = spawn_pos
	enemy_container.add_child(boss)
