extends Node2D

@onready var player: Node2D = $Player
@onready var enemy_container: Node2D = $EnemyContainer

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var gem_scene: PackedScene = preload("res://scenes/exp_gem.tscn")

var spawn_timer: float = 0.0
var spawn_interval: float = 1.8
var chart_points: Array = []
var bg_candlesticks: Array = []
var bear_boss_spawned: bool = false
var candle_boss_spawned: bool = false
var trump_boss_spawned: bool = false
var event_timer: float = 0.0
var next_event_time: float = 30.0
var sector_tick_timer: float = 0.0

func _ready():
	# 1. Background moving average neon chart wave
	for i in range(48):
		chart_points.append(Vector2(i * 120 - 2800, randf_range(-350, 350)))
		
	# 2. Atmospheric Candlestick columns across world
	for i in range(40):
		var angle = randf() * TAU
		var dist = randf_range(600.0, 7500.0)
		bg_candlesticks.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"height": randf_range(60.0, 180.0),
			"width": randf_range(20.0, 36.0),
			"is_bull": randf() > 0.4,
			"phase": randf() * TAU
		})
		
	MarketDataManager.reset_match_data()

func _draw():
	var cam_pos = player.global_position if is_instance_valid(player) else Vector2.ZERO
	var view_margin = Vector2(850.0, 1500.0)
	var view_rect = Rect2(cam_pos - view_margin, view_margin * 2.0)

	# 1. High-Tech Cyber Grid with Glowing Crosshair Intersections
	_draw_cyber_grid(cam_pos, view_margin, view_rect)

	# 2. Ambient Candlestick Columns in View
	_draw_ambient_candlesticks(cam_pos, view_rect)

	# 3. Parallax Moving Average Neon Wave
	_draw_chart_wave(cam_pos)

	# 4. Central Exchange Plaza, Grand Expressways, Sector Biomes, Stock Sanctuaries
	_draw_world_infrastructure(cam_pos, view_rect)

func _draw_cyber_grid(cam_pos: Vector2, view_margin: Vector2, view_rect: Rect2):
	var grid_size = 140
	var start_x = int((cam_pos.x - view_margin.x) / grid_size) * grid_size - grid_size
	var end_x = int((cam_pos.x + view_margin.x) / grid_size) * grid_size + grid_size
	var start_y = int((cam_pos.y - view_margin.y) / grid_size) * grid_size - grid_size
	var end_y = int((cam_pos.y + view_margin.y) / grid_size) * grid_size + grid_size
	
	var minor_lines = PackedVector2Array()
	var major_lines = PackedVector2Array()
	var cross_points = PackedVector2Array()
	
	for x in range(start_x, end_x + grid_size, grid_size):
		var is_major = (int(x / grid_size) % 3 == 0)
		if is_major:
			major_lines.append(Vector2(x, start_y))
			major_lines.append(Vector2(x, end_y))
		else:
			minor_lines.append(Vector2(x, start_y))
			minor_lines.append(Vector2(x, end_y))
			
	for y in range(start_y, end_y + grid_size, grid_size):
		var is_major = (int(y / grid_size) % 3 == 0)
		if is_major:
			major_lines.append(Vector2(start_x, y))
			major_lines.append(Vector2(end_x, y))
		else:
			minor_lines.append(Vector2(start_x, y))
			minor_lines.append(Vector2(end_x, y))
			
	if minor_lines.size() > 0:
		draw_multiline(minor_lines, Color(0.14, 0.26, 0.44, 0.28), 1.0)
	if major_lines.size() > 0:
		draw_multiline(major_lines, Color(0.22, 0.45, 0.75, 0.45), 1.8)

func _draw_ambient_candlesticks(cam_pos: Vector2, view_rect: Rect2):
	var t = Global.game_time
	for candle in bg_candlesticks:
		var c_pos = candle["pos"]
		if view_rect.has_point(c_pos):
			var h = candle["height"] + sin(t * 2.0 + candle["phase"]) * 14.0
			var w = candle["width"]
			var is_bull = candle["is_bull"]
			
			var fill_color = Color(0.0, 0.85, 0.4, 0.16) if is_bull else Color(0.9, 0.2, 0.25, 0.16)
			var border_color = Color(0.2, 1.0, 0.6, 0.45) if is_bull else Color(1.0, 0.35, 0.4, 0.45)
			
			# Wick line
			draw_line(c_pos + Vector2(0, -h * 0.75), c_pos + Vector2(0, h * 0.75), border_color, 2.0)
			# Candle body
			var rect = Rect2(c_pos - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
			draw_rect(rect, fill_color, true)
			draw_rect(rect, border_color, false, 1.8)

func _draw_chart_wave(cam_pos: Vector2):
	if cam_pos.length() < 3500.0:
		for i in range(chart_points.size() - 1):
			var p1 = chart_points[i]
			var p2 = chart_points[i+1]
			var is_up = p2.y < p1.y
			var line_color = Global.get_up_color() if is_up else Global.get_down_color()
			line_color.a = 0.4
			draw_line(p1, p2, line_color, 3.0)

func _draw_world_infrastructure(cam_pos: Vector2, view_rect: Rect2):
	var font = ThemeDB.fallback_font
	var center = MarketDataManager.CENTER_POS
	var t = Global.game_time

	# 1. Draw Grand Radial Expressways (320px wide asphalt with glowing guardrails and lampposts)
	_draw_expressways(cam_pos, view_rect, font, center, t)

	# 2. Outer Orbital Ring Road (Connecting Sectors at ~4800m radius)
	var sec_keys = MarketDataManager.sectors.keys()
	for i in range(sec_keys.size()):
		var p1 = MarketDataManager.sectors[sec_keys[i]]["position"]
		var p2 = MarketDataManager.sectors[sec_keys[(i + 1) % sec_keys.size()]]["position"]
		draw_line(p1, p2, Color(0.3, 0.6, 0.9, 0.35), 4.0)

	# 3. Central 360-Degree Exchange Plaza
	_draw_central_plaza(cam_pos, font, center, t)

	# 4. Sector Biomes, Hubs & Stock Sanctuaries
	_draw_sectors_and_stocks(cam_pos, view_rect, font, t)

func _draw_expressways(cam_pos: Vector2, view_rect: Rect2, font: Font, center: Vector2, t: float):
	var sector_themes = {
		"semiconductor": Color(0.2, 0.85, 1.0),
		"battery": Color(1.0, 0.70, 0.15),
		"bio": Color(0.15, 0.95, 0.55),
		"robot": Color(0.85, 0.35, 1.0)
	}

	for sec_key in MarketDataManager.sectors.keys():
		var sec = MarketDataManager.sectors[sec_key]
		var s_pos = sec["position"]
		var dir = (s_pos - center).normalized()
		var road_len = (s_pos - center).length()
		var normal = Vector2(-dir.y, dir.x)
		var theme_col = sector_themes.get(sec_key, Color(0.3, 0.7, 1.0))
		
		# A. Solid High-Tech Cyber Asphalt Slab (320px wide)
		draw_line(center, s_pos, Color(0.06, 0.11, 0.20, 0.94), 320.0)
		
		# B. Road Shoulders (Dark metallic curbs)
		draw_line(center + normal * 148.0, s_pos + normal * 148.0, Color(0.14, 0.24, 0.40, 0.8), 8.0)
		draw_line(center - normal * 148.0, s_pos - normal * 148.0, Color(0.14, 0.24, 0.40, 0.8), 8.0)
		
		# C. Glowing Cyber Guardrails
		draw_line(center + normal * 160.0, s_pos + normal * 160.0, Color(theme_col.r, theme_col.g, theme_col.b, 0.85), 3.5)
		draw_line(center - normal * 160.0, s_pos - normal * 160.0, Color(theme_col.r, theme_col.g, theme_col.b, 0.85), 3.5)
		
		# D. Center Lane Dashed Divider & Streetlight Pylons
		var step_dist = 220.0
		var cur_d = 200.0
		while cur_d < road_len - 250.0:
			var mid_pt = center + dir * cur_d
			if view_rect.has_point(mid_pt):
				# Dashed yellow/cyan center divider line
				draw_line(mid_pt - dir * 40.0, mid_pt + dir * 40.0, Color(1.0, 0.85, 0.3, 0.7), 4.0)
				
				# Streetlight Pylons on both sides
				var p_l = mid_pt + normal * 175.0
				var p_r = mid_pt - normal * 175.0
				draw_circle(p_l, 6.0, theme_col)
				draw_line(p_l, p_l - normal * 15.0, theme_col, 2.5)
				draw_circle(p_r, 6.0, theme_col)
				draw_line(p_r, p_r + normal * 15.0, theme_col, 2.5)
			cur_d += step_dist

		# E. Flowing High-Speed Cyber Chevrons
		var chevron_spacing = 300.0
		var flow_anim = fmod(t * 350.0, chevron_spacing)
		var c_dist = 260.0 + flow_anim
		while c_dist < road_len - 200.0:
			var arrow_center = center + dir * c_dist
			if view_rect.has_point(arrow_center):
				var arrow_tip = arrow_center + dir * 36.0
				var arrow_left = arrow_center - dir * 14.0 + normal * 36.0
				var arrow_right = arrow_center - dir * 14.0 - normal * 36.0
				draw_line(arrow_left, arrow_tip, Color(theme_col.r, theme_col.g, theme_col.b, 0.85), 4.5)
				draw_line(arrow_right, arrow_tip, Color(theme_col.r, theme_col.g, theme_col.b, 0.85), 4.5)
			c_dist += chevron_spacing

		# F. Highway Overhead Gantry Milestone Signs (every 1000m along expressway)
		var milestone_distances = [1000.0, 2000.0, 3000.0, 4000.0]
		for m_dist in milestone_distances:
			var m_pos = center + dir * m_dist
			if cam_pos.distance_to(m_pos) < 1400.0:
				var remain_km = (road_len - m_dist) / 1000.0
				var gantry_box = Rect2(m_pos - Vector2(260, 50), Vector2(520, 100))
				draw_rect(gantry_box, Color(0.04, 0.08, 0.16, 0.92), true)
				draw_rect(gantry_box, theme_col, false, 3.0)
				
				var sign_txt1 = "🛣️ %s [%s 고속도로]" % [sec.get("direction_hint", ""), sec["name"]]
				var sign_txt2 = "전방: %s 메가 허브 (잔여 %.1fkm)" % [sec["name"], remain_km]
				draw_string(font, m_pos + Vector2(-240, -10), sign_txt1, HORIZONTAL_ALIGNMENT_CENTER, 480, 36, Color(1.0, 0.95, 0.7))
				draw_string(font, m_pos + Vector2(-240, 30), sign_txt2, HORIZONTAL_ALIGNMENT_CENTER, 480, 28, Color(0.85, 0.95, 1.0))

		# Sub-Feeder Roads to Individual Stock Sanctuaries
		if sec.has("stocks"):
			for stock in sec["stocks"]:
				var st_pos = stock.get("world_pos", s_pos)
				if cam_pos.distance_to(st_pos) < 2200.0 or cam_pos.distance_to(s_pos) < 2200.0:
					draw_line(s_pos, st_pos, Color(0.08, 0.15, 0.28, 0.8), 120.0)
					draw_line(s_pos, st_pos, Color(theme_col.r, theme_col.g, theme_col.b, 0.4), 2.5)

func _draw_central_plaza(cam_pos: Vector2, font: Font, center: Vector2, t: float):
	if cam_pos.distance_to(center) > 2200.0:
		return
		
	# Grand Circular Base Floor
	draw_circle(center, 1200.0, Color(0.05, 0.09, 0.17, 0.65))
	
	# Concentric Neon Radar Rings
	draw_arc(center, 1200.0, 0, TAU, 72, Color(0.4, 0.8, 1.0, 0.6), 3.0)
	draw_arc(center, 800.0, 0, TAU, 56, Color(0.4, 0.8, 1.0, 0.35), 2.0)
	draw_arc(center, 400.0, 0, TAU, 40, Color(1.0, 0.85, 0.3, 0.5), 2.5)
	
	# 8-Way Radial Compass Axes
	draw_line(center - Vector2(1200, 0), center + Vector2(1200, 0), Color(0.4, 0.7, 1.0, 0.35), 2.0)
	draw_line(center - Vector2(0, 1200), center + Vector2(0, 1200), Color(0.4, 0.7, 1.0, 0.35), 2.0)
	var diag_v = Vector2(850, 850)
	draw_line(center - diag_v, center + diag_v, Color(0.4, 0.7, 1.0, 0.22), 1.5)
	draw_line(center - Vector2(-850, 850), center + Vector2(-850, 850), Color(0.4, 0.7, 1.0, 0.22), 1.5)
	
	# Central Monument Hologram Pillar
	var center_box = Rect2(center - Vector2(400, 130), Vector2(800, 260))
	draw_rect(center_box, Color(0.03, 0.07, 0.14, 0.94), true)
	draw_rect(center_box, Color(0.4, 0.85, 1.0, 0.9), false, 3.5)
	
	draw_string(font, center + Vector2(-380, -82), "🏛️ [중앙 증시 대교차로 (EXCHANGE PLAZA)]", HORIZONTAL_ALIGNMENT_CENTER, 760, 36, Color(1.0, 0.95, 0.6))
	draw_string(font, center + Vector2(-380, -46), "8방위 고속도로를 선택하여 원하는 섹터로 진입하세요!", HORIZONTAL_ALIGNMENT_CENTER, 760, 26, Color(0.85, 0.92, 1.0, 0.9))
	
	if MarketDataManager.current_market_type == MarketDataManager.MarketType.KOREA:
		draw_string(font, center + Vector2(-380, -12), "⬆️[북] 반도체밸리  |  ↗️[북동] 전력망·원전  |  ➡️[동] 로봇&AI", HORIZONTAL_ALIGNMENT_CENTER, 760, 25, Color(0.8, 0.95, 1.0))
		draw_string(font, center + Vector2(-380, 20), "↘️[남동] 조선·해운  |  ⬇️[남] 2차전지  |  ↙️[남서] 금융·밸류업", HORIZONTAL_ALIGNMENT_CENTER, 760, 25, Color(0.8, 0.95, 1.0))
		draw_string(font, center + Vector2(-380, 52), "⬅️[서] 바이오랩  |  ↖️[북서] K-방산·우주항공", HORIZONTAL_ALIGNMENT_CENTER, 760, 25, Color(0.8, 0.95, 1.0))
		draw_string(font, center + Vector2(-380, 84), "⚠️ 빨간색(상승) 제단 레벨업!  파란색(하락) 공매도 위험!", HORIZONTAL_ALIGNMENT_CENTER, 760, 23, Color(1.0, 0.85, 0.4))
	else:
		draw_string(font, center + Vector2(-380, -12), "⬆️[북] AI반도체  |  ↗️[북동] 전력망·SMR  |  ➡️[동] 빅테크 M7", HORIZONTAL_ALIGNMENT_CENTER, 760, 25, Color(0.8, 0.95, 1.0))
		draw_string(font, center + Vector2(-380, 20), "↘️[남동] 국방AI·방산  |  ⬇️[남] EV캐즘  |  ↙️[남서] 월가 메가뱅크", HORIZONTAL_ALIGNMENT_CENTER, 760, 25, Color(0.8, 0.95, 1.0))
		draw_string(font, center + Vector2(-380, 52), "⬅️[서] 글로벌헬스케어  |  ↖️[북서] 리테일·소비재", HORIZONTAL_ALIGNMENT_CENTER, 760, 25, Color(0.8, 0.95, 1.0))
		draw_string(font, center + Vector2(-380, 84), "⚠️ 빨간색(상승) 제단 레벨업!  파란색(하락) 공매도 위험!", HORIZONTAL_ALIGNMENT_CENTER, 760, 23, Color(1.0, 0.85, 0.4))

func _draw_sectors_and_stocks(cam_pos: Vector2, view_rect: Rect2, font: Font, t: float):
	for sec_key in MarketDataManager.sectors.keys():
		var sec = MarketDataManager.sectors[sec_key]
		var s_pos = sec["position"]
		var s_rad = sec["radius"]
		var dist_to_sec = cam_pos.distance_to(s_pos)
		var is_up = sec["change_rate"] >= 0.0
		var theme_color = Global.get_up_color() if is_up else Global.get_down_color()
		
		# Sector Ambient Floor & Perimeter
		if dist_to_sec < s_rad + 1500.0:
			# Soft radiant sector floor glow
			draw_circle(s_pos, s_rad, Color(theme_color.r, theme_color.g, theme_color.b, 0.08))
			draw_arc(s_pos, s_rad, 0, TAU, 64, Color(theme_color.r, theme_color.g, theme_color.b, 0.6), 3.0)
			draw_arc(s_pos, s_rad * 0.5, 0, TAU, 48, Color(theme_color.r, theme_color.g, theme_color.b, 0.25), 2.0)
			
			# Core Cyber Beacon
			draw_arc(s_pos, 120.0, 0, TAU, 32, theme_color, 4.0)
			draw_arc(s_pos, 150.0 + sin(t * 3.0) * 14.0, 0, TAU, 32, Color(theme_color.r, theme_color.g, theme_color.b, 0.45), 2.5)
			
			# Sector Hub Signboard with Live News Broadcast
			var sec_box = Rect2(s_pos - Vector2(340, 125), Vector2(680, 250))
			draw_rect(sec_box, Color(0.03, 0.06, 0.13, 0.94), true)
			draw_rect(sec_box, Color(theme_color.r, theme_color.g, theme_color.b, 0.9), false, 3.5)
			
			var rate_sign = "▲ +" if is_up else "▼ "
			var rate_str = "%s [%s %s%.1f%%]" % [sec.get("direction_hint", ""), sec["name"], rate_sign, abs(sec["change_rate"])]
			var title_col = Color(1.0, 0.95, 0.3) if sec.get("is_top_bull", false) else theme_color
			draw_string(font, s_pos + Vector2(-320, -78), rate_str, HORIZONTAL_ALIGNMENT_CENTER, 640, 44, title_col)
			draw_string(font, s_pos + Vector2(-320, -32), sec["sub_title"], HORIZONTAL_ALIGNMENT_CENTER, 640, 30, Color(0.85, 0.92, 0.98))
			
			# Sector Live News Banner Box
			var sec_news_box = Rect2(s_pos - Vector2(320, 10), Vector2(640, 52))
			draw_rect(sec_news_box, Color(0.01, 0.04, 0.09, 0.9), true)
			draw_rect(sec_news_box, Color(theme_color.r, theme_color.g, theme_color.b, 0.6), false, 1.5)
			
			var sec_headline = MarketDataManager.get_news_for_sector(sec_key)
			var blink_tag = "🔴 [섹터 속보] " if (int(t * 2.5) % 2 == 0) else "⭕ [섹터 속보] "
			draw_string(font, s_pos + Vector2(-305, 46), blink_tag + sec_headline, HORIZONTAL_ALIGNMENT_LEFT, 610, 24, Color(1.0, 0.92, 0.65))
			
			draw_string(font, s_pos + Vector2(-320, 98), "외곽 도로를 따라 개별 종목 성역으로 진입하세요 ➔", HORIZONTAL_ALIGNMENT_CENTER, 640, 26, Color(0.4, 0.88, 1.0, 0.95))

		# Individual Stock Cyber Sanctuaries (Culled by distance)
		if sec.has("stocks"):
			for stock in sec["stocks"]:
				var st_pos = stock.get("world_pos", s_pos)
				if cam_pos.distance_to(st_pos) > 1350.0:
					continue
					
				var st_up = stock["rate"] >= 0.0
				var st_col = Global.get_up_color() if st_up else Global.get_down_color()
				var is_super_bull = stock["rate"] >= 10.0
				var is_deep_bear = stock["rate"] <= -6.0
				
				var is_halted = stock.get("is_halted", false)
				var cd_left = stock.get("cooldown_timer", 0.0)
				
				# Ambient sanctuary floor glow
				var glow_col = Color(1.0, 0.75, 0.2) if is_halted else st_col
				draw_circle(st_pos, 420.0, Color(glow_col.r, glow_col.g, glow_col.b, 0.07))
				draw_arc(st_pos, 420.0, 0, TAU, 48, Color(glow_col.r, glow_col.g, glow_col.b, 0.45), 2.5)
				
				# Central Cyber Altar Diamond or VI Caution Barrier
				if is_halted:
					# Pulsing Caution VI Barrier
					var caution_pulse = sin(t * 8.0) * 8.0
					draw_circle(st_pos, 54.0, Color(1.0, 0.4, 0.1, 0.28))
					draw_arc(st_pos, 72.0 + caution_pulse, 0, TAU, 32, Color(1.0, 0.8, 0.2, 0.95), 3.5)
					draw_arc(st_pos, 52.0, 0, TAU, 24, Color(1.0, 0.3, 0.2, 0.8), 2.5)
					draw_string(font, st_pos + Vector2(-60, 6), "🚨 VI 발동", HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color(1.0, 0.9, 0.3))
					draw_string(font, st_pos + Vector2(-70, 26), "거래정지 (%ds)" % int(ceil(cd_left)), HORIZONTAL_ALIGNMENT_CENTER, 140, 15, Color(1.0, 1.0, 1.0))
				else:
					var diamond_size = 46.0
					var rot_angle = t * 1.5
					var d_pts = PackedVector2Array([
						st_pos + Vector2(0, -diamond_size).rotated(rot_angle),
						st_pos + Vector2(diamond_size, 0).rotated(rot_angle),
						st_pos + Vector2(0, diamond_size).rotated(rot_angle),
						st_pos + Vector2(-diamond_size, 0).rotated(rot_angle)
					])
					draw_colored_polygon(d_pts, Color(st_col.r, st_col.g, st_col.b, 0.85))
					draw_polyline(PackedVector2Array([d_pts[0], d_pts[1], d_pts[2], d_pts[3], d_pts[0]]), Color(1, 1, 1, 0.95), 3.0)
					
					# Pulsing outer ring around altar
					var pulse_rad = 68.0 + sin(t * 4.0) * 10.0
					draw_arc(st_pos, pulse_rad, 0, TAU, 24, Color(st_col.r, st_col.g, st_col.b, 0.7), 2.5)
				
				# High-Tech Stock Hologram Board with Stock-Specific News (Enlarged width & height for maximum visibility)
				var board_box = Rect2(st_pos - Vector2(400, 172), Vector2(800, 126))
				draw_rect(board_box, Color(0.03, 0.06, 0.14, 0.95), true)
				draw_rect(board_box, Color(glow_col.r, glow_col.g, glow_col.b, 0.9), false, 3.0)
				
				# Left Side: Stock Name & VI Status Badge (Enlarged font & width)
				var badge_icon = "👑 " if is_super_bull else ("⚠️ " if is_deep_bear else "")
				var left_badge = "%s%s" % [badge_icon, stock["name"]]
				var left_col = Color(1.0, 0.9, 0.2) if is_super_bull else (Color(0.4, 0.8, 1.0) if is_deep_bear else Color(1, 1, 1))
				if is_halted:
					left_badge = "🚨 [VI %ds] %s" % [int(ceil(cd_left)), stock["name"]]
					left_col = Color(1.0, 0.8, 0.2)
				
				# Top Left: Stock Name & Status
				draw_string(font, st_pos + Vector2(-375, -128), left_badge, HORIZONTAL_ALIGNMENT_LEFT, 400, 34, left_col)
				
				# Right Side: Current Price + Fluctuation Rate (%)
				var st_sign = "▲ +" if st_up else "▼ "
				var rate_str = "%s%.1f%%" % [st_sign, abs(stock["rate"])]
				
				var price_str = MarketDataManager.get_stock_price(stock)
				var unit = "" if (price_str.begins_with("$") or price_str.ends_with("원")) else "원"
				var right_text = "%s%s  %s" % [price_str, unit, rate_str]
				
				# Top Right: Price & Fluctuation Rate (Always visible even during VI)
				draw_string(font, st_pos + Vector2(15, -128), right_text, HORIZONTAL_ALIGNMENT_RIGHT, 360, 30, st_col)
				
				# Divider line between stock rate and news headline
				draw_line(st_pos + Vector2(-385, -112), st_pos + Vector2(385, -112), Color(st_col.r, st_col.g, st_col.b, 0.45), 1.8)
				
				# Bottom: News Background Pill for enhanced contrast & legibility
				var news_pill_box = Rect2(st_pos - Vector2(385, 105), Vector2(770, 50))
				draw_rect(news_pill_box, Color(0.015, 0.035, 0.08, 0.75), true)
				draw_rect(news_pill_box, Color(glow_col.r, glow_col.g, glow_col.b, 0.3), false, 1.2)
				
				# Bottom: Specific Live Stock News Headline (Rotates every 4s, widened to 740px & enlarged to 26pt font)
				var st_news = MarketDataManager.get_news_for_stock(stock["name"])
				var news_display = "📰 [속보] " + st_news
				draw_string(font, st_pos + Vector2(-370, -70), news_display, HORIZONTAL_ALIGNMENT_LEFT, 740, 26, Color(0.9, 0.96, 1.0))

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
	
	var effective_rate = cur_sec.get("change_rate", 0.0)
	if not near_stock.is_empty():
		effective_rate = near_stock.get("rate", effective_rate)
		
	if effective_rate >= 3.0:
		Global.in_bull_zone = true
		Global.in_bear_hazard = false
		Global.player_speed_modifier = 1.20
		Global.exp_multiplier = 1.6
		
		if effective_rate >= 10.0 and randf() < 0.40:
			var gem = gem_scene.instantiate()
			gem.exp_value = 16
			var angle = randf() * TAU
			gem.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(60, 200)
			call_deferred("add_child", gem)
			
	elif effective_rate <= -2.5:
		Global.in_bear_hazard = true
		Global.in_bull_zone = false
		Global.player_speed_modifier = 0.80
		Global.exp_multiplier = 0.6
		
		Global.take_player_damage(1.5 * 0.2 * 2.5)
		Global.portfolio_return = max(0.0, Global.portfolio_return - 4.0 * 0.2)
		
		if effective_rate <= -6.0:
			Global.portfolio_return = max(0.0, Global.portfolio_return - 6.0 * 0.2)
			
	else:
		Global.in_bull_zone = false
		Global.in_bear_hazard = false
		Global.player_speed_modifier = 1.0
		if Global.current_market_event == "":
			Global.exp_multiplier = 1.0

func _process_market_events(delta):
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
			Global.current_market_event = "CIRCUIT_BREAKER"
			Global.enemy_speed_multiplier = 0.0
			Global.event_remaining_time = 5.0
			SoundManager.play_boss_alert()
			Global.market_event_triggered.emit("🚨 [서킷 브레이커 발동]", "5초간 모든 거래 정지! 프리 딜 찬스!")
		1:
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
	# Fast spawn cycle: starts at 0.7s and accelerates down to 0.20s
	spawn_interval = max(0.20, 0.70 - (Global.game_time / 180.0) * 0.50)
	
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy_wave()
		
	# 1. 60초 (1분): 1차 중간 보스 [공매도 수장 BEAR BOSS]
	if Global.game_time >= 60.0 and not bear_boss_spawned:
		bear_boss_spawned = true
		_spawn_boss(Enemy.EnemyType.BEAR_BOSS)
		SoundManager.play_boss_alert()
		Global.market_event_triggered.emit("🚨 [비상 경보] 공매도 수장 BEAR BOSS 출현!", "거대한 공매도 세력이 플레이어를 향해 진격합니다!")
		
	# 2. 120초 (2분): 2차 중간 보스 [초대형 하한가 캔들 군단]
	if Global.game_time >= 120.0 and not candle_boss_spawned:
		candle_boss_spawned = true
		if is_instance_valid(player):
			for i in range(4):
				var angle = i * (TAU / 4.0)
				var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 620.0
				var candle_e = enemy_scene.instantiate()
				candle_e.type = Enemy.EnemyType.RED_CANDLE
				candle_e.polarity = Enemy.Polarity.BEAR
				candle_e.global_position = spawn_pos
				enemy_container.add_child(candle_e)
		SoundManager.play_boss_alert()
		Global.market_event_triggered.emit("📉 [어닝 쇼크] 거대 하한가 캔들 군단 출현!", "거대한 음봉 캔들들이 화면을 뒤덮습니다!")
		
	# 3. 180초 (3분): 최종 결전 [관세맨 TRUMP]
	if Global.game_time >= 180.0 and not trump_boss_spawned:
		trump_boss_spawned = true
		_spawn_boss(Enemy.EnemyType.TRUMP_BOSS)
		SoundManager.play_boss_alert()
		Global.market_event_triggered.emit("🏛️ [최종 결전] 관세맨 TRUMP 등장!", "🚨 전방위 관세 폭탄 100% 발령! 글로벌 증시를 구원하세요!")

func _spawn_enemy_wave():
	# Cap enemy count to protect mobile 60fps performance
	if enemy_container.get_child_count() >= 130:
		return

	if not is_instance_valid(player):
		return

	var t = Global.game_time
	# Wave count: 3~5 early game, scaling up to 7~11 enemies per wave late game
	var wave_count = int(clampf(3 + int(t / 25.0) * 1.5, 3, 11))
	if not Global.current_market_event.is_empty():
		wave_count += 3

	var p_pos = player.global_position
	var nearby_stocks = MarketDataManager.get_stocks_near(p_pos, 2200.0)

	# 1. Nearby Stock Sanctuary Spawning:
	# If player is near a stock, enemies stream directly from that stock!
	if nearby_stocks.size() > 0:
		var closest_stock = nearby_stocks[0]
		var min_d = p_pos.distance_to(closest_stock.get("world_pos", Vector2.ZERO))
		for st in nearby_stocks:
			var d = p_pos.distance_to(st.get("world_pos", Vector2.ZERO))
			if d < min_d:
				min_d = d
				closest_stock = st
				
		var st_pos = closest_stock.get("world_pos", p_pos)
		var is_bull = closest_stock.get("rate", 0.0) >= 0.0
		var is_halted = closest_stock.get("is_halted", false)
		
		# If the stock is in VI Cooldown (거래 정지):
		if is_halted:
			# Do NOT spawn free red profits! Spawn blue profit-taking selling pressure
			for i in range(mini(wave_count, 4)):
				var type_to_spawn = _pick_enemy_type(t)
				var enemy = enemy_scene.instantiate()
				enemy.type = type_to_spawn
				enemy.polarity = Enemy.Polarity.BEAR # Profit taking selling pressure!
				var spawn_pos = p_pos + Vector2(cos(randf() * TAU), sin(randf() * TAU)) * randf_range(520.0, 700.0)
				enemy.global_position = spawn_pos
				enemy_container.add_child(enemy)
		else:
			# Active Stock: Record spawns towards VI Quota (28 max)
			MarketDataManager.record_stock_spawn(closest_stock["name"], wave_count)
			
			# Stream enemies directly from or towards the stock altar
			for i in range(wave_count):
				var type_to_spawn = _pick_enemy_type(t)
				var enemy = enemy_scene.instantiate()
				enemy.type = type_to_spawn
				enemy.polarity = Enemy.Polarity.BULL if is_bull else Enemy.Polarity.BEAR
				
				var spawn_pos: Vector2
				if min_d <= 750.0:
					# Right at the stock altar: erupts directly from the altar!
					spawn_pos = st_pos + Vector2(randf_range(-90, 90), randf_range(-90, 90))
				else:
					# Marching from the stock towards player: stream along the highway line
					var dir_to_player = (p_pos - st_pos).normalized()
					var march_point = p_pos - dir_to_player * randf_range(520.0, 720.0)
					spawn_pos = march_point + Vector2(randf_range(-120, 120), randf_range(-120, 120))
					
				enemy.global_position = spawn_pos
				enemy_container.add_child(enemy)
	else:
		# 2. Open Highway / Central Plaza Spawning:
		# Spawn right around the visible camera perimeter (500~720px) so they engage immediately!
		var base_angle = randf() * TAU
		for i in range(wave_count):
			var type_to_spawn = _pick_enemy_type(t)
			var cluster_spread = randf_range(-0.4, 0.4)
			var angle = base_angle + cluster_spread + (float(i) / wave_count) * 0.75
			var spawn_dist = randf_range(500.0, 720.0)
			var spawn_pos = p_pos + Vector2(cos(angle), sin(angle)) * spawn_dist
			
			var enemy = enemy_scene.instantiate()
			enemy.type = type_to_spawn
			
			var cur_sec = MarketDataManager.get_sector_at(p_pos)
			var rate = cur_sec.get("change_rate", 0.0)
			var bull_chance = clampf(0.50 + rate * 0.08, 0.15, 0.85)
			enemy.polarity = Enemy.Polarity.BULL if randf() < bull_chance else Enemy.Polarity.BEAR
			enemy.global_position = spawn_pos
			enemy_container.add_child(enemy)

func _pick_enemy_type(t: float) -> Enemy.EnemyType:
	var rand_val = randf()
	if t < 45.0:
		return Enemy.EnemyType.PANIC_SELL
	elif t < 100.0:
		return Enemy.EnemyType.FAKE_NEWS if rand_val > 0.6 else Enemy.EnemyType.PANIC_SELL
	else:
		if rand_val < 0.45:
			return Enemy.EnemyType.PANIC_SELL
		elif rand_val < 0.75:
			return Enemy.EnemyType.FAKE_NEWS
		else:
			return Enemy.EnemyType.RED_CANDLE

func _spawn_boss(b_type):
	if not is_instance_valid(player):
		return
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 700.0
	
	var boss = enemy_scene.instantiate()
	boss.type = b_type
	boss.global_position = spawn_pos
	enemy_container.add_child(boss)
