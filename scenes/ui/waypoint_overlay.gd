extends Control

# High-Tech Off-Screen Waypoint Navigation Overlay
var target_player: Node2D = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)

func _process(_delta):
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
	queue_redraw()

func _draw():
	if not is_instance_valid(target_player):
		return

	var vp_size = get_viewport_rect().size
	var screen_center = vp_size * 0.5
	var p_pos = target_player.global_position
	var font = ThemeDB.fallback_font
	var zoom = 1.0 # Match Camera2D zoom
	
	# Safe boundary margins for off-screen pointer clamp
	var min_x = 70.0
	var max_x = vp_size.x - 70.0
	var min_y = 500.0 # Below top HUD panels
	var max_y = vp_size.y - 320.0 # Above bottom joystick area
	
	# Collect navigation targets: 4 Market Sectors & Central Plaza (Neutral guidance without spoilers!)
	var targets = []
	var neutral_nav_color = Color(0.35, 0.75, 1.0)
	
	for sec_key in MarketDataManager.sectors.keys():
		var sec = MarketDataManager.sectors[sec_key]
		var s_pos = sec.get("position", Vector2.ZERO)
		var dist = p_pos.distance_to(s_pos)
		targets.append({
			"name": sec["name"],
			"pos": s_pos,
			"dist": dist,
			"icon": "🧭",
			"color": neutral_nav_color
		})
	
	# Central Exchange Plaza (Show when far)
	var plaza_dist = p_pos.distance_to(MarketDataManager.CENTER_POS)
	if plaza_dist > 850.0:
		targets.append({
			"name": "증시 광장",
			"pos": MarketDataManager.CENTER_POS,
			"dist": plaza_dist,
			"icon": "🏛️",
			"color": Color(0.8, 0.9, 1.0)
		})

	# Draw each off-screen target pointer
	for target in targets:
		var world_diff = target["pos"] - p_pos
		var screen_target_pos = screen_center + world_diff * zoom
		
		# Check if target is already on screen
		if screen_target_pos.x >= min_x and screen_target_pos.x <= max_x and screen_target_pos.y >= min_y and screen_target_pos.y <= max_y:
			# Target is visible on screen, no off-screen pointer needed
			continue
			
		# Calculate intersection with screen border
		var dir = (screen_target_pos - screen_center).normalized()
		var edge_pos = _get_edge_intersection(screen_center, dir, min_x, max_x, min_y, max_y)
		
		# Draw Edge Indicator Badge
		_draw_pointer_badge(edge_pos, dir, target, font)

func _get_edge_intersection(center: Vector2, dir: Vector2, min_x: float, max_x: float, min_y: float, max_y: float) -> Vector2:
	var t_candidates = []
	if dir.x > 0:
		t_candidates.append((max_x - center.x) / dir.x)
	elif dir.x < 0:
		t_candidates.append((min_x - center.x) / dir.x)
		
	if dir.y > 0:
		t_candidates.append((max_y - center.y) / dir.y)
	elif dir.y < 0:
		t_candidates.append((min_y - center.y) / dir.y)
		
	var valid_t = 99999.0
	for t in t_candidates:
		if t > 0 and t < valid_t:
			valid_t = t
			
	return center + dir * valid_t

func _draw_pointer_badge(pos: Vector2, dir: Vector2, target: Dictionary, font: Font):
	var col = target["color"]
	var badge_w = 280.0
	var badge_h = 66.0
	
	# Clamp badge so it doesn't get clipped at edges
	var clamped_pos = pos
	clamped_pos.x = clamp(clamped_pos.x, 150.0, get_viewport_rect().size.x - 150.0)
	clamped_pos.y = clamp(clamped_pos.y, 520.0, get_viewport_rect().size.y - 360.0)
	
	var badge_rect = Rect2(clamped_pos - Vector2(badge_w * 0.5, badge_h * 0.5), Vector2(badge_w, badge_h))
	
	# Glassmorphism badge background
	draw_rect(badge_rect, Color(0.04, 0.08, 0.15, 0.92), true)
	draw_rect(badge_rect, Color(col.r, col.g, col.b, 0.9), false, 2.5)
	
	# Prominent directional triangle pointer outside badge
	var arrow_center = clamped_pos + dir * 42.0
	var normal = Vector2(-dir.y, dir.x)
	var arrow_pts = PackedVector2Array([
		arrow_center + dir * 18.0,
		arrow_center - dir * 8.0 + normal * 12.0,
		arrow_center - dir * 8.0 - normal * 12.0
	])
	draw_colored_polygon(arrow_pts, col)
	
	# Large, Clear Text: [Icon Name | Dist]
	var dist_km = target["dist"] / 1000.0
	var text_str = "%s %s (%.1fkm)" % [target["icon"], target["name"], dist_km]
	draw_string(font, clamped_pos + Vector2(-badge_w * 0.5 + 8, 9), text_str, HORIZONTAL_ALIGNMENT_CENTER, int(badge_w - 16), 28, col)
