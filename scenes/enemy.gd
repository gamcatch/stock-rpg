class_name Enemy
extends CharacterBody2D

enum EnemyType { PANIC_SELL, FAKE_NEWS, RED_CANDLE, BEAR_BOSS, TRUMP_BOSS }
enum Polarity { BULL, BEAR }
enum CharacterArchetype {
	DEFAULT,
	CHIP_GOLEM,       # 반도체 (삼성전자, SK하이닉스, 한미반도체, NVIDIA)
	BATTERY_MECHA,    # 2차전지/배터리 (LG에너지솔루션, 에코프로비엠, 테슬라)
	BIO_CHIMERA,      # 제약바이오 (알테오젠, 삼바, 셀트리온, 일라이릴리)
	AI_ANDROID,       # 로봇 & 빅테크 (두산로보틱스, 레인보우로보, NAVER, 카카오)
	REACTOR_TITAN,    # 전력망 & 원전 (HD현대일렉트릭, 두산에너빌리티, LS일렉트릭)
	DREADNOUGHT,      # K-조선 & 해운 (HD한국조선해양, 한화오션, 삼성중공업)
	GOLD_VAULT,       # 금융 & 밸류업 (KB금융, 신한지주, 메리츠금융지주)
	DEFENSE_MECHA     # K-방산 & 우주항공 (한화에어로스페이스, LIG넥스원, 록히드마틴)
}

const ProjectileScript = preload("res://scenes/projectile.gd")

@export var type: EnemyType = EnemyType.PANIC_SELL
@export var archetype: CharacterArchetype = CharacterArchetype.DEFAULT
@export var polarity: Polarity = Polarity.BULL
@export var max_hp: float = 30.0
@export var move_speed: float = 140.0
@export var contact_damage: float = 12.0
@export var exp_reward: int = 3
@export var is_boss: bool = false

var stock_name: String = ""
var stock_rate: float = 0.0
var hp: float = 30.0
var is_dead: bool = false
var player: Node2D = null
var knockback: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0
var flash_timer: float = 0.0

# 적 말풍선 (Enemy Speech Bubble) 시스템
static var last_enemy_speech_time_msec: int = 0
var speech_bubble: PanelContainer = null
var speech_label: Label = null
var speech_tail: Control = null
var speech_timer: float = 0.0
var is_speech_active: bool = false
var bubble_check_timer: float = 0.0

var gem_scene: PackedScene = preload("res://scenes/exp_gem.tscn")
var proj_scene: PackedScene = preload("res://scenes/projectile.tscn")

func _ready():
	add_to_group("enemy")
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	_setup_stats()
	_setup_speech_bubble()
	# 각 적마다 서로 다른 타이밍에 첫 대사를 검토하도록 1~4초 랜덤 오프셋
	bubble_check_timer = randf_range(1.0, 4.0)

func _exit_tree():
	if is_instance_valid(speech_bubble):
		speech_bubble.queue_free()

func _setup_stats():
	var col_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
	var hurt_shape = $HurtArea/CollisionShape2D if has_node("HurtArea/CollisionShape2D") else null
	var r = 24.0

	if archetype != CharacterArchetype.DEFAULT:
		match archetype:
			CharacterArchetype.CHIP_GOLEM:
				max_hp = 35.0
				move_speed = 120.0
				contact_damage = 7.0
				exp_reward = 16
				r = 26.0
			CharacterArchetype.BATTERY_MECHA:
				max_hp = 30.0
				move_speed = 140.0
				contact_damage = 7.0
				exp_reward = 16
				r = 26.0
			CharacterArchetype.BIO_CHIMERA:
				max_hp = 42.0
				move_speed = 110.0
				contact_damage = 6.0
				exp_reward = 18
				r = 28.0
			CharacterArchetype.AI_ANDROID:
				max_hp = 36.0
				move_speed = 125.0
				contact_damage = 7.0
				exp_reward = 16
				r = 26.0
			CharacterArchetype.REACTOR_TITAN:
				max_hp = 55.0
				move_speed = 95.0
				contact_damage = 10.0
				exp_reward = 22
				r = 30.0
			CharacterArchetype.DREADNOUGHT:
				max_hp = 65.0
				move_speed = 90.0
				contact_damage = 11.0
				exp_reward = 24
				r = 32.0
			CharacterArchetype.GOLD_VAULT:
				max_hp = 48.0
				move_speed = 105.0
				contact_damage = 8.0
				exp_reward = 28
				r = 28.0
			CharacterArchetype.DEFENSE_MECHA:
				max_hp = 40.0
				move_speed = 130.0
				contact_damage = 8.0
				exp_reward = 18
				r = 28.0
		hp = max_hp
	else:
		match type:
			EnemyType.PANIC_SELL:
				max_hp = 20.0
				move_speed = 135.0
				contact_damage = 6.0
				exp_reward = 8
				r = 24.0
			EnemyType.FAKE_NEWS:
				max_hp = 45.0
				move_speed = 110.0
				contact_damage = 9.0
				exp_reward = 18
				r = 28.0
			EnemyType.RED_CANDLE:
				max_hp = 85.0
				move_speed = 85.0
				contact_damage = 14.0
				exp_reward = 36
				r = 34.0
			EnemyType.BEAR_BOSS:
				max_hp = 650.0
				move_speed = 95.0
				contact_damage = 22.0
				exp_reward = 160
				is_boss = true
				r = 60.0
			EnemyType.TRUMP_BOSS:
				max_hp = 2500.0
				move_speed = 80.0
				contact_damage = 32.0
				exp_reward = 1000
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
		draw_circle(Vector2.ZERO, 34.0, Color(1.0, 1.0, 1.0, 0.9))
		return

	# Single cohesive theme color based on stock market polarity
	# 🔴 Red: Bull / Surge (떡상/과열)
	# 🔵 Blue: Bear / Short-selling / Panic Drop (하락/공매도)
	var is_bull = (polarity == Polarity.BULL)
	var theme_color = Color(0.95, 0.22, 0.25) if is_bull else Color(0.20, 0.55, 1.0)
	var glow_color = Color(0.95, 0.22, 0.25, 0.25) if is_bull else Color(0.20, 0.55, 1.0, 0.25)
	var rim_color = Color(1.0, 0.55, 0.55) if is_bull else Color(0.65, 0.88, 1.0)

	# 1. Subtle soft footprint glow
	draw_circle(Vector2.ZERO, 28.0, glow_color)
	var font = ThemeDB.fallback_font

	# 2. Check if this is a Characterized Stock Entity (종목 캐릭터화 렌더링)
	if archetype != CharacterArchetype.DEFAULT:
		match archetype:
			CharacterArchetype.CHIP_GOLEM:
				_draw_chip_golem(theme_color, rim_color, is_bull, font)
			CharacterArchetype.BATTERY_MECHA:
				_draw_battery_mecha(theme_color, rim_color, is_bull, font)
			CharacterArchetype.BIO_CHIMERA:
				_draw_bio_chimera(theme_color, rim_color, is_bull, font)
			CharacterArchetype.AI_ANDROID:
				_draw_ai_android(theme_color, rim_color, is_bull, font)
			CharacterArchetype.REACTOR_TITAN:
				_draw_reactor_titan(theme_color, rim_color, is_bull, font)
			CharacterArchetype.DREADNOUGHT:
				_draw_dreadnought(theme_color, rim_color, is_bull, font)
			CharacterArchetype.GOLD_VAULT:
				_draw_gold_vault(theme_color, rim_color, is_bull, font)
			CharacterArchetype.DEFENSE_MECHA:
				_draw_defense_mecha(theme_color, rim_color, is_bull, font)
		_draw_stock_badge_and_hp(is_bull, font)
		return

	# 3. Default Enemy Types (Panic Sell, Fake News, Red Candle, Bosses)
	_draw_stock_badge_and_hp(is_bull, font)

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
		
	_process_speech_bubble(delta)
		
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
				Global.take_player_damage(contact_damage)
				if polarity == Polarity.BEAR:
					Global.portfolio_return = max(0.0, Global.portfolio_return - 0.1 * delta)
				
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
	label.text = "-%.0f" % amount if amount <= 30.0 else "CRIT -%.0f" % amount
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
	
	# Polarity Rewards:
	# 🔴 BULL (상승/과열) 적 처치: 상승 랠리 수익 (+0.04% * exp_reward)
	# 🔵 BEAR (하락/공매도) 적 처치: 공매도 숏스퀴즈/방어 성공 (+0.02% * exp_reward)
	if polarity == Polarity.BULL:
		var yield_gain = exp_reward * 0.04
		Global.portfolio_return += yield_gain
		if randf() < 0.25 or is_boss:
			_try_spawn_return_popup("+%.2f%% 떡상!" % yield_gain, Global.get_up_color())
	else:
		var yield_gain = exp_reward * 0.02
		Global.portfolio_return += yield_gain
		if randf() < 0.25 or is_boss:
			_try_spawn_return_popup("+%.2f%% 숏커버링!" % yield_gain, Global.get_down_color())
	
	# Spawn exp gem
	_spawn_exp_gem()
	
	if is_boss:
		if type == EnemyType.TRUMP_BOSS:
			# 방치형 RPG: 보스 처치 시 종료되지 않고 축제 보상 및 무한 랠리 지속!
			Global.market_event_triggered.emit("🏆 [보스 격파!] 관세맨 TRUMP 격파!", "관세 장벽 돌파 완료! 글로벌 강세장 랠리가 계속 이어집니다!")
			SoundManager.play_level_up()
			LeaderboardManager.unlock_achievement("trump_slayer")
			Global.heal_player(Global.player_max_hp)
			Global.portfolio_return += 2.0
			Global.emergency_bailouts = min(3, Global.emergency_bailouts + 1)
			
			for i in range(16):
				var extra_gem = gem_scene.instantiate()
				extra_gem.exp_value = 15
				extra_gem.global_position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
				get_parent().call_deferred("add_child", extra_gem)
		else:
			# Mid boss exp explosion
			SoundManager.play_level_up()
			Global.portfolio_return += 0.8
			Global.heal_player(Global.player_max_hp * 0.4)
			for i in range(8):
				var extra_gem = gem_scene.instantiate()
				extra_gem.exp_value = 10
				extra_gem.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
				get_parent().call_deferred("add_child", extra_gem)
				
	if is_instance_valid(speech_bubble):
		speech_bubble.queue_free()
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

# ------------------------------------------------------------------------------
# 💬 적 말풍선 시스템 (Enemy Random Speech Bubble System)
# ------------------------------------------------------------------------------
func _setup_speech_bubble():
	speech_bubble = PanelContainer.new()
	speech_bubble.top_level = true
	speech_bubble.z_index = 120
	speech_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb = StyleBoxFlat.new()
	var is_bull = (polarity == Polarity.BULL)
	var border_col = Color(1.0, 0.35, 0.35, 0.95) if is_bull else Color(0.35, 0.75, 1.0, 0.95)
	if is_boss:
		border_col = Color(1.0, 0.85, 0.25, 0.95)
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.92)
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 6
	speech_bubble.add_theme_stylebox_override("panel", sb)
	
	speech_label = Label.new()
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech_label.add_theme_font_size_override("font_size", 18) # 18pt로 시원하고 또렷하게!
	speech_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.90))
	speech_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	speech_label.add_theme_constant_override("shadow_offset_x", 1)
	speech_label.add_theme_constant_override("shadow_offset_y", 1)
	speech_bubble.add_child(speech_label)
	
	speech_tail = Control.new()
	speech_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech_tail.draw.connect(func():
		var pts = PackedVector2Array([
			Vector2(-6, 0),
			Vector2(6, 0),
			Vector2(0, 7)
		])
		speech_tail.draw_colored_polygon(pts, border_col)
	)
	speech_bubble.add_child(speech_tail)
	
	speech_bubble.modulate.a = 0.0
	add_child(speech_bubble)

func say_bubble(text: String, duration: float = 3.0):
	if not is_instance_valid(speech_bubble) or not is_instance_valid(speech_label):
		return
	speech_label.text = text
	speech_bubble.reset_size()
	speech_bubble.pivot_offset = speech_bubble.size * 0.5
	is_speech_active = true
	speech_timer = duration
	
	speech_bubble.scale = Vector2(0.85, 0.85)
	var tw = create_tween()
	tw.tween_property(speech_bubble, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(speech_bubble, "scale", Vector2(1.05, 1.05), 0.12)
	tw.tween_property(speech_bubble, "scale", Vector2(1.0, 1.0), 0.1)

func _process_speech_bubble(delta: float):
	if not is_instance_valid(speech_bubble):
		return
		
	# 적 머리 위에 수평 고정 (노드 회전 무시)
	var b_size = speech_bubble.size
	speech_bubble.global_position = global_position - Vector2(b_size.x * 0.5, b_size.y + 45.0)
	speech_bubble.rotation = 0.0
	if is_instance_valid(speech_tail):
		speech_tail.position = Vector2(b_size.x * 0.5, b_size.y - 1.0)
		speech_tail.queue_redraw()
		
	if is_speech_active:
		speech_timer -= delta
		if speech_timer <= 0.0:
			is_speech_active = false
			var tw = create_tween()
			tw.tween_property(speech_bubble, "modulate:a", 0.0, 0.3)
			tw.parallel().tween_property(speech_bubble, "scale", Vector2(0.9, 0.9), 0.3)
	else:
		# 침묵 중일 때 랜덤 확률로 대사 발동 검사
		bubble_check_timer -= delta
		if bubble_check_timer <= 0.0:
			bubble_check_timer = randf_range(3.5, 6.5)
			_maybe_trigger_speech()

func _maybe_trigger_speech():
	if is_dead or not is_instance_valid(player):
		return
	# 화면 안 혹은 플레이어와 750px 이내에 있을 때만 대사 출력
	if global_position.distance_to(player.global_position) > 750.0:
		return
	var now = Time.get_ticks_msec()
	# 화면 전체에서 적들이 동시에 떠들지 않도록 글로벌 1.8초 쿨다운
	if not is_boss and (now - last_enemy_speech_time_msec < 1800):
		return
	# 보스는 50% 확률, 일반 적은 18% 확률로 대사 발동
	var chance = 0.50 if is_boss else 0.18
	if randf() > chance:
		return
	last_enemy_speech_time_msec = now
	
	var lines = []
	if is_boss:
		if type == EnemyType.TRUMP_BOSS:
			lines = [
				"🇺🇸 100% 관세 폭탄 맛 좀 봐라!",
				"📢 가짜 뉴스는 절대 용납 못 해!",
				"🦅 Make America Great Again!",
				"💥 시장은 내가 움직인다!"
			]
		else:
			lines = [
				"🐻 하락장의 공포를 느껴라!",
				"❄️ 전부 공매도로 밀어버리겠다!",
				"📉 여기가 네 무덤이다, 개미야!"
			]
	elif archetype != CharacterArchetype.DEFAULT:
		var name_prefix = "[%s]" % stock_name if not stock_name.is_empty() else ""
		match archetype:
			CharacterArchetype.CHIP_GOLEM:
				lines = [
					"%s 웨이퍼를 사수하라!" % name_prefix,
					"⚡ HBM 반도체 풀가동!",
					"🦾 나노 공정의 위력을 봐라!"
				]
			CharacterArchetype.BATTERY_MECHA:
				lines = [
					"%s 2차전지 방전 불가!" % name_prefix,
					"🔋 리튬 에너지 100% 충전!",
					"⚡ 배터리 화력 맛 좀 봐라!"
				]
			CharacterArchetype.BIO_CHIMERA:
				lines = [
					"%s 임상 3상 완료!" % name_prefix,
					"🧬 바이오 시밀러의 역습!",
					"🧪 신약 파이프라인 가동!"
				]
			CharacterArchetype.AI_ANDROID:
				lines = [
					"%s AI 연산 과열 중!" % name_prefix,
					"🤖 알고리즘이 네 패배를 계산했다!",
					"💡 딥러닝 텐서 폭격!"
				]
			CharacterArchetype.REACTOR_TITAN:
				lines = [
					"%s 원전 출력 200%!",
					"⚡ 초고압 전력망 과부하!",
					"🔥 에너지 대란을 일으켜주마!"
				]
			CharacterArchetype.DREADNOUGHT:
				lines = [
					"%s 전함 주포 일제 발포!",
					"⚓ 수주 대박의 물결이다!",
					"🌊 대양을 지배하는 K-조선!"
				]
			CharacterArchetype.GOLD_VAULT:
				lines = [
					"%s 밸류업 금고를 열어라!",
					"💰 배당금 방어막 발동!",
					"🏦 자사주 소각 맛을 봐라!"
				]
			CharacterArchetype.DEFENSE_MECHA:
				lines = [
					"%s 미사일 록온 완료!",
					"🚀 K-방산 수출 대박!",
					"🎯 타겟 조준... 발사!"
				]
	else:
		if polarity == Polarity.BULL:
			lines = [
				"📈 오늘 상한가 간다!",
				"🚀 불기둥 뚫고 가즈아~!",
				"🔥 물타기 금지! 풀매수다!"
			]
		else:
			lines = [
				"📉 공매도 폭탄 투하!",
				"😱 패닉셀이다! 던져라!",
				"❄️ 파란불의 공포를 봐라!"
			]
	say_bubble(lines.pick_random(), randf_range(2.5, 3.2))

# ------------------------------------------------------------------------------
# 🎮 종목별 RPG 캐릭터 렌더링 시스템 (Stock Character Renderers)
# ------------------------------------------------------------------------------
func _draw_stock_badge_and_hp(_is_bull: bool, font: Font):
	if stock_name.is_empty():
		return
	var sign_str = "▲+" if stock_rate >= 0 else "▼"
	var rate_abs = abs(stock_rate)
	var text_str = "%s %s%.1f%%" % [stock_name, sign_str, rate_abs] if rate_abs > 0.0 else stock_name
	var badge_col = Global.get_up_color() if stock_rate >= 0 else Global.get_down_color()
	
	# Node 회전 상쇄하여 수평 유지 및 크고 또렷하게 표시 (폰트 18pt)
	var badge_offset = Vector2(0, -48).rotated(-rotation)
	var badge_w = clampf(text_str.length() * 19.0 + 26.0, 130.0, 280.0)
	var badge_rect = Rect2(badge_offset + Vector2(-badge_w * 0.5, -14), Vector2(badge_w, 28))
	
	draw_rect(badge_rect, Color(0.04, 0.08, 0.16, 0.92), true)
	draw_rect(badge_rect, badge_col, false, 2.0)
	draw_string(font, badge_offset + Vector2(-badge_w * 0.5, 6), text_str, HORIZONTAL_ALIGNMENT_CENTER, badge_w, 18, badge_col)
	
	# Mini HP Bar
	var hp_ratio = clampf(hp / max(1.0, max_hp), 0.0, 1.0)
	var hp_w = 52.0
	var hp_rect = Rect2(badge_offset + Vector2(-hp_w * 0.5, 18), Vector2(hp_w, 6))
	draw_rect(hp_rect, Color(0.08, 0.08, 0.12, 0.85), true)
	var hp_col = Color(0.2, 1.0, 0.4) if hp_ratio > 0.35 else Color(1.0, 0.25, 0.25)
	draw_rect(Rect2(hp_rect.position, Vector2(hp_w * hp_ratio, 6)), hp_col, true)
	draw_rect(hp_rect, Color(0.35, 0.6, 0.85, 0.6), false, 1.2)

# 1. 반도체 실리콘 칩 골렘 (삼성전자, SK하이닉스, NVIDIA 등)
func _draw_chip_golem(theme_color: Color, rim_color: Color, _is_bull: bool, _font: Font):
	var t = Global.game_time
	# A. Hexagonal Silicon Wafer Halo (헤드 뒤에서 회전하는 웨이퍼 링)
	var halo_rot = t * 2.0
	draw_arc(Vector2.ZERO, 34.0, halo_rot, halo_rot + TAU, 24, Color(0.3, 0.8, 1.0, 0.4), 1.8)
	for i in range(6):
		var wa_ang = halo_rot + i * (TAU / 6.0)
		draw_line(Vector2.ZERO, Vector2(cos(wa_ang), sin(wa_ang)) * 34.0, Color(0.3, 0.8, 1.0, 0.25), 1.2)
		
	# B. Square Processor Core (마이크로칩 본체)
	var core_rect = Rect2(-20, -20, 40, 40)
	draw_rect(core_rect, Color(0.06, 0.12, 0.22), true)
	draw_rect(core_rect, rim_color, false, 2.4)
	
	# C. Golden Pin Connectors (4방향 골드 핀 렉)
	for i in range(-14, 18, 8):
		draw_line(Vector2(i, -20), Vector2(i, -27), Color(1.0, 0.85, 0.25), 2.5)
		draw_line(Vector2(i, 20), Vector2(i, 27), Color(1.0, 0.85, 0.25), 2.5)
		draw_line(Vector2(-20, i), Vector2(-27, i), Color(1.0, 0.85, 0.25), 2.5)
		draw_line(Vector2(20, i), Vector2(27, i), Color(1.0, 0.85, 0.25), 2.5)
		
	# D. Central HBM Die & PCB Traces
	draw_rect(Rect2(-10, -10, 20, 20), theme_color, true)
	draw_rect(Rect2(-10, -10, 20, 20), Color(1.0, 1.0, 1.0), false, 1.5)
	
	# E. Piercing Laser Glare Visor Eye
	draw_line(Vector2(10, -5), Vector2(24, 0), theme_color, 3.5)
	draw_line(Vector2(10, 5), Vector2(24, 0), theme_color, 3.5)
	draw_circle(Vector2(24, 0), 3.0, Color(1, 1, 1))

# 2. 2차전지 배터리 메카 (LG에너지솔루션, 에코프로비엠, Tesla 등)
func _draw_battery_mecha(_theme_color: Color, rim_color: Color, _is_bull: bool, _font: Font):
	var t = Global.game_time
	# A. Dual Cylindrical Lithium-ion Battery Cells
	var cell_w = 18.0
	var cell_h = 36.0
	var c1 = Rect2(-24, -18, cell_w, cell_h)
	var c2 = Rect2(6, -18, cell_w, cell_h)
	draw_rect(c1, Color(0.08, 0.14, 0.24), true)
	draw_rect(c1, rim_color, false, 2.0)
	draw_rect(c2, Color(0.08, 0.14, 0.24), true)
	draw_rect(c2, rim_color, false, 2.0)
	
	# Positive (+) Metal Terminals on top
	draw_rect(Rect2(-18, -24, 6, 6), Color(0.9, 0.92, 1.0), true)
	draw_rect(Rect2(12, -24, 6, 6), Color(0.9, 0.92, 1.0), true)
	
	# B. Crackling High-Voltage Electric Discharge Arc between cells
	var spark_y = sin(t * 22.0) * 12.0
	draw_line(Vector2(-6, spark_y), Vector2(6, -spark_y), Color(1.0, 0.95, 0.4), 2.5)
	draw_circle(Vector2(0, 0), 4.5, Color(1.0, 0.85, 0.2))
	
	# C. Lightning Bolt Emblem on Chest
	var bolt = PackedVector2Array([
		Vector2(2, -14), Vector2(-8, 0), Vector2(-1, 0),
		Vector2(-4, 14), Vector2(6, -2), Vector2(-1, -2)
	])
	draw_colored_polygon(bolt, Color(1.0, 0.88, 0.2))
	draw_polyline(bolt, Color(1.0, 1.0, 1.0), 1.5)

# 3. 제약바이오 나노 키메라 (알테오젠, 삼바, 셀트리온, Eli Lilly 등)
func _draw_bio_chimera(theme_color: Color, rim_color: Color, _is_bull: bool, _font: Font):
	var t = Global.game_time
	# A. Double-Helix DNA Strands on Flanks
	for i in range(-3, 4):
		var y = i * 8.0
		var x_wave = sin(t * 5.0 + i * 0.8) * 12.0
		draw_circle(Vector2(-24 + x_wave, y), 3.0, Color(0.2, 0.95, 0.65))
		draw_circle(Vector2(24 - x_wave, y), 3.0, Color(0.3, 0.8, 1.0))
		draw_line(Vector2(-24 + x_wave, y), Vector2(24 - x_wave, y), Color(0.25, 0.9, 0.7, 0.35), 1.5)
		
	# B. Bioluminescent Cellular Spirit Body (중심 구체)
	draw_circle(Vector2.ZERO, 18.0, Color(0.06, 0.16, 0.22, 0.92))
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 24, rim_color, 2.2)
	draw_circle(Vector2.ZERO, 10.0, theme_color)
	draw_circle(Vector2(4, -4), 4.0, Color(1, 1, 1))

# 4. 로봇/AI 사이버 안드로이드 (두산로보틱스, 레인보우로보, NAVER 등)
func _draw_ai_android(_theme_color: Color, rim_color: Color, _is_bull: bool, _font: Font):
	var t = Global.game_time
	# A. Articulated Industrial Robot Arm on Sides
	var arm_swing = sin(t * 8.0) * 8.0
	draw_line(Vector2(-16, -10), Vector2(-28, -20 + arm_swing), Color(0.7, 0.75, 0.85), 4.0)
	draw_line(Vector2(-28, -20 + arm_swing), Vector2(-36, -14 + arm_swing), Color(1.0, 0.8, 0.2), 3.0)
	draw_line(Vector2(-16, 10), Vector2(-28, 20 - arm_swing), Color(0.7, 0.75, 0.85), 4.0)
	draw_line(Vector2(-28, 20 - arm_swing), Vector2(-36, 14 - arm_swing), Color(1.0, 0.8, 0.2), 3.0)
	
	# B. Sleek Octagonal Mecha Head & Torso
	var torso_pts = PackedVector2Array([
		Vector2(-16, -16), Vector2(12, -18), Vector2(24, 0),
		Vector2(12, 18), Vector2(-16, 16), Vector2(-22, 0)
	])
	draw_colored_polygon(torso_pts, Color(0.10, 0.12, 0.20))
	draw_polyline(torso_pts, rim_color, 2.4)
	
	# C. Floating Holographic 3D Data Cube over head
	var cube_y = -34.0 + sin(t * 4.0) * 4.0
	draw_rect(Rect2(-8, cube_y - 8, 16, 16), Color(0.8, 0.3, 1.0, 0.25), true)
	draw_rect(Rect2(-8, cube_y - 8, 16, 16), Color(0.85, 0.4, 1.0), false, 1.8)
	# Neural eye sensor array
	draw_circle(Vector2(14, -6), 3.5, Color(0.85, 0.35, 1.0))
	draw_circle(Vector2(14, 6), 3.5, Color(0.85, 0.35, 1.0))
	draw_circle(Vector2(20, 0), 4.0, Color(1, 1, 1))

# 5. 전력망/원전 아크 타이탄 (HD현대일렉트릭, 두산에너빌리티, LS일렉트릭 등)
func _draw_reactor_titan(_theme_color: Color, rim_color: Color, _is_bull: bool, _font: Font):
	var t = Global.game_time
	# A. Ceramic High-Voltage Insulator Ribs (변압기 애자)
	for i in range(3):
		var ix = -28.0 - i * 6.0
		draw_line(Vector2(ix, -16), Vector2(ix, 16), Color(0.4, 0.7, 0.95), 3.5)
		
	# B. Heavy Spherical Containment Armor
	draw_circle(Vector2.ZERO, 26.0, Color(0.08, 0.12, 0.22))
	draw_arc(Vector2.ZERO, 26.0, 0, TAU, 28, rim_color, 2.5)
	
	# C. Spinning Electron Orbital Energy Rings
	var r_ang = t * 3.5
	draw_arc(Vector2.ZERO, 34.0, r_ang, r_ang + PI, 16, Color(0.2, 0.85, 1.0, 0.8), 2.0)
	draw_arc(Vector2.ZERO, 34.0, r_ang + PI * 0.5, r_ang + PI * 1.5, 16, Color(1.0, 0.85, 0.2, 0.8), 2.0)
	
	# D. Glowing Cherenkov Arc Reactor Core
	draw_circle(Vector2.ZERO, 13.0, Color(0.2, 0.75, 1.0))
	draw_circle(Vector2.ZERO, 7.0, Color(1, 1, 1))

# 6. K-조선/해운 철갑 드레드노트 (HD한국조선해양, 한화오션, 삼성중공업 등)
func _draw_dreadnought(theme_color: Color, rim_color: Color, _is_bull: bool, _font: Font):
	var t = Global.game_time
	# A. Twin Marine Bronze Screw Propellers Spinning at Stern
	var p_rot = t * 14.0
	draw_line(Vector2(-32, -14), Vector2(-32 + cos(p_rot) * 9.0, -14 + sin(p_rot) * 9.0), Color(0.9, 0.7, 0.2), 3.0)
	draw_line(Vector2(-32, 14), Vector2(-32 + cos(-p_rot) * 9.0, 14 + sin(-p_rot) * 9.0), Color(0.9, 0.7, 0.2), 3.0)
	
	# B. Armored Warship Wedge Prow (철갑 함선 선수 형태)
	var hull_pts = PackedVector2Array([
		Vector2(32, 0),      # Sharp cutwater prow
		Vector2(14, -20),
		Vector2(-26, -20),
		Vector2(-32, 0),
		Vector2(-26, 20),
		Vector2(14, 20)
	])
	draw_colored_polygon(hull_pts, Color(0.07, 0.12, 0.22))
	draw_polyline(hull_pts, rim_color, 2.5)
	
	# C. Riveted Armored Plating & Twin Naval Anchor Claws
	draw_line(Vector2(6, -20), Vector2(16, -30), Color(0.8, 0.85, 0.95), 3.0)
	draw_line(Vector2(16, -30), Vector2(22, -26), Color(0.8, 0.85, 0.95), 3.0)
	draw_line(Vector2(6, 20), Vector2(16, 30), Color(0.8, 0.85, 0.95), 3.0)
	draw_line(Vector2(16, 30), Vector2(22, 26), Color(0.8, 0.85, 0.95), 3.0)
	
	# D. Central Conning Tower Visor
	draw_rect(Rect2(-6, -8, 16, 16), theme_color, true)
	draw_circle(Vector2(16, 0), 4.0, Color(1, 1, 1))

# 7. 금융/밸류업 골든 볼트 가디언 (KB금융, 신한지주, 메리츠금융 등)
func _draw_gold_vault(_theme_color: Color, _rim_color: Color, _is_bull: bool, _font: Font):
	var t = Global.game_time
	# A. Swept Wall Street Golden Bull Horns
	var horn_l = PackedVector2Array([Vector2(-4, -18), Vector2(8, -32), Vector2(24, -30), Vector2(10, -22)])
	draw_colored_polygon(horn_l, Color(1.0, 0.84, 0.2))
	draw_polyline(horn_l, Color(1.0, 0.95, 0.6), 2.0)
	var horn_r = PackedVector2Array([Vector2(-4, 18), Vector2(8, 32), Vector2(24, 30), Vector2(10, 22)])
	draw_colored_polygon(horn_r, Color(1.0, 0.84, 0.2))
	draw_polyline(horn_r, Color(1.0, 0.95, 0.6), 2.0)
	
	# B. Heavy Square Safe Vault Body
	var vault_box = Rect2(-20, -20, 40, 40)
	draw_rect(vault_box, Color(0.12, 0.10, 0.05), true)
	draw_rect(vault_box, Color(1.0, 0.82, 0.25), false, 2.6)
	
	# C. Golden Combination Lock Dial in Center
	var dial_rot = t * 3.0
	draw_circle(Vector2.ZERO, 12.0, Color(0.2, 0.16, 0.08))
	draw_arc(Vector2.ZERO, 12.0, 0, TAU, 20, Color(1.0, 0.88, 0.3), 2.2)
	for i in range(4):
		var spoke_a = dial_rot + i * (TAU / 4.0)
		draw_line(Vector2.ZERO, Vector2(cos(spoke_a), sin(spoke_a)) * 10.0, Color(1.0, 0.9, 0.4), 2.0)
	draw_circle(Vector2.ZERO, 3.5, Color(1.0, 1.0, 1.0))

# 8. K-방산/우주항공 델타 요격 메카 (한화에어로스페이스, LIG넥스원, 록히드마틴 등)
func _draw_defense_mecha(_theme_color: Color, rim_color: Color, _is_bull: bool, _font: Font):
	var t = Global.game_time
	# A. Swept Stealth Delta Wings & Missile Pods
	var delta_wings = PackedVector2Array([
		Vector2(28, 0),       # Stealth Nose Tip
		Vector2(-8, -28),     # Left wing tip
		Vector2(-24, -26),    # Left trailing edge
		Vector2(-14, 0),      # Center engine notch
		Vector2(-24, 26),     # Right trailing edge
		Vector2(-8, 28)       # Right wing tip
	])
	draw_colored_polygon(delta_wings, Color(0.08, 0.12, 0.18))
	draw_polyline(delta_wings, rim_color, 2.4)
	
	# Twin Missile Pods on Wing Rails
	draw_rect(Rect2(-12, -26, 16, 5), Color(1.0, 0.4, 0.2), true)
	draw_rect(Rect2(-12, 21, 16, 5), Color(1.0, 0.4, 0.2), true)
	
	# Twin Afterburner Cones with Flame Pulse
	var flame_len = 8.0 + sin(t * 30.0) * 4.0
	draw_line(Vector2(-16, -7), Vector2(-16 - flame_len, -7), Color(1.0, 0.6, 0.1), 3.0)
	draw_line(Vector2(-16, 7), Vector2(-16 - flame_len, 7), Color(1.0, 0.6, 0.1), 3.0)
	
	# HUD Targeting Crosshair Eye
	draw_circle(Vector2(14, 0), 4.0, Color(1.0, 0.3, 0.3))
	draw_line(Vector2(8, 0), Vector2(20, 0), Color(1, 1, 1), 1.5)
	draw_line(Vector2(14, -6), Vector2(14, 6), Color(1, 1, 1), 1.5)
