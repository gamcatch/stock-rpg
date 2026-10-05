extends CanvasLayer

@onready var card_container: VBoxContainer = $Control/Panel/CardContainer
@onready var title_label: Label = $Control/Panel/TitleLabel

var pending_level_ups: int = 0
var auto_pick_timer: float = 3.5
var current_level_shown: int = 1
var is_selection_in_progress: bool = false

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	Global.level_up.connect(_on_level_up)

func _process(delta):
	if visible and Global.auto_play_enabled and not is_selection_in_progress:
		auto_pick_timer -= delta
		if auto_pick_timer <= 0.0:
			auto_pick_timer = 3.5
			_auto_pick_card()
		else:
			title_label.text = "📈 투자 전략 매수 (Lv. %d)  [🤖 %d초 후 자동선택]" % [current_level_shown, int(ceil(auto_pick_timer))]

func _auto_pick_card():
	if is_selection_in_progress:
		return
	if card_container.get_child_count() > 0:
		var first_card = card_container.get_child(0)
		if first_card is Button:
			first_card.emit_signal("pressed")

func _on_level_up(new_level: int):
	pending_level_ups += 1
	if not visible:
		_show_level_up_screen(new_level)

func _show_level_up_screen(level_to_show: int):
	SoundManager.play_level_up()
	get_tree().paused = true
	visible = true
	is_selection_in_progress = false
	current_level_shown = level_to_show
	auto_pick_timer = 3.5
	
	# Check if all main skills are maxed
	var pool: Array = []
	for skill_id in Global.skills.keys():
		var info = Global.skills[skill_id]
		if info["level"] < info["max_level"]:
			pool.append(skill_id)
			
	if pool.is_empty():
		title_label.text = "👑 [전략 완성] 특별 배당금 & 차익 실현 (Lv. %d)" % level_to_show
		title_label.modulate = Color(1.0, 0.9, 0.2)
	else:
		title_label.text = "📈 투자 전략 매수 (Lv. %d)" % level_to_show
		title_label.modulate = Color(0.2, 1.0, 0.4)
		
	_generate_choices(pool)

func _generate_choices(skill_pool: Array):
	for child in card_container.get_children():
		child.queue_free()
		
	skill_pool.shuffle()
	var skill_count = min(3, skill_pool.size())
	
	for i in range(skill_count):
		var skill_id = skill_pool[i]
		var info = Global.skills[skill_id]
		var card = _create_card(skill_id, info)
		card_container.add_child(card)
		
	# Fill remaining choices up to 3 with repeatable Bonus/Dividend cards!
	if skill_count < 3:
		var bonus_cards = _get_bonus_cards()
		bonus_cards.shuffle()
		var needed = 3 - skill_count
		for i in range(min(needed, bonus_cards.size())):
			var b_info = bonus_cards[i]
			var card = _create_bonus_card(b_info)
			card_container.add_child(card)

	# Failsafe: if for any unexpected reason card_container has no children, add an emergency resume card!
	if card_container.get_child_count() == 0:
		var fallback_btn = Button.new()
		fallback_btn.custom_minimum_size = Vector2(840, 240)
		fallback_btn.text = "💰 [특별 배당금 수령]\n체력 50% 회복 & 수익률 +50% 획득\n\n[ 👆 터치하여 계속하기 ]"
		fallback_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback_btn.add_theme_font_size_override("font_size", 32)
		fallback_btn.pressed.connect(func():
			_highlight_and_select(fallback_btn, func():
				Global.heal_player(Global.player_max_hp * 0.5)
				Global.portfolio_return += 50.0
				_finish_choice()
			, "특별 배당금 수령")
		)
		card_container.add_child(fallback_btn)

func _create_card(skill_id: String, info: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(840, 260)
	
	var cur_lvl = info["level"]
	var next_lvl = cur_lvl + 1
	var action_text = "신규 매수" if cur_lvl == 0 else "Lv. %d ➔ Lv. %d" % [cur_lvl, next_lvl]
	
	btn.text = "%s %s  [%s]\n\n%s\n\n[ 👆 터치하여 즉시 체결! ]" % [info["icon"], info["name"], action_text, info["desc"]]
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", 30)
	
	btn.pressed.connect(func():
		_highlight_and_select(btn, func(): _select_upgrade(skill_id), "%s %s (%s)" % [info["icon"], info["name"], action_text])
	)
	return btn

func _create_bonus_card(bonus_info: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(840, 260)
	
	btn.text = "%s %s  [%s]\n\n%s\n\n[ 👆 터치하여 보너스 수령! ]" % [
		bonus_info["icon"], bonus_info["name"], bonus_info["action_text"], bonus_info["desc"]
	]
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", 30)
	
	btn.pressed.connect(func():
		_highlight_and_select(btn, func():
			_apply_bonus(bonus_info["id"])
			_finish_choice()
		, "%s %s" % [bonus_info["icon"], bonus_info["name"]])
	)
	return btn

func _highlight_and_select(card_btn: Button, callback: Callable, card_title: String):
	if is_selection_in_progress:
		return
	is_selection_in_progress = true
	
	SoundManager.play_level_up()
	SoundManager.haptic_impact()
	
	# 선택된 카드는 황금빛 네온으로 강조하고, 나머지 카드는 반투명 페이드아웃!
	for child in card_container.get_children():
		if child is Button:
			if child == card_btn:
				child.modulate = Color(1.3, 1.25, 0.45) # 황금빛 네온 발광
				var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tween.tween_property(child, "scale", Vector2(1.04, 1.04), 0.15)
				tween.tween_property(child, "scale", Vector2(1.0, 1.0), 0.15)
			else:
				var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tween.tween_property(child, "modulate:a", 0.25, 0.2)
				
	# 상단 타이틀 배너에 체결된 전략 공지
	title_label.text = "✅ [투자 전략 체결] %s" % card_title
	title_label.modulate = Color(1.0, 0.88, 0.2)
	
	# 실시간 증시 속보 티커로도 체결 타전
	Global.market_event_triggered.emit("📈 [전략 매수 체결]", "%s 전략 매수 완료!" % card_title)
	
	# 유저가 어떤 카드가 선택되었는지 충분히 볼 수 있도록 0.85초간 하이라이트 유지!
	var timer = get_tree().create_timer(0.85, true, false, true)
	await timer.timeout
	
	callback.call()

func _get_bonus_cards() -> Array:
	return [
		{
			"id": "dividend_payout",
			"icon": "💰",
			"name": "특별 현금 배당금",
			"action_text": "즉시 수령",
			"desc": "보유 포트폴리오에서 현금 배당금 지급!\nHP +50% 즉시 회복 & 포트폴리오 수익률 +50%"
		},
		{
			"id": "short_squeeze",
			"icon": "💥",
			"name": "공매도 강제 청산 (숏스퀴즈)",
			"action_text": "전체 마진콜",
			"desc": "공매도 세력에 강제 마진콜 폭격!\n화면 전체의 모든 적에게 300 광역 피해"
		},
		{
			"id": "compound_growth",
			"icon": "🚀",
			"name": "복리 마법 가속",
			"action_text": "영구 강화",
			"desc": "워렌 버핏의 복리 마법 발동!\n모든 공격력 +15% & 이동 속도 +10% 영구 상승"
		},
		{
			"id": "profit_taking_rally",
			"icon": "☕",
			"name": "차익 실현 랠리",
			"action_text": "무적 & 젬 진공",
			"desc": "수익을 안전하게 확정!\n6초간 절대 무적 및 맵 전체 젬을 플레이어에게 즉시 흡입"
		}
	]

func _apply_bonus(bonus_id: String):
	match bonus_id:
		"dividend_payout":
			Global.heal_player(Global.player_max_hp * 0.5)
			Global.portfolio_return += 50.0
			SoundManager.play_exp_coin()
		"short_squeeze":
			SoundManager.play_shockwave()
			var enemies = get_tree().get_nodes_in_group("enemy")
			var player = get_tree().get_first_node_in_group("player")
			var p_pos = player.global_position if is_instance_valid(player) else Vector2.ZERO
			for e in enemies:
				if is_instance_valid(e) and e.has_method("take_damage"):
					var dir = (e.global_position - p_pos).normalized()
					e.take_damage(300.0, dir)
		"compound_growth":
			Global.bonus_damage_multiplier += 0.15
			Global.bonus_speed_multiplier += 0.10
			SoundManager.play_level_up()
		"profit_taking_rally":
			SoundManager.play_boss_alert()
			var player = get_tree().get_first_node_in_group("player")
			if is_instance_valid(player):
				player.is_hodl_active = true
				player.hodl_duration = max(player.hodl_duration, 6.0)
			var gems = get_tree().get_nodes_in_group("exp_gem")
			for g in gems:
				if is_instance_valid(g) and is_instance_valid(player) and g.has_method("attract_to"):
					g.attract_to(player)

func _select_upgrade(skill_id: String):
	Global.skills[skill_id]["level"] += 1
	if skill_id == "dividend_reinvest":
		Global.player_max_hp = 100.0 + Global.skills["dividend_reinvest"]["level"] * 25.0
		Global.heal_player(25.0)
	elif skill_id == "liquidity_magnet":
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player.has_method("update_magnet_radius"):
			player.update_magnet_radius()
	_finish_choice()

func _finish_choice():
	pending_level_ups = max(0, pending_level_ups - 1)
	if pending_level_ups > 0:
		_show_level_up_screen(Global.player_level)
	else:
		get_tree().paused = false
		visible = false
