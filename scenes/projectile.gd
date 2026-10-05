extends Area2D

enum Type { GREEN_BEAM, DCA_ORB, STOP_LOSS_SHOCK, RUMOR_BULLET, INTEREST_RATE_BEAM, TARIFF_BOMB, TRUTH_TWEET }

@export var type: Type = Type.GREEN_BEAM
@export var damage: float = 25.0
@export var speed: float = 500.0
@export var lifetime: float = 2.0
@export var pierce_count: int = 3
@export var is_enemy_projectile: bool = false

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var shock_radius: float = 10.0
var orb_angle: float = 0.0
var orb_radius: float = 70.0
var parent_player: Node2D = null

func init_directional(dir: Vector2, p_damage: float, p_speed: float = 650.0, p_lifetime: float = 1.5, p_color: Color = Color.GREEN, p_pierce: int = 1):
	direction = dir.normalized()
	rotation = dir.angle()
	damage = p_damage
	speed = p_speed
	lifetime = p_lifetime
	pierce_count = p_pierce
	type = Type.GREEN_BEAM

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Make collision shape unique per instance so STOP_LOSS_SHOCK expansion doesn't contaminate all projectiles!
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape and col_shape.shape:
		col_shape.shape = col_shape.shape.duplicate()
		match type:
			Type.GREEN_BEAM:
				col_shape.shape.radius = 16.0
			Type.DCA_ORB:
				col_shape.shape.radius = 14.0
			Type.STOP_LOSS_SHOCK:
				col_shape.shape.radius = 10.0
			Type.RUMOR_BULLET:
				col_shape.shape.radius = 10.0
			Type.INTEREST_RATE_BEAM:
				col_shape.shape.radius = 18.0
			Type.TARIFF_BOMB:
				col_shape.shape.radius = 16.0
			Type.TRUTH_TWEET:
				col_shape.shape.radius = 12.0
	
	if lifetime > 0:
		get_tree().create_timer(lifetime).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)

func _draw():
	match type:
		Type.GREEN_BEAM:
			# Draw candle stick beam
			var width = 14.0
			var length = 40.0
			# Wick line
			draw_line(Vector2(-length*0.5 - 8, 0), Vector2(length*0.5 + 8, 0), Color(0.0, 1.0, 0.4, 0.8), 2.0)
			# Green Body rect
			var rect = Rect2(Vector2(-length*0.5, -width*0.5), Vector2(length, width))
			draw_rect(rect, Color(0.0, 1.0, 0.4, 0.95))
			draw_rect(rect, Color(0.8, 1.0, 0.8), false, 2.0)
			
		Type.DCA_ORB:
			# DCA Shield Drone with rotating diamond matrix
			draw_circle(Vector2.ZERO, 14.0, Color(0.1, 0.85, 0.35, 0.3))
			draw_circle(Vector2.ZERO, 9.0, Color(0.2, 0.95, 0.45, 0.85))
			draw_arc(Vector2.ZERO, 14.0, 0, TAU, 24, Color(0.5, 1.0, 0.7), 2.2)
			var d_poly = PackedVector2Array([Vector2(0, -6), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)])
			draw_colored_polygon(d_poly, Color(1.0, 1.0, 1.0, 0.95))
			
		Type.STOP_LOSS_SHOCK:
			# Draw expanding shockwave ring
			draw_arc(Vector2.ZERO, shock_radius, 0.0, TAU, 32, Color(0.0, 0.9, 1.0, 0.8), 6.0)
			draw_arc(Vector2.ZERO, max(1.0, shock_radius - 8.0), 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.6), 3.0)
			
		Type.RUMOR_BULLET:
			# 3-Blade Rotating Rumor Shuriken (Gold & Crimson distortion)
			var t_rot = distance_traveled * 0.06
			for i in range(3):
				var a = t_rot + i * (TAU / 3.0)
				var blade_tip = Vector2(cos(a), sin(a)) * 13.0
				var blade_l = Vector2(cos(a - 0.45), sin(a - 0.45)) * 5.0
				var blade_r = Vector2(cos(a + 0.45), sin(a + 0.45)) * 5.0
				draw_colored_polygon(PackedVector2Array([Vector2.ZERO, blade_l, blade_tip, blade_r]), Color(1.0, 0.78, 0.15))
			draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.20, 0.25))
			draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 1.0))
			
		Type.INTEREST_RATE_BEAM:
			# Heavy Red Shock Laser Lance
			var width = 20.0
			var length = 80.0
			draw_line(Vector2(-length * 0.5, 0), Vector2(length * 0.5, 0), Color(1.0, 0.18, 0.22, 0.95), width)
			draw_line(Vector2(-length * 0.5 + 8, 0), Vector2(length * 0.5 - 8, 0), Color(1.0, 0.9, 0.9), width * 0.45)
			for i in range(-2, 3):
				draw_circle(Vector2(i * 16.0, 0), width * 0.65, Color(1.0, 0.45, 0.15, 0.5))

		Type.TARIFF_BOMB:
			# Heavy Armored Tariff Missile Warhead (Pointing +X forward)
			var missile_body = PackedVector2Array([
				Vector2(20, 0),     # Warhead tip
				Vector2(10, -9),    # Shoulder
				Vector2(-13, -9),   # Fuselage back
				Vector2(-18, -15),  # Fin upper tip
				Vector2(-13, -4),   # Engine notch
				Vector2(-13, 4),
				Vector2(-18, 15),   # Fin lower tip
				Vector2(-13, 9),
				Vector2(10, 9)
			])
			draw_colored_polygon(missile_body, Color(0.95, 0.18, 0.22))
			draw_polyline(PackedVector2Array([
				missile_body[0], missile_body[1], missile_body[2], missile_body[3],
				missile_body[4], missile_body[5], missile_body[6], missile_body[7],
				missile_body[8], missile_body[0]
			]), Color(1.0, 0.85, 0.3), 2.2)
			# Golden warhead ring
			draw_line(Vector2(6, -8), Vector2(6, 8), Color(1.0, 0.85, 0.25), 3.0)
			# Rocket engine booster flame
			var flame_len = 7.0 + randf() * 7.0
			draw_colored_polygon(PackedVector2Array([Vector2(-13, -5), Vector2(-13 - flame_len, 0), Vector2(-13, 5)]), Color(1.0, 0.75, 0.15))

		Type.TRUTH_TWEET:
			# Supersonic Cyber Bird Dart (Pointing +X forward)
			var bird_pts = PackedVector2Array([
				Vector2(18, 0),     # Beak tip
				Vector2(4, -8),     # Wing left base
				Vector2(-12, -15),  # Wing left tip
				Vector2(-5, -4),    # Inner body
				Vector2(-13, 0),    # Tail
				Vector2(-5, 4),
				Vector2(-12, 15),   # Wing right tip
				Vector2(4, 8)
			])
			draw_colored_polygon(bird_pts, Color(0.18, 0.65, 1.0))
			draw_polyline(PackedVector2Array([
				bird_pts[0], bird_pts[1], bird_pts[2], bird_pts[3],
				bird_pts[4], bird_pts[5], bird_pts[6], bird_pts[7], bird_pts[0]
			]), Color(0.75, 0.95, 1.0), 2.0)
			draw_circle(Vector2(4, 0), 3.5, Color(1, 1, 1))

func _process(delta):
	match type:
		Type.GREEN_BEAM, Type.RUMOR_BULLET, Type.INTEREST_RATE_BEAM, Type.TARIFF_BOMB, Type.TRUTH_TWEET:
			global_position += direction * speed * delta
			
		Type.DCA_ORB:
			if is_instance_valid(parent_player):
				orb_angle += 3.0 * delta
				global_position = parent_player.global_position + Vector2(cos(orb_angle), sin(orb_angle)) * orb_radius
			else:
				queue_free()
				
		Type.STOP_LOSS_SHOCK:
			shock_radius += 400.0 * delta
			queue_redraw()
			var shape = get_node_or_null("CollisionShape2D")
			if shape and shape.shape is CircleShape2D:
				shape.shape.radius = shock_radius

var hit_enemy_times: Dictionary = {}

func _hit_target_enemy(enemy_node: Node2D):
	if not is_instance_valid(enemy_node):
		return
	var eid = enemy_node.get_instance_id()
	var now = Time.get_ticks_msec()
	# Prevent duplicate same-frame hits from body+area, and throttle continuous aura damage to 250ms
	if now - hit_enemy_times.get(eid, 0) < 250:
		return
	hit_enemy_times[eid] = now
	
	if enemy_node.has_method("take_damage"):
		var actual_damage = damage * Global.get_damage_multiplier()
		enemy_node.take_damage(actual_damage, direction)
		pierce_count -= 1
		if pierce_count <= 0 and type != Type.DCA_ORB and type != Type.STOP_LOSS_SHOCK:
			queue_free()

func _on_body_entered(body):
	if is_enemy_projectile:
		if body.is_in_group("player"):
			Global.take_player_damage(damage)
			queue_free()
	else:
		if body.is_in_group("enemy"):
			_hit_target_enemy(body)

func _on_area_entered(area):
	if not is_enemy_projectile and area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy and enemy.is_in_group("enemy"):
			_hit_target_enemy(enemy)
