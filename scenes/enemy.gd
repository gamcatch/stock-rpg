class_name Enemy
extends CharacterBody2D

enum EnemyType { PANIC_SELL, FAKE_NEWS, RED_CANDLE, BEAR_BOSS, TRUMP_BOSS }
enum Polarity { BULL, BEAR }

const ProjectileScript = preload("res://scenes/projectile.gd")

@export var type: EnemyType = EnemyType.PANIC_SELL
@export var polarity: Polarity = Polarity.BULL
@export var max_hp: float = 30.0
@export var move_speed: float = 140.0
@export var contact_damage: float = 12.0
@export var exp_reward: int = 3
@export var is_boss: bool = false

var hp: float = 30.0
var is_dead: bool = false
var player: Node2D = null
var knockback: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0
var flash_timer: float = 0.0

var gem_scene: PackedScene = preload("res://scenes/exp_gem.tscn")
var proj_scene: PackedScene = preload("res://scenes/projectile.tscn")

func _ready():
	add_to_group("enemy")
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	_setup_stats()

func _setup_stats():
	var col_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
	var hurt_shape = $HurtArea/CollisionShape2D if has_node("HurtArea/CollisionShape2D") else null
	var r = 24.0

	match type:
		EnemyType.PANIC_SELL:
			max_hp = 25.0
			move_speed = 195.0
			contact_damage = 10.0
			exp_reward = 2
			r = 24.0
		EnemyType.FAKE_NEWS:
			max_hp = 55.0
			move_speed = 135.0
			contact_damage = 15.0
			exp_reward = 5
			r = 28.0
		EnemyType.RED_CANDLE:
			max_hp = 120.0
			move_speed = 110.0
			contact_damage = 25.0
			exp_reward = 10
			r = 34.0
		EnemyType.BEAR_BOSS:
			max_hp = 800.0
			move_speed = 120.0
			contact_damage = 35.0
			exp_reward = 50
			is_boss = true
			r = 60.0
		EnemyType.TRUMP_BOSS:
			max_hp = 3500.0
			move_speed = 95.0
			contact_damage = 50.0
			exp_reward = 350
			is_boss = true
			r = 80.0
	hp = max_hp
	
	# Scale collision shapes to match bigger visuals
	if col_shape and col_shape.shape is CircleShape2D:
		col_shape.shape = col_shape.shape.duplicate()
		col_shape.shape.radius = r
	if hurt_shape and hurt_shape.shape is CircleShape2D:
		hurt_shape.shape = hurt_shape.shape.duplicate()
		hurt_shape.shape.radius = r + 3.0

func _draw():
	if flash_timer > 0:
		draw_circle(Vector2.ZERO, 32.0, Color(1.0, 1.0, 1.0, 0.9))
		return

	# Single cohesive theme color based on stock market polarity
	# 🔴 Red: Bull / Surge (떡상/과열)
	# 🔵 Blue: Bear / Short-selling / Panic Drop (하락/공매도)
	var is_bull = (polarity == Polarity.BULL)
	var theme_color = Color(0.95, 0.22, 0.25) if is_bull else Color(0.20, 0.55, 1.0)
	var glow_color = Color(0.95, 0.22, 0.25, 0.25) if is_bull else Color(0.20, 0.55, 1.0, 0.25)
	var rim_color = Color(1.0, 0.55, 0.55) if is_bull else Color(0.65, 0.88, 1.0)

	# 1. Subtle soft footprint glow (scaled up)
	draw_circle(Vector2.ZERO, 28.0, glow_color)

	var font = ThemeDB.fallback_font

	match type:
		EnemyType.PANIC_SELL:
			# Large, Menacing Single-color Stock Arrow Predator (~54x44px)
			# Faces forward towards target with crisp geometric wings
			var delta_pts = PackedVector2Array([
				Vector2(28, 0),     # Forward spear tip
				Vector2(-10, -20),  # Left wing tip
				Vector2(-20, -11),  # Left rear fin
				Vector2(-13, 0),    # Inner engine notch
				Vector2(-20, 11),   # Right rear fin
				Vector2(-10, 20)    # Right wing tip
			])
			draw_colored_polygon(delta_pts, theme_color)
			draw_polyline(PackedVector2Array([
				delta_pts[0], delta_pts[1], delta_pts[2], delta_pts[3],
				delta_pts[4], delta_pts[5], delta_pts[0]
			]), rim_color, 2.2)
			
			# Glowing predatory white eyes
			draw_circle(Vector2(8, -6), 3.5, Color(1, 1, 1))
			draw_circle(Vector2(8, 6), 3.5, Color(1, 1, 1))

		EnemyType.FAKE_NEWS:
			# Rumor Alert Mimic Beast (악마의 찌라시 몬스터)
			# Flapping warning document wings & razor fanged mimic jaws
			var t_mimic = Global.game_time
			var flap = sin(t_mimic * 14.0) * 5.0

			# 1. Menacing Flapping Cyber Document Wings
			var up_wing = PackedVector2Array([
				Vector2(-12, -14),
				Vector2(-24, -36 + flap),
				Vector2(4, -28 + flap),
				Vector2(14, -14)
			])
			draw_colored_polygon(up_wing, Color(1.0, 0.75, 0.15))
			draw_polyline(up_wing, Color(1.0, 0.95, 0.5), 2.2)

			var low_wing = PackedVector2Array([
				Vector2(-12, 14),
				Vector2(-24, 36 - flap),
				Vector2(4, 28 - flap),
				Vector2(14, 14)
			])
			draw_colored_polygon(low_wing, Color(1.0, 0.75, 0.15))
			draw_polyline(low_wing, Color(1.0, 0.95, 0.5), 2.2)

			# Black caution hazard stripes on wings
			draw_line(Vector2(-14, -20 + flap * 0.5), Vector2(-6, -24 + flap * 0.5), Color(0.12, 0.12, 0.15), 3.0)
			draw_line(Vector2(-14, 20 - flap * 0.5), Vector2(-6, 24 - flap * 0.5), Color(0.12, 0.12, 0.15), 3.0)

			# 2. Main Mimic Jaws & Head (Pointing +X forward)
			var body_pts = PackedVector2Array([
				Vector2(28, 0),    # Forward snout tip
				Vector2(8, -18),
				Vector2(-22, -15),
				Vector2(-18, 0),
				Vector2(-22, 15),
				Vector2(8, 18)
			])
			draw_colored_polygon(body_pts, Color(0.95, 0.68, 0.10))
			draw_polyline(PackedVector2Array([body_pts[0], body_pts[1], body_pts[2], body_pts[3], body_pts[4], body_pts[5], body_pts[0]]), Color(1.0, 0.9, 0.4), 2.4)

			# Dark inner mouth opening
			var mouth_pts = PackedVector2Array([
				Vector2(24, 0),
				Vector2(6, -10),
				Vector2(0, 0),
				Vector2(6, 10)
			])
			draw_colored_polygon(mouth_pts, Color(0.12, 0.04, 0.08))

			# Sharp White Razor Fangs
			draw_colored_polygon(PackedVector2Array([Vector2(8, -10), Vector2(15, -9), Vector2(11, -2)]), Color(1, 1, 1))
			draw_colored_polygon(PackedVector2Array([Vector2(8, 10), Vector2(15, 9), Vector2(11, 2)]), Color(1, 1, 1))
			draw_colored_polygon(PackedVector2Array([Vector2(18, -5), Vector2(24, 0), Vector2(18, 5)]), Color(1.0, 0.95, 0.7))

			# 3. Slanted Glowing Evil Predator Eyes
			draw_line(Vector2(2, -11), Vector2(12, -7), Color(1.0, 0.15, 0.22), 4.0)
			draw_circle(Vector2(8, -9), 2.0, Color(1, 1, 1))
			draw_line(Vector2(2, 11), Vector2(12, 7), Color(1.0, 0.15, 0.22), 4.0)
			draw_circle(Vector2(8, 9), 2.0, Color(1, 1, 1))

			# 4. Central Warning Hazard Sigil (Geometric Triangle, No Text)
			var tri_pts = PackedVector2Array([
				Vector2(-12, -7),
				Vector2(-4, 0),
				Vector2(-12, 7)
			])
			draw_colored_polygon(tri_pts, Color(1.0, 0.15, 0.22))

		EnemyType.RED_CANDLE:
			# Towering Candlestick Monster (80px tall)
			draw_line(Vector2(0, -40), Vector2(0, 40), theme_color, 4.5)
			var candle_box = Rect2(Vector2(-17, -25), Vector2(34, 50))
			draw_rect(candle_box, theme_color)
			draw_rect(candle_box, rim_color, false, 2.5)
			# Angry chart face
			draw_circle(Vector2(-6, -4), 3.8, Color(1, 1, 1))
			draw_circle(Vector2(6, -4), 3.8, Color(1, 1, 1))
			draw_circle(Vector2(-6, -4), 2.0, Color(0.1, 0.1, 0.1))
			draw_circle(Vector2(6, -4), 2.0, Color(0.1, 0.1, 0.1))

		EnemyType.BEAR_BOSS:
			# Massive Cybernetic Short-Seller Beast (Alpha Bear)
			var t_boss = Global.game_time
			var up_dir = Vector2.UP.rotated(-rotation)
			var right_dir = Vector2.RIGHT.rotated(-rotation)
			
			# 1. Menacing Sub-zero Frost Spikes Aura
			var spike_count = 12
			for i in range(spike_count):
				var spk_ang = (i * TAU) / spike_count + sin(t_boss * 3.0 + i) * 0.1
				var spk_r1 = 62.0
				var spk_r2 = 74.0 + sin(t_boss * 6.0 + i * 2.0) * 8.0
				draw_line(Vector2(cos(spk_ang), sin(spk_ang)) * spk_r1, Vector2(cos(spk_ang), sin(spk_ang)) * spk_r2, Color(0.2, 0.6, 1.0, 0.4), 2.5)

			# 2. Heavy Armored Shoulders & Bear Claws
			# Upper pauldron & claws
			var up_paw = PackedVector2Array([
				Vector2(-15, -45), Vector2(12, -58), Vector2(34, -48), Vector2(25, -30), Vector2(-12, -30)
			])
			draw_colored_polygon(up_paw, Color(0.06, 0.10, 0.20))
			draw_polyline(up_paw, Color(0.3, 0.75, 1.0), 2.2)
			draw_line(Vector2(30, -52), Vector2(42, -56), Color(0.8, 0.95, 1.0), 3.0)
			draw_line(Vector2(34, -48), Vector2(46, -48), Color(0.8, 0.95, 1.0), 3.0)
			draw_line(Vector2(32, -42), Vector2(43, -40), Color(0.8, 0.95, 1.0), 3.0)

			# Lower pauldron & claws
			var low_paw = PackedVector2Array([
				Vector2(-15, 45), Vector2(12, 58), Vector2(34, 48), Vector2(25, 30), Vector2(-12, 30)
			])
			draw_colored_polygon(low_paw, Color(0.06, 0.10, 0.20))
			draw_polyline(low_paw, Color(0.3, 0.75, 1.0), 2.2)
			draw_line(Vector2(30, 52), Vector2(42, 56), Color(0.8, 0.95, 1.0), 3.0)
			draw_line(Vector2(34, 48), Vector2(46, 48), Color(0.8, 0.95, 1.0), 3.0)
			draw_line(Vector2(32, 42), Vector2(43, 40), Color(0.8, 0.95, 1.0), 3.0)

			# 3. Massive Armored Bear Torso & Ears
			draw_circle(Vector2(-32, -42), 16.0, Color(0.08, 0.13, 0.25))
			draw_arc(Vector2(-32, -42), 16.0, 0, TAU, 18, Color(0.3, 0.75, 1.0), 2.0)
			draw_circle(Vector2(-32, -42), 8.0, Color(0.15, 0.45, 0.85, 0.7))
			
			draw_circle(Vector2(-32, 42), 16.0, Color(0.08, 0.13, 0.25))
			draw_arc(Vector2(-32, 42), 16.0, 0, TAU, 18, Color(0.3, 0.75, 1.0), 2.0)
			draw_circle(Vector2(-32, 42), 8.0, Color(0.15, 0.45, 0.85, 0.7))

			# Main Beast Body
			draw_circle(Vector2(-8, 0), 50.0, Color(0.07, 0.11, 0.22))
			draw_arc(Vector2(-8, 0), 50.0, 0, TAU, 36, Color(0.2, 0.65, 1.0), 3.0)

			# 4. Ferocious Snout & Razor Cyber-Fangs (Pointing towards target +X)
			var snout_pts = PackedVector2Array([
				Vector2(12, -26),
				Vector2(48, -17),
				Vector2(62, 0),
				Vector2(48, 17),
				Vector2(12, 26),
				Vector2(-2, 0)
			])
			draw_colored_polygon(snout_pts, Color(0.11, 0.18, 0.32))
			draw_polyline(PackedVector2Array([snout_pts[0], snout_pts[1], snout_pts[2], snout_pts[3], snout_pts[4]]), Color(0.4, 0.85, 1.0), 2.8)

			draw_circle(Vector2(58, 0), 5.0, Color(0.03, 0.06, 0.12))
			draw_arc(Vector2(58, 0), 5.0, 0, TAU, 12, Color(0.4, 0.8, 1.0), 1.5)

			# Sharp Cyber Fangs
			draw_colored_polygon(PackedVector2Array([Vector2(36, -16), Vector2(47, -13), Vector2(41, -5)]), Color(1, 1, 1))
			draw_colored_polygon(PackedVector2Array([Vector2(36, 16), Vector2(47, 13), Vector2(41, 5)]), Color(1, 1, 1))

			# Glowing Predatory Cyber Eyes
			draw_line(Vector2(20, -17), Vector2(36, -12), Color(0.0, 0.95, 1.0), 5.0)
			draw_circle(Vector2(30, -14), 2.8, Color(1, 1, 1))
			draw_line(Vector2(20, 17), Vector2(36, 12), Color(0.0, 0.95, 1.0), 5.0)
			draw_circle(Vector2(30, 14), 2.8, Color(1, 1, 1))

			# 5. Short-Selling 3-Bar Downtrend Claw Lacerations (Neon Red)
			draw_line(Vector2(-35, -20), Vector2(-12, -10), Color(1.0, 0.25, 0.3), 3.5)
			draw_line(Vector2(-30, -5), Vector2(-6, 5), Color(1.0, 0.25, 0.3), 3.5)
			draw_line(Vector2(-25, 10), Vector2(-2, 20), Color(1.0, 0.25, 0.3), 3.5)

			# Pulsing Anti-Bull Core
			var core_pulse = sin(t_boss * 5.0) * 3.0
			draw_circle(Vector2(-8, 0), 14.0 + core_pulse, Color(0.1, 0.5, 0.9, 0.25))
			draw_arc(Vector2(-8, 0), 14.0 + core_pulse, 0, TAU, 20, Color(0.3, 0.9, 1.0), 2.0)

			# 6. Overhead Upright Boss HP Bar & Crown (Screen Aligned)
			var bar_pos = up_dir * 88.0
			var bar_half_w = 54.0
			var bar_h = 7.0
			var hp_ratio = clampf(hp / max_hp, 0.0, 1.0)

			# Health bar background & frame
			draw_line(bar_pos - right_dir * bar_half_w, bar_pos + right_dir * bar_half_w, Color(0.04, 0.07, 0.14, 0.92), bar_h + 3.0)
			draw_line(bar_pos - right_dir * (bar_half_w + 2.0), bar_pos + right_dir * (bar_half_w + 2.0), Color(0.3, 0.8, 1.0, 0.85), 1.5)
			
			# Health bar fill
			if hp_ratio > 0.001:
				var fill_start = bar_pos - right_dir * bar_half_w
				var fill_end = fill_start + right_dir * (bar_half_w * 2.0 * hp_ratio)
				var bar_col = Color(0.15, 0.85, 1.0) if hp_ratio > 0.35 else Color(1.0, 0.25, 0.35)
				draw_line(fill_start, fill_end, bar_col, bar_h)

			# Overhead Floating Alpha Crown
			var crown_c = up_dir * 105.0
			var cr_pts = PackedVector2Array([
				crown_c - right_dir * 16.0,
				crown_c - right_dir * 20.0 + up_dir * 10.0,
				crown_c - right_dir * 8.0 + up_dir * 5.0,
				crown_c + up_dir * 15.0,
				crown_c + right_dir * 8.0 + up_dir * 5.0,
				crown_c + right_dir * 20.0 + up_dir * 10.0,
				crown_c + right_dir * 16.0
			])
			draw_colored_polygon(cr_pts, Color(0.2, 0.75, 1.0, 0.9))
			draw_polyline(cr_pts, Color(0.7, 0.95, 1.0), 1.8)
			draw_circle(crown_c + up_dir * 15.0, 2.5, Color(1, 1, 1))

		EnemyType.TRUMP_BOSS:
			# President Trump Final Boss (Tariff Overlord Titan)
			var t_boss = Global.game_time
			var up_dir = Vector2.UP.rotated(-rotation)
			var right_dir = Vector2.RIGHT.rotated(-rotation)

			# 1. 4 Orbiting Golden Tariff Diamond Shields (100% Tariff Barriers)
			for i in range(4):
				var orb_ang = t_boss * 2.2 + i * (TAU / 4.0)
				var orb_pos = Vector2(cos(orb_ang), sin(orb_ang)) * 105.0
				var d_size = 14.0
				var d_poly = PackedVector2Array([
					orb_pos + Vector2(0, -d_size),
					orb_pos + Vector2(d_size, 0),
					orb_pos + Vector2(0, d_size),
					orb_pos + Vector2(-d_size, 0)
				])
				draw_colored_polygon(d_poly, Color(1.0, 0.82, 0.22, 0.88))
				draw_polyline(PackedVector2Array([d_poly[0], d_poly[1], d_poly[2], d_poly[3], d_poly[0]]), Color(1.0, 0.98, 0.7), 2.2)
				draw_circle(orb_pos, 4.2, Color(1.0, 0.20, 0.25))

			# 2. Massive Executive Navy Power Suit & Golden Pauldrons
			draw_arc(Vector2.ZERO, 78.0, 0, TAU, 44, Color(1.0, 0.82, 0.24, 0.8), 3.5)
			draw_arc(Vector2.ZERO, 70.0, 0, TAU, 36, Color(0.8, 0.65, 0.15, 0.35), 2.0)

			draw_circle(Vector2.ZERO, 74.0, Color(0.06, 0.10, 0.20))
			draw_circle(Vector2.ZERO, 58.0, Color(0.10, 0.16, 0.28))

			var sh_left = PackedVector2Array([Vector2(-40, -68), Vector2(0, -78), Vector2(30, -68), Vector2(10, -48), Vector2(-30, -48)])
			draw_colored_polygon(sh_left, Color(0.08, 0.13, 0.24))
			draw_polyline(sh_left, Color(1.0, 0.84, 0.22), 2.5)

			var sh_right = PackedVector2Array([Vector2(-40, 68), Vector2(0, 78), Vector2(30, 68), Vector2(10, 48), Vector2(-30, 48)])
			draw_colored_polygon(sh_right, Color(0.08, 0.13, 0.24))
			draw_polyline(sh_right, Color(1.0, 0.84, 0.22), 2.5)

			# Crisp White Dress Shirt Collar
			var collar_pts = PackedVector2Array([
				Vector2(8, -26), Vector2(38, -16), Vector2(32, 0), Vector2(38, 16), Vector2(8, 26), Vector2(2, 0)
			])
			draw_colored_polygon(collar_pts, Color(0.95, 0.96, 1.0))
			draw_polyline(collar_pts, Color(0.7, 0.75, 0.85), 1.8)

			# 3. Signature Bold Crimson Silk Power Tie (Flowing Forward)
			var tie_pts = PackedVector2Array([
				Vector2(14, -10),
				Vector2(14, 10),
				Vector2(65, 14),
				Vector2(82, 0),
				Vector2(65, -14)
			])
			draw_colored_polygon(tie_pts, Color(0.96, 0.12, 0.20))
			draw_polyline(PackedVector2Array([tie_pts[0], tie_pts[1], tie_pts[2], tie_pts[3], tie_pts[4], tie_pts[0]]), Color(1.0, 0.5, 0.55), 2.2)
			draw_line(Vector2(35, -11), Vector2(35, 11), Color(1.0, 0.88, 0.3), 3.5)

			# 4. Sculptural Iconic Golden Power Hairstyle
			var hair_pts = PackedVector2Array([
				Vector2(-45, -35),
				Vector2(-35, -70),
				Vector2(16, -72),
				Vector2(58, -48),
				Vector2(68, -18),
				Vector2(48, -14),
				Vector2(22, -38),
				Vector2(-18, -34)
			])
			draw_colored_polygon(hair_pts, Color(1.0, 0.84, 0.18))
			draw_polyline(PackedVector2Array([hair_pts[0], hair_pts[1], hair_pts[2], hair_pts[3], hair_pts[4], hair_pts[5], hair_pts[6], hair_pts[7], hair_pts[0]]), Color(1.0, 0.98, 0.65), 2.5)
			draw_line(Vector2(-15, -60), Vector2(35, -45), Color(1.0, 0.96, 0.6), 2.0)
			draw_line(Vector2(-5, -50), Vector2(48, -32), Color(1.0, 0.96, 0.6), 2.0)

			# 5. Executive Aviator Cyber-Visor with Piercing Laser Glare
			draw_circle(Vector2(25, -16), 8.0, Color(0.12, 0.04, 0.08))
			draw_arc(Vector2(25, -16), 8.0, 0, TAU, 18, Color(1.0, 0.85, 0.25), 2.2)
			draw_circle(Vector2(26, -16), 3.5, Color(1.0, 0.18, 0.22))
			draw_circle(Vector2(27, -16), 1.5, Color(1.0, 1.0, 1.0))
			
			draw_circle(Vector2(25, 16), 8.0, Color(0.12, 0.04, 0.08))
			draw_arc(Vector2(25, 16), 8.0, 0, TAU, 18, Color(1.0, 0.85, 0.25), 2.2)
			draw_circle(Vector2(26, 16), 3.5, Color(1.0, 0.18, 0.22))
			draw_circle(Vector2(27, 16), 1.5, Color(1.0, 1.0, 1.0))

			draw_line(Vector2(24, -8), Vector2(24, 8), Color(1.0, 0.85, 0.25), 2.5)
			draw_line(Vector2(20, -18), Vector2(20, 18), Color(1.0, 0.85, 0.25), 2.0)

			# 6. Overhead Upright Boss HP Bar & Imperial Crown (Screen Aligned)
			var bar_pos = up_dir * 115.0
			var bar_half_w = 75.0
			var bar_h = 9.0
			var hp_ratio = clampf(hp / max_hp, 0.0, 1.0)

			draw_line(bar_pos - right_dir * bar_half_w, bar_pos + right_dir * bar_half_w, Color(0.03, 0.06, 0.12, 0.95), bar_h + 4.0)
			draw_line(bar_pos - right_dir * (bar_half_w + 3.0), bar_pos + right_dir * (bar_half_w + 3.0), Color(1.0, 0.84, 0.25, 0.9), 2.0)

			if hp_ratio > 0.001:
				var fill_start = bar_pos - right_dir * bar_half_w
				var fill_end = fill_start + right_dir * (bar_half_w * 2.0 * hp_ratio)
				var bar_col = Color(1.0, 0.82, 0.18) if hp_ratio > 0.30 else Color(1.0, 0.20, 0.25)
				draw_line(fill_start, fill_end, bar_col, bar_h)

			# Imperial 5-Point Crown Floating Overhead
			var crown_c = up_dir * 135.0
			var cr_pts = PackedVector2Array([
				crown_c - right_dir * 22.0,
				crown_c - right_dir * 26.0 + up_dir * 13.0,
				crown_c - right_dir * 13.0 + up_dir * 7.0,
				crown_c + up_dir * 18.0,
				crown_c + right_dir * 13.0 + up_dir * 7.0,
				crown_c + right_dir * 26.0 + up_dir * 13.0,
				crown_c + right_dir * 22.0
			])
			draw_colored_polygon(cr_pts, Color(1.0, 0.84, 0.22))
			draw_polyline(cr_pts, Color(1.0, 1.0, 0.8), 2.2)
			draw_circle(crown_c + up_dir * 18.0, 3.2, Color(1.0, 0.15, 0.25))
			draw_circle(crown_c - right_dir * 26.0 + up_dir * 13.0, 2.4, Color(1.0, 0.15, 0.25))
			draw_circle(crown_c + right_dir * 26.0 + up_dir * 13.0, 2.4, Color(1.0, 0.15, 0.25))

func _physics_process(delta):
	if Global.is_game_over or Global.is_paused:
		return
		
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			queue_redraw()
	elif is_boss:
		queue_redraw()
	
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var to_player = player.global_position - global_position
	var dist_sq = to_player.length_squared()

	# Culling / Despawn logic for off-screen entities
	if is_boss:
		# If boss falls too far behind (e.g. player sprinted 2400px away), relocate near perimeter
		if dist_sq > 2400.0 * 2400.0:
			var re_angle = randf() * TAU
			global_position = player.global_position + Vector2(cos(re_angle), sin(re_angle)) * 800.0
			to_player = player.global_position - global_position
			dist_sq = to_player.length_squared()
	else:
		# Despawn regular enemies that are far outside screen to free memory and unlock spawn cap
		if dist_sq > 2000.0 * 2000.0:
			queue_free()
			return

	var dir = to_player.normalized()
	rotation = lerp_angle(rotation, dir.angle(), 10.0 * delta)
	
	# Handle knockback decay
	knockback = knockback.move_toward(Vector2.ZERO, 1000.0 * delta)
	var hazard_speed = 1.25 if (polarity == Polarity.BEAR and Global.in_bear_hazard) else 1.0
	velocity = dir * (move_speed * Global.enemy_speed_multiplier * hazard_speed) + knockback
	
	move_and_slide()
	
	# Check contact with player
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player"):
			# Check HODL invincibility
			if collider.is_hodl_active:
				take_damage(80.0, -dir * 600.0)
			else:
				Global.take_player_damage(contact_damage * delta * 2.0)
				if polarity == Polarity.BEAR:
					Global.portfolio_return = max(0.0, Global.portfolio_return - 8.0 * delta)
				
	# Ranged attacks for bosses and fake news monsters
	_process_attacks(delta, dir)

func _process_attacks(delta: float, dir: Vector2):
	attack_timer += delta
	match type:
		EnemyType.FAKE_NEWS:
			if attack_timer >= 3.5:
				attack_timer = 0.0
				_fire_projectile(dir, 200.0, ProjectileScript.Type.RUMOR_BULLET, 12.0)
		EnemyType.BEAR_BOSS:
			if attack_timer >= 4.0:
				attack_timer = 0.0
				# Stomp charge!
				knockback = dir * 450.0
		EnemyType.TRUMP_BOSS:
			if attack_timer >= 2.0:
				attack_timer = 0.0
				SoundManager.play_boss_alert()
				# 5-way Tariff Bomb barrage
				for i in range(-2, 3):
					_fire_projectile(dir.rotated(i * 0.22), 320.0, ProjectileScript.Type.TARIFF_BOMB, 24.0)
				# Frequent Truth Social storm tweets
				if randf() > 0.35:
					_fire_projectile(dir.rotated(randf_range(-0.4, 0.4)), 400.0, ProjectileScript.Type.TRUTH_TWEET, 16.0)

func _fire_projectile(fire_dir: Vector2, speed: float, proj_type, damage_val: float):
	var proj = proj_scene.instantiate()
	proj.type = proj_type
	proj.damage = damage_val
	proj.speed = speed
	proj.is_enemy_projectile = true
	proj.global_position = global_position
	proj.direction = fire_dir
	proj.rotation = fire_dir.angle()
	get_parent().add_child(proj)

static var last_damage_text_msec: int = 0
static var last_popup_time_msec: int = 0

func take_damage(amount: float, kb_dir: Vector2 = Vector2.ZERO):
	if is_dead:
		return
	hp -= amount
	flash_timer = 0.08
	queue_redraw()
	knockback = kb_dir * 180.0
	Global.total_damage_dealt += amount
	
	SoundManager.play_hit()
	
	if hp <= 0:
		_die()
	else:
		if is_boss or (randf() < 0.40 and amount > 15.0):
			_spawn_damage_text(amount)

func _spawn_damage_text(amount: float):
	var now = Time.get_ticks_msec()
	if not is_boss and (now - last_damage_text_msec < 35):
		return
	last_damage_text_msec = now

	var label = Label.new()
	label.text = "+%.0f%%" % amount if randf() > 0.3 else "상한가!"
	label.modulate = Color(0.2, 1.0, 0.4) if amount > 30 else Color(1.0, 0.9, 0.2)
	label.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-25, -10))
	label.z_index = 100
	get_parent().call_deferred("add_child", label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -35), 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func _die():
	if is_dead:
		return
	is_dead = true
	
	# Immediately remove from enemy group so player auto-aim targets living enemies
	remove_from_group("enemy")
	
	# Instantly disable all physics collisions & processing to eliminate frame stutter & duplicate hits
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if has_node("HurtArea"):
		$HurtArea.set_deferred("monitoring", false)
		$HurtArea.set_deferred("monitorable", false)
	set_physics_process(false)
	
	Global.kills_count += 1
	SoundManager.play_enemy_death(polarity == Polarity.BULL)
	
	# Polarity Rewards & Penalties:
	# 🔴 BULL (상승/과열) 적 처치: 수익률 대폭 상승 (+3.5% * exp_reward)
	# 🔵 BEAR (하락/공매도) 적 처치: 수익률 하락 손실 (-1.5% * exp_reward)
	if polarity == Polarity.BULL:
		var yield_gain = exp_reward * 3.5
		Global.portfolio_return += yield_gain
		_try_spawn_return_popup("+%.1f%% 떡상!" % yield_gain, Global.get_up_color())
	else:
		var yield_loss = exp_reward * 1.5
		Global.portfolio_return = max(-99.0, Global.portfolio_return - yield_loss)
		_try_spawn_return_popup("-%.1f%% 손실!" % yield_loss, Global.get_down_color())
	
	# Spawn exp gem
	_spawn_exp_gem()
	
	if is_boss:
		if type == EnemyType.TRUMP_BOSS:
			Global.trigger_game_over(true) # Victory!
		else:
			# Mid boss exp explosion
			for i in range(8):
				var extra_gem = gem_scene.instantiate()
				extra_gem.exp_value = 10
				extra_gem.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
				get_parent().call_deferred("add_child", extra_gem)
				
	queue_free()

func _spawn_exp_gem():
	var gem_val = exp_reward * (2 if polarity == Polarity.BULL else 1)
	
	# Only cluster if massive gem flood (> 100 gems on screen) and very close (within 35px)
	var existing_gems = get_tree().get_nodes_in_group("exp_gem")
	if existing_gems.size() > 100:
		for g in existing_gems:
			if is_instance_valid(g) and not g.is_attracted:
				if global_position.distance_squared_to(g.global_position) < 35.0 * 35.0:
					g.exp_value += gem_val
					return
	
	var gem = gem_scene.instantiate()
	gem.exp_value = gem_val
	gem.global_position = global_position
	get_parent().call_deferred("add_child", gem)

func _try_spawn_return_popup(text_str: String, col: Color):
	var now = Time.get_ticks_msec()
	# Fast responsive throttling (35ms = ~28 popups/sec max) so burst kills display clearly
	if not is_boss and (now - last_popup_time_msec < 35):
		return
	last_popup_time_msec = now

	var label = Label.new()
	label.text = text_str
	label.modulate = col
	label.global_position = global_position + Vector2(randf_range(-20, 20), -30)
	label.z_index = 110
	get_parent().call_deferred("add_child", label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -45), 0.75)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.75)
	tween.tween_callback(label.queue_free)
