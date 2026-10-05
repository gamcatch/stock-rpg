extends Control

# High-Tech Cyber Radar Minimap & Off-Screen Waypoint Navigation
var radar_radius: float = 80.0
var world_max_radius: float = MarketDataManager.WORLD_RADIUS
var target_player: Node2D = null

func _ready():
	custom_minimum_size = Vector2(200, 200)

func _process(_delta):
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
	queue_redraw()

func _draw():
	var center = size * 0.5
	var font = ThemeDB.fallback_font
	var t = Global.game_time
	var up_col = Global.get_up_color()
	var down_col = Global.get_down_color()
	
	# 1. Radar Glass Background
	draw_circle(center, radar_radius, Color(0.03, 0.07, 0.13, 0.88))
	draw_arc(center, radar_radius, 0, TAU, 48, Color(0.35, 0.7, 1.0, 0.65), 2.0)
	draw_arc(center, radar_radius * 0.65, 0, TAU, 36, Color(0.35, 0.7, 1.0, 0.22), 1.0)
	draw_arc(center, radar_radius * 0.35, 0, TAU, 24, Color(0.35, 0.7, 1.0, 0.22), 1.0)
	
	# Radar Crosshair Axes
	draw_line(center - Vector2(radar_radius, 0), center + Vector2(radar_radius, 0), Color(0.35, 0.7, 1.0, 0.22), 1.0)
	draw_line(center - Vector2(0, radar_radius), center + Vector2(0, radar_radius), Color(0.35, 0.7, 1.0, 0.22), 1.0)
	
	# Rotating Radar Scan Beam Line
	var scan_angle = fmod(t * 2.2, TAU)
	var scan_vec = Vector2(cos(scan_angle), sin(scan_angle)) * radar_radius
	draw_line(center, center + scan_vec, Color(0.4, 0.9, 1.0, 0.35), 1.5)
	
	var scale_factor = radar_radius / world_max_radius
	
	# 2. Central Exchange Plaza Dot (0, 0)
	var plaza_pos = center + MarketDataManager.CENTER_POS * scale_factor
	draw_circle(plaza_pos, 4.0, Color(1.0, 0.9, 0.4, 0.95))
	draw_arc(plaza_pos, 5.5, 0, TAU, 16, Color(1.0, 0.8, 0.2, 0.7), 1.0)
	
	# 3. Sectors & Stocks on Radar (🔴 상승 / 🔵 하락 실시간 색상 표시)
	for sec_key in MarketDataManager.sectors.keys():
		var sec = MarketDataManager.sectors[sec_key]
		var s_world = sec.get("position", Vector2.ZERO)
		var s_radar = center + s_world * scale_factor
		
		var rate = sec.get("change_rate", 0.0)
		var is_up = rate >= 0.0
		var sec_col = up_col if is_up else down_col
		
		# Check if player is currently inside this sector
		var is_inside = false
		if is_instance_valid(target_player):
			is_inside = target_player.global_position.distance_to(s_world) <= sec.get("radius", 1000.0)
		
		# Sector Outer Aura Glow (상승은 붉은빛 글로우, 하락은 푸른빛 글로우)
		var aura_alpha = 0.35 + (sin(t * 4.0) * 0.15 if is_up else 0.0)
		draw_circle(s_radar, 11.0, Color(sec_col.r, sec_col.g, sec_col.b, aura_alpha))
		
		# Sector Main Hub Dot
		draw_circle(s_radar, 6.5, sec_col)
		
		# Current Sector Highlight Ring
		if is_inside:
			var ring_pulse = 8.5 + sin(t * 6.0) * 2.0
			draw_arc(s_radar, ring_pulse, 0, TAU, 20, Color(1.0, 0.95, 0.4, 0.95), 2.0)
		else:
			draw_arc(s_radar, 8.0, 0, TAU, 16, Color(1, 1, 1, 0.75), 1.2)
		
		# Initial Character Tag inside Sector Hub Dot
		var tag = sec["name"].substr(0, 1)
		draw_string(font, s_radar + Vector2(-6, 4), tag, HORIZONTAL_ALIGNMENT_CENTER, 12, 13, Color(1, 1, 1, 0.98))
		
		# Small Up/Down Indicator Arrow above Sector Hub
		var arrow_char = "▲" if is_up else "▼"
		var arrow_pos = s_radar + Vector2(-6, -10)
		draw_string(font, arrow_pos, arrow_char, HORIZONTAL_ALIGNMENT_CENTER, 12, 11, sec_col)
		
		# Stock dots (각 종목별 상승/하락 개별 닷)
		if sec.has("stocks"):
			for st in sec["stocks"]:
				var st_world = st.get("world_pos", s_world)
				var st_radar = center + st_world * scale_factor
				var st_rate = st.get("rate", 0.0)
				var st_is_up = st_rate >= 0.0
				var st_col = up_col if st_is_up else down_col
				
				# 상승 빨간색 / 하락 파란색 개별 종목 닷
				draw_circle(st_radar, 2.8, Color(st_col.r, st_col.g, st_col.b, 0.88))
				if abs(st_rate) >= 10.0:
					draw_arc(st_radar, 4.2, 0, TAU, 10, Color(st_col.r, st_col.g, st_col.b, 0.6), 1.0)

	# 4. Boss & Nearby Enemy Radar Indicators
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and not e.is_dead:
			var e_world = e.global_position
			var e_radar = center + e_world * scale_factor
			
			if e.is_boss:
				# Boss Blip: Flashing warning beacon on radar
				var b_col = up_col if e.polarity == Enemy.Polarity.BULL else Color(1.0, 0.3, 0.9)
				var b_pulse = 5.0 + sin(t * 8.0) * 2.0
				draw_circle(e_radar, b_pulse, b_col)
				draw_arc(e_radar, b_pulse + 3.0, 0, TAU, 12, Color(1.0, 1.0, 0.2, 0.9), 1.5)
			elif is_instance_valid(target_player) and target_player.global_position.distance_to(e_world) < 2500.0:
				# Nearby enemies within local tactical perimeter
				var e_col = up_col if e.polarity == Enemy.Polarity.BULL else down_col
				draw_circle(e_radar, 1.6, Color(e_col.r, e_col.g, e_col.b, 0.6))

	# 5. Player Indicator on Radar
	if is_instance_valid(target_player):
		var p_radar = center + target_player.global_position * scale_factor
		
		# Check boundary clamp in radar circle
		var diff = p_radar - center
		if diff.length() > radar_radius - 6.0:
			p_radar = center + diff.normalized() * (radar_radius - 6.0)
			
		# Player Blip (Glowing Neon Cyan with Heading Cone)
		var p_rot = target_player.rotation
		var heading = Vector2(cos(p_rot), sin(p_rot))
		var left_fin = heading.rotated(2.4) * 8.0
		var right_fin = heading.rotated(-2.4) * 8.0
		var nose = heading * 10.0
		
		draw_colored_polygon(PackedVector2Array([p_radar + nose, p_radar + left_fin, p_radar + right_fin]), Color(0.2, 1.0, 0.5, 0.95))
		draw_arc(p_radar, 8.0 + sin(t * 5.0) * 2.0, 0, TAU, 16, Color(0.2, 1.0, 0.5, 0.7), 1.2)

	# 6. Radar Header & Legend Labels
	draw_string(font, center + Vector2(-80, -radar_radius - 8.0), "🧭 증시 360° 레이더", HORIZONTAL_ALIGNMENT_CENTER, 160, 16, Color(0.4, 0.85, 1.0, 0.95))
	
	# 상승/하락 컬러 레전드 범례 표기
	var legend_str = "🔴 상승   🔵 하락"
	draw_string(font, center + Vector2(-80, radar_radius + 18.0), legend_str, HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color(0.85, 0.92, 1.0, 0.95))
