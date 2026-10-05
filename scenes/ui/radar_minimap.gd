extends Control

# High-Tech Cyber Radar Minimap & Off-Screen Waypoint Navigation
var radar_radius: float = 85.0
var world_max_radius: float = 8500.0
var target_player: Node2D = null

func _ready():
	custom_minimum_size = Vector2(190, 190)

func _process(_delta):
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
	queue_redraw()

func _draw():
	var center = size * 0.5
	var font = ThemeDB.fallback_font
	var t = Global.game_time
	
	# 1. Radar Glass Background
	draw_circle(center, radar_radius, Color(0.03, 0.07, 0.13, 0.82))
	draw_arc(center, radar_radius, 0, TAU, 48, Color(0.35, 0.7, 1.0, 0.65), 2.0)
	draw_arc(center, radar_radius * 0.65, 0, TAU, 36, Color(0.35, 0.7, 1.0, 0.22), 1.0)
	draw_arc(center, radar_radius * 0.35, 0, TAU, 24, Color(0.35, 0.7, 1.0, 0.22), 1.0)
	
	# Radar Crosshair Axes
	draw_line(center - Vector2(radar_radius, 0), center + Vector2(radar_radius, 0), Color(0.35, 0.7, 1.0, 0.25), 1.0)
	draw_line(center - Vector2(0, radar_radius), center + Vector2(0, radar_radius), Color(0.35, 0.7, 1.0, 0.25), 1.0)
	
	# Rotating Radar Scan Beam Line
	var scan_angle = fmod(t * 2.2, TAU)
	var scan_vec = Vector2(cos(scan_angle), sin(scan_angle)) * radar_radius
	draw_line(center, center + scan_vec, Color(0.4, 0.9, 1.0, 0.4), 1.5)
	
	var scale_factor = radar_radius / world_max_radius
	
	# 2. Central Exchange Plaza Dot (0, 0)
	var plaza_pos = center + MarketDataManager.CENTER_POS * scale_factor
	draw_circle(plaza_pos, 4.0, Color(1.0, 0.9, 0.4, 0.9))
	
	# 3. Sectors & Stocks on Radar (Neutral radar blips until reached)
	for sec_key in MarketDataManager.sectors.keys():
		var sec = MarketDataManager.sectors[sec_key]
		var s_world = sec.get("position", Vector2.ZERO)
		var s_radar = center + s_world * scale_factor
		
		# Only reveal real color if player is currently in this sector!
		var is_inside = false
		if is_instance_valid(target_player):
			is_inside = target_player.global_position.distance_to(s_world) <= sec.get("radius", 1000.0)
			
		var is_up = sec.get("change_rate", 0.0) >= 0.0
		var real_col = Global.get_up_color() if is_up else Global.get_down_color()
		var sec_col = real_col if is_inside else Color(0.4, 0.75, 1.0) # Neutral radar cyan
		
		# Sector Dot
		draw_circle(s_radar, 6.0, sec_col)
		draw_arc(s_radar, 7.5, 0, TAU, 16, Color(1, 1, 1, 0.8), 1.2)
		
		# Initial character tag
		var tag = sec["name"].substr(0, 1)
		draw_string(font, s_radar + Vector2(-8, 5), tag, HORIZONTAL_ALIGNMENT_CENTER, 16, 15, Color(1, 1, 1, 0.95))
		
		# Stock dots (Neutral cyan)
		if sec.has("stocks"):
			for st in sec["stocks"]:
				var st_world = st.get("world_pos", s_world)
				var st_radar = center + st_world * scale_factor
				draw_circle(st_radar, 2.5, Color(0.5, 0.8, 1.0, 0.5))

	# 4. Player Indicator on Radar
	if is_instance_valid(target_player):
		var p_radar = center + target_player.global_position * scale_factor
		
		# Check boundary clamp in radar circle
		var diff = p_radar - center
		if diff.length() > radar_radius - 6.0:
			p_radar = center + diff.normalized() * (radar_radius - 6.0)
			
		# Player Blip (Glowing Cyan with Heading Cone)
		var p_rot = target_player.rotation
		var heading = Vector2(cos(p_rot), sin(p_rot))
		var left_fin = heading.rotated(2.4) * 8.0
		var right_fin = heading.rotated(-2.4) * 8.0
		var nose = heading * 10.0
		
		draw_colored_polygon(PackedVector2Array([p_radar + nose, p_radar + left_fin, p_radar + right_fin]), Color(0.2, 1.0, 0.5, 0.95))
		draw_arc(p_radar, 8.0 + sin(t * 5.0) * 2.0, 0, TAU, 16, Color(0.2, 1.0, 0.5, 0.7), 1.2)

	# 5. Radar Header Title Label
	draw_string(font, center + Vector2(-80, -radar_radius - 8.0), "🧭 증시 360° 레이더", HORIZONTAL_ALIGNMENT_CENTER, 160, 18, Color(0.4, 0.85, 1.0, 0.95))
