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

func _ready():
	add_to_group("player")
	var magnet_area = $MagnetArea
	if magnet_area:
		magnet_area.area_entered.connect(_on_magnet_area_entered)
	update_magnet_radius()

func _draw():
	var font = ThemeDB.fallback_font

	# 0. Liquidity Magnet Area Visual Wave
	var mag_lvl = Global.skills["liquidity_magnet"]["level"] if Global.skills.has("liquidity_magnet") else 0
	if mag_lvl > 0:
		var mag_r = 180.0 + mag_lvl * 140.0
		var pulse = sin(Global.game_time * 3.5) * 8.0
		draw_arc(Vector2.ZERO, mag_r + pulse, 0.0, TAU, 36, Color(0.2, 0.75, 1.0, 0.12 + mag_lvl * 0.03), 2.0)

	# 1. Zone Buff/Debuff Auras
	if Global.in_bear_hazard:
		# Icy Frost Aura & Slowdown Indicator
		draw_circle(Vector2.ZERO, 36.0, Color(0.2, 0.55, 1.0, 0.28))
		draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 24, Color(0.4, 0.75, 1.0, 0.8), 2.5)
		draw_string(font, Vector2(-40, -38), "⚠️ 혹한기 감속 -20%", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.6, 0.85, 1.0))
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


func _physics_process(delta):
	if Global.is_game_over or Global.is_paused:
		return
		
	# Movement input (Keyboard or Mobile Virtual Joystick)
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO and Global.joystick_vector.length() > 0:
		input_dir = Global.joystick_vector
	var scalping_lvl = Global.skills["scalping"]["level"] if Global.skills.has("scalping") else 0
	var speed_mult = (1.6 if is_hodl_active else 1.0) * Global.player_speed_modifier * Global.bonus_speed_multiplier * (1.0 + scalping_lvl * 0.10)
	velocity = input_dir.normalized() * move_speed * speed_mult
	
	if input_dir.length() > 0:
		rotation = lerp_angle(rotation, input_dir.angle(), 15.0 * delta)
		
	move_and_slide()
	queue_redraw()
	
	# Process timers
	_process_weapons(delta)
	
	if iframe_timer > 0:
		iframe_timer -= delta

func _process_weapons(delta):
	# 1. Green Candle Beam
	var gbeam_lvl = Global.skills["green_beam"]["level"]
	if gbeam_lvl > 0:
		green_beam_timer += delta
		var scalping_lvl = Global.skills["scalping"]["level"] if Global.skills.has("scalping") else 0
		var cooldown = max(0.12, (1.2 - gbeam_lvl * 0.18) * (1.0 - scalping_lvl * 0.10))
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
			proj.damage = 35.0
			proj.speed = 700.0
			proj.pierce_count = 10 + quant_lvl * 2
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
			proj.damage = 22.0 + level * 6.0
			proj.speed = 650.0
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
	var nearest: Node2D = null
	var min_dist: float = 99999.0
	for e in enemies:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
	return nearest

func _on_magnet_area_entered(area):
	if area.is_in_group("exp_gem") and area.has_method("attract_to"):
		area.attract_to(self)

func update_magnet_radius():
	var mag_lvl = Global.skills["liquidity_magnet"]["level"] if Global.skills.has("liquidity_magnet") else 0
	var magnet_shape = get_node_or_null("MagnetArea/CollisionShape2D")
	if magnet_shape and magnet_shape.shape is CircleShape2D:
		# Base 180px, +140px per level (Lv 5 = 880px!)
		magnet_shape.shape.radius = 180.0 + mag_lvl * 140.0
