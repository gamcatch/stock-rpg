extends Area2D

@export var exp_value: int = 2
var speed: float = 0.0
var is_attracted: bool = false
var target_player: Node2D = null

func _ready():
	body_entered.connect(_on_body_entered)

func _draw():
	# Draw glowing green stock coin
	draw_circle(Vector2.ZERO, 7.0, Color(0.2, 0.9, 0.3, 0.9))
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.9, 0.2, 1.0))
	# Draw inner shiny reflection
	draw_circle(Vector2(-1.5, -1.5), 1.5, Color(1.0, 1.0, 0.8))

var cull_timer: float = 0.0

func _process(delta):
	if is_attracted and is_instance_valid(target_player):
		var mag_lvl = Global.skills["liquidity_magnet"]["level"] if Global.skills.has("liquidity_magnet") else 0
		var max_spd = 600.0 + mag_lvl * 150.0
		var accel = 1200.0 + mag_lvl * 350.0
		speed = move_toward(speed, max_spd, accel * delta)
		var dir = (target_player.global_position - global_position).normalized()
		global_position += dir * speed * delta
		return

	# Staggered periodic cull check for abandoned distant gems
	cull_timer += delta
	if cull_timer >= 1.5:
		cull_timer = randf_range(0.0, 0.5)
		var p = target_player if is_instance_valid(target_player) else get_tree().get_first_node_in_group("player")
		if is_instance_valid(p):
			if global_position.distance_squared_to(p.global_position) > 2500.0 * 2500.0:
				queue_free()

func attract_to(player: Node2D):
	target_player = player
	is_attracted = true

func _on_body_entered(body):
	if body.is_in_group("player"):
		Global.add_exp(exp_value)
		SoundManager.play_exp_coin()
		queue_free()
