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
var endless_raid_cycle: int = 0
var next_raid_time: float = 180.0
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
	
	# 12-Hour Clock Radial Spokes and Markers
	for h in range(12):
		var rad = deg_to_rad(h * 30.0)
		var dir_v = Vector2(sin(rad), -cos(rad))
		var is_cardinal = (h % 3 == 0)
		var spoke_col = Color(0.4, 0.75, 1.0, 0.38) if is_cardinal else Color(0.4, 0.7, 1.0, 0.18)
		var spoke_w = 2.5 if is_cardinal else 1.5
		draw_line(center, center + dir_v * 1200.0, spoke_col, spoke_w)
		
		# Dial hour text at edge of plaza
		var tick_pos = center + dir_v * 1140.0
		var h_num = 12 if h == 0 else h
		draw_string(font, tick_pos - Vector2(30, -8), "%d시" % h_num, HORIZONTAL_ALIGNMENT_CENTER, 60, 20, Color(0.9, 0.95, 1.0, 0.85))
	
	# Central Monument Hologram Pillar
	var center_box = Rect2(center - Vector2(440, 150), Vector2(880, 300))
	draw_rect(center_box, Color(0.03, 0.07, 0.14, 0.94), true)
	draw_rect(center_box, Color(0.4, 0.85, 1.0, 0.9), false, 3.5)
	
	draw_string(font, center + Vector2(-420, -104), "🏛️ [중앙 증시 대교차로 (EXCHANGE PLAZA)]", HORIZONTAL_ALIGNMENT_CENTER, 840, 36, Color(1.0, 0.95, 0.6))
	draw_string(font, center + Vector2(-420, -68), "12시계 다이얼 고속도로를 선택하여 원하는 섹터로 진입하세요!", HORIZONTAL_ALIGNMENT_CENTER, 840, 24, Color(0.85, 0.92, 1.0, 0.9))
	
	if MarketDataManager.current_market_type == MarketDataManager.MarketType.KOREA:
		draw_string(font, center + Vector2(-420, -32), "🕛12시: 반도체밸리  |  🕐1시: 전력망·원전  |  🕑2시: 미래차·모빌리티  |  🕒3시: 로봇·AI", HORIZONTAL_ALIGNMENT_CENTER, 840, 22, Color(0.85, 0.95, 1.0))
		draw_string(font, center + Vector2(-420, -4), "🕓4시: 게임·플랫폼  |  🕔5시: K-엔터  |  🕕6시: 2차전지  |  🕖7시: K-푸드·소비재", HORIZONTAL_ALIGNMENT_CENTER, 840, 22, Color(0.85, 0.95, 1.0))
		draw_string(font, center + Vector2(-420, 24), "🕗8시: 금융·밸류업  |  🕘9시: 바이오랩  |  🕙10시: 조선·해운  |  🕚11시: K-방산·우주", HORIZONTAL_ALIGNMENT_CENTER, 840, 22, Color(0.85, 0.95, 1.0))
		draw_string(font, center + Vector2(-420, 56), "⚠️ 빨간색(상승) 제단 레벨업!  파란색(하락) 공매도 위험!", HORIZONTAL_ALIGNMENT_CENTER, 840, 21, Color(1.0, 0.85, 0.4))
	else:
		draw_string(font, center + Vector2(-420, -32), "🕛12시: AI반도체  |  🕐1시: 전력·SMR  |  🕑2시: 국방AI·방산  |  🕒3시: 빅테크 M7", HORIZONTAL_ALIGNMENT_CENTER, 840, 22, Color(0.85, 0.95, 1.0))
		draw_string(font, center + Vector2(-420, -4), "🕓4시: 사이버SaaS  |  🕔5시: 미디어  |  🕕6시: EV·청정에너지  |  🕖7시: 전통에너지", HORIZONTAL_ALIGNMENT_CENTER, 840, 22, Color(0.85, 0.95, 1.0))
		draw_string(font, center + Vector2(-420, 24), "🕗8시: 월가메가뱅크  |  🕘9시: 글로벌헬스  |  🕙10시: 리테일·소비  |  🕚11시: 산업재·인프라", HORIZONTAL_ALIGNMENT_CENTER, 840, 22, Color(0.85, 0.95, 1.0))
		draw_string(font, center + Vector2(-420, 56), "⚠️ 초록색(상승) 제단 레벨업!  빨간색(하락) 공매도 위험!", HORIZONTAL_ALIGNMENT_CENTER, 840, 21, Color(1.0, 0.85, 0.4))

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
		Global.player_speed_modifier = 0.90
		Global.exp_multiplier = 0.8
		
		Global.portfolio_return = max(0.0, Global.portfolio_return - 0.02 * 0.2)
		
		if effective_rate <= -6.0:
			Global.portfolio_return = max(0.0, Global.portfolio_return - 0.04 * 0.2)
			
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
	# 스폰 속도 2배 가속: 1.0초 ~ 1.6초 간격 (적당한 전투 긴장감과 사냥 재미 유지)
	spawn_interval = max(1.0, 1.6 - (Global.game_time / 300.0) * 0.4)
	
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
			for i in range(2):
				var angle = i * (TAU / 2.0)
				var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 620.0
				var candle_e = enemy_scene.instantiate()
				candle_e.type = Enemy.EnemyType.RED_CANDLE
				candle_e.polarity = Enemy.Polarity.BEAR
				candle_e.stock_name = "하한가 음봉"
				candle_e.global_position = spawn_pos
				enemy_container.add_child(candle_e)
		SoundManager.play_boss_alert()
		Global.market_event_triggered.emit("📉 [어닝 쇼크] 거대 하한가 캔들 출현!", "하한가 음봉 캔들이 등장했습니다!")
		
	# 3. 180초 (3분): 주요 보스 결전 [관세맨 TRUMP]
	if Global.game_time >= 180.0 and not trump_boss_spawned:
		trump_boss_spawned = true
		next_raid_time = Global.game_time + 120.0
		_spawn_boss(Enemy.EnemyType.TRUMP_BOSS)
		SoundManager.play_boss_alert()
		Global.market_event_triggered.emit("🏛️ [주요 보스] 관세맨 TRUMP 등장!", "🚨 전방위 관세 폭탄 발령! 글로벌 증시 방어선을 사수하세요!")

	# 4. 방치형 무한 주기 레이드 보스 순환 (Endless Periodic Raid Cycles)
	if trump_boss_spawned and Global.game_time >= next_raid_time:
		endless_raid_cycle += 1
		next_raid_time = Global.game_time + randf_range(110.0, 140.0) # 약 2분마다 정기 레이드 지속
		_spawn_endless_raid_wave(endless_raid_cycle)

func _spawn_endless_raid_wave(cycle: int):
	SoundManager.play_boss_alert()
	match (cycle % 3):
		1:
			_spawn_boss(Enemy.EnemyType.BEAR_BOSS)
			Global.market_event_triggered.emit("🚨 [무한 레이드 %d차] 각성한 공매도 수장 출현!" % cycle, "강화된 공매도 군단이 시장을 흔들기 위해 진격합니다!")
		2:
			if is_instance_valid(player):
				for i in range(3):
					var angle = i * (TAU / 3.0)
					var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 650.0
					var candle_e = enemy_scene.instantiate()
					candle_e.type = Enemy.EnemyType.RED_CANDLE
					candle_e.polarity = Enemy.Polarity.BEAR
					candle_e.stock_name = "심연의 하한가 음봉"
					candle_e.global_position = spawn_pos
					enemy_container.add_child(candle_e)
			Global.market_event_triggered.emit("📉 [무한 레이드 %d차] 트리플 하한가 캔들 습격!" % cycle, "거대한 패닉셀 음봉 3기가 등장했습니다!")
		0:
			_spawn_boss(Enemy.EnemyType.TRUMP_BOSS)
			Global.market_event_triggered.emit("🏛️ [무한 레이드 %d차] 초인플레이션 관세 타이탄 강림!" % cycle, "글로벌 무역 분쟁 2차 파동! 증시 방어선을 지키세요!")

func _get_archetype_for_sector(sec_key: String) -> Enemy.CharacterArchetype:
	match sec_key:
		"semiconductor", "ai_chips":
			return Enemy.CharacterArchetype.CHIP_GOLEM
		"battery", "ev_auto", "automotive":
			return Enemy.CharacterArchetype.BATTERY_MECHA
		"bio", "pharma":
			return Enemy.CharacterArchetype.BIO_CHIMERA
		"robot_ai", "big_tech", "gaming_platform", "cyber_saas":
			return Enemy.CharacterArchetype.AI_ANDROID
		"power_grid", "ai_power", "traditional_energy":
			return Enemy.CharacterArchetype.REACTOR_TITAN
		"shipbuilding", "industrial_infra":
			return Enemy.CharacterArchetype.DREADNOUGHT
		"finance", "wall_street", "entertainment", "media_entertain", "food_consumer", "retail":
			return Enemy.CharacterArchetype.GOLD_VAULT
		"defense", "defense_tech":
			return Enemy.CharacterArchetype.DEFENSE_MECHA
		_:
			return Enemy.CharacterArchetype.CHIP_GOLEM

func _spawn_enemy_wave():
	# 몬스터 최대 상한 42마리로 확대 (스폰 2배 가속에 맞춤)
	if enemy_container.get_child_count() >= 42:
		return

	if not is_instance_valid(player):
		return

	var t = Global.game_time
	# 2배 가속 웨이브: 웨이브당 2~3마리, 후반부 4마리
	var wave_count = int(clampf(2 + int(t / 45.0) * 0.5, 2, 4))
	if not Global.current_market_event.is_empty():
		wave_count = mini(wave_count + 1, 5)

	var p_pos = player.global_position
	var cur_sec = MarketDataManager.get_sector_at(p_pos)
	var nearby_stocks = MarketDataManager.get_stocks_near(p_pos, 2200.0)

	# 1. Nearby Stock Sanctuary Spawning:
	# 특정 종목 성역 근처일 때는 해당 종목의 캐릭터화된 RPG 엔티티 출현!
	if nearby_stocks.size() > 0:
		var closest_stock = nearby_stocks[0]
		var min_d = p_pos.distance_to(closest_stock.get("world_pos", Vector2.ZERO))
		for st in nearby_stocks:
			var d = p_pos.distance_to(st.get("world_pos", Vector2.ZERO))
			if d < min_d:
				min_d = d
				closest_stock = st
				
		var st_pos = closest_stock.get("world_pos", p_pos)
		var is_halted = closest_stock.get("is_halted", false)
		var sec_key = closest_stock.get("sector_key", cur_sec.get("key", "semiconductor"))
		var arch = _get_archetype_for_sector(sec_key)
		
		# If the stock is in VI Cooldown (거래 정지):
		if is_halted:
			var enemy = enemy_scene.instantiate()
			enemy.archetype = arch
			enemy.polarity = Enemy.Polarity.BEAR
			enemy.stock_name = closest_stock["name"]
			enemy.stock_rate = closest_stock.get("rate", 0.0)
			var spawn_pos = p_pos + Vector2(cos(randf() * TAU), sin(randf() * TAU)) * randf_range(500.0, 660.0)
			enemy.global_position = spawn_pos
			enemy_container.add_child(enemy)
		else:
			var sanctuary_spawns = mini(wave_count, 3)
			MarketDataManager.record_stock_spawn(closest_stock["name"], sanctuary_spawns)
			
			for i in range(sanctuary_spawns):
				var enemy = enemy_scene.instantiate()
				enemy.archetype = arch
				enemy.stock_name = closest_stock["name"]
				enemy.stock_rate = closest_stock.get("rate", 0.0)
				enemy.polarity = Enemy.Polarity.BULL if enemy.stock_rate >= 0.0 else Enemy.Polarity.BEAR
				
				var spawn_pos: Vector2
				if min_d <= 750.0:
					spawn_pos = st_pos + Vector2(randf_range(-60, 60), randf_range(-60, 60))
				else:
					var dir_to_player = (p_pos - st_pos).normalized()
					var march_point = p_pos - dir_to_player * randf_range(480.0, 640.0)
					spawn_pos = march_point + Vector2(randf_range(-80, 80), randf_range(-80, 80))
					
				enemy.global_position = spawn_pos
				enemy_container.add_child(enemy)
	else:
		# 2. Open Highway / Central Plaza Spawning:
		# 섹터 정보를 바탕으로 해당 섹터의 대표 종목 RPG 캐릭터 자동 매칭
		var sec_key = cur_sec.get("key", "semiconductor")
		var arch = _get_archetype_for_sector(sec_key)
		var sec_stocks = cur_sec.get("stocks", [])
		
		for i in range(wave_count):
			var enemy = enemy_scene.instantiate()
			var picked_stock = sec_stocks.pick_random() if not sec_stocks.is_empty() else null
			
			if picked_stock:
				enemy.archetype = arch
				enemy.stock_name = picked_stock["name"]
				enemy.stock_rate = picked_stock.get("rate", 0.0)
				enemy.polarity = Enemy.Polarity.BULL if enemy.stock_rate >= 0.0 else Enemy.Polarity.BEAR
			else:
				enemy.type = _pick_enemy_type(t)
				enemy.stock_name = cur_sec.get("name", "지수 캔들")
				enemy.stock_rate = cur_sec.get("change_rate", 0.0)
				enemy.polarity = Enemy.Polarity.BULL if enemy.stock_rate >= 0.0 else Enemy.Polarity.BEAR
				
			var angle = randf() * TAU
			var spawn_dist = randf_range(500.0, 680.0)
			enemy.global_position = p_pos + Vector2(cos(angle), sin(angle)) * spawn_dist
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
