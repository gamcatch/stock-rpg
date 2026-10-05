extends MainLoop

func _process(delta: float) -> bool:
	print("Headless runtime test starting...")
	var scene = load("res://scenes/main.tscn").instantiate()
	var scene_tree = Engine.get_main_loop() as SceneTree
	if scene_tree:
		scene_tree.root.add_child(scene)
		print("Main scene successfully added to root!")
		
		# Test spawning enemies & leveling up
		Global.add_exp(20)
		print("EXP added, current level: %d" % Global.player_level)
		print("Headless runtime test passed!")
	return true
