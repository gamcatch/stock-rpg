extends CanvasLayer

@onready var title_label: Label = $Control/Panel/TitleLabel
@onready var stats_label: Label = $Control/Panel/StatsLabel
@onready var notice_label: Label = $Control/Panel/NoticeLabel
@onready var leaderboard_button: Button = $Control/Panel/LeaderboardButton
@onready var capture_button: Button = $Control/Panel/CaptureButton
@onready var restart_button: Button = $Control/Panel/RestartButton

# Leaderboard modal
@onready var leaderboard_panel: Control = $Control/LeaderboardPanel
@onready var modal_box: Panel = $Control/LeaderboardPanel/ModalBox
@onready var lboard_text: RichTextLabel = $Control/LeaderboardPanel/ModalBox/LBoardText
@onready var lboard_close_button: Button = $Control/LeaderboardPanel/ModalBox/LBoardCloseButton

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	leaderboard_panel.visible = false
	
	_setup_modal_styles()
	
	Global.game_over_signal.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	if capture_button:
		capture_button.pressed.connect(_on_capture_pressed)
	if leaderboard_button:
		leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	if lboard_close_button:
		lboard_close_button.pressed.connect(_on_leaderboard_close_pressed)

func _setup_modal_styles():
	# 1. Main Receipt Panel Style (Opaque Dark Tech Finish)
	var main_panel = $Control/Panel as Panel
	if main_panel:
		var sb_main = StyleBoxFlat.new()
		sb_main.bg_color = Color(0.04, 0.07, 0.15, 0.98)
		sb_main.border_color = Color(0.2, 0.75, 1.0, 0.85)
		sb_main.set_border_width_all(3)
		sb_main.set_corner_radius_all(24)
		sb_main.shadow_color = Color(0, 0, 0, 0.85)
		sb_main.shadow_size = 20
		main_panel.add_theme_stylebox_override("panel", sb_main)
		
	# 2. Leaderboard Modal Box Style (100% Opaque Navy + Brilliant Gold Trim)
	if modal_box:
		var sb_modal = StyleBoxFlat.new()
		sb_modal.bg_color = Color(0.05, 0.08, 0.16, 1.0) # 100% 불투명
		sb_modal.border_color = Color(1.0, 0.84, 0.25, 1.0) # 황금 테두리
		sb_modal.set_border_width_all(4)
		sb_modal.set_corner_radius_all(28)
		sb_modal.shadow_color = Color(0, 0, 0, 0.95)
		sb_modal.shadow_size = 25
		sb_modal.content_margin_left = 30
		sb_modal.content_margin_right = 30
		sb_modal.content_margin_top = 25
		sb_modal.content_margin_bottom = 25
		modal_box.add_theme_stylebox_override("panel", sb_modal)
		
	# 3. Leaderboard Close Button Style
	if lboard_close_button:
		var sb_btn = StyleBoxFlat.new()
		sb_btn.bg_color = Color(0.12, 0.18, 0.32, 1.0)
		sb_btn.border_color = Color(1.0, 0.84, 0.25, 0.9)
		sb_btn.set_border_width_all(2)
		sb_btn.set_corner_radius_all(18)
		lboard_close_button.add_theme_stylebox_override("normal", sb_btn)
		
		var sb_btn_hover = sb_btn.duplicate() as StyleBoxFlat
		sb_btn_hover.bg_color = Color(0.18, 0.26, 0.45, 1.0)
		sb_btn_hover.border_color = Color(1.0, 0.95, 0.5, 1.0)
		lboard_close_button.add_theme_stylebox_override("hover", sb_btn_hover)
		lboard_close_button.add_theme_stylebox_override("pressed", sb_btn_hover)

func _on_game_over(victory: bool):
	get_tree().paused = true
	visible = true
	notice_label.text = ""
	leaderboard_panel.visible = false
	
	# Save record & check achievements
	LeaderboardManager.save_record(Global.portfolio_return, Global.game_time, Global.kills_count)
	if victory:
		LeaderboardManager.unlock_achievement("trump_slayer")
	else:
		LeaderboardManager.unlock_achievement("first_margin_call")
		
	if Global.skills["leverage_100x"]["level"] > 0 and Global.game_time >= 60.0:
		LeaderboardManager.unlock_achievement("leverage_master")
	
	if victory:
		title_label.text = "👑 [전설의 슈퍼개미 달성! 포트폴리오 마감]"
		title_label.modulate = Global.get_up_color()
		SoundManager.play_level_up()
	else:
		title_label.text = "📉 [상장 폐지 경고! 포트폴리오 파산]"
		title_label.modulate = Global.get_down_color()
		SoundManager.play_boss_alert()
		
	var mins = int(Global.game_time) / 60
	var secs = int(Global.game_time) % 60
	
	var retro = MarketDataManager.get_retrospective_data()
	var bonus_mult = retro["bonus_multiplier"]
	var final_return = Global.portfolio_return * bonus_mult
	
	var text = "==============================\n"
	text += "   🧾 [MTS 데일리 매매 정산 영수증]   \n"
	text += "==============================\n\n"
	text += "🌍 기준 증시: %s\n" % retro["market_name"]
	text += "⏱️ 생존 시간: %02d분 %02d초\n" % [mins, secs]
	text += "🎯 격파한 하락/공매도 세력: %d마리\n" % Global.kills_count
	text += "⭐ 도달 계좌 레벨: Lv. %d\n\n" % Global.player_level
	text += "------------------------------\n"
	text += "📊 [오늘의 주도주 복기 분석]\n"
	text += "🔥 당일 최강 주도주: %s\n" % retro["top_stock"]
	text += "🧭 주도주 섹터 체류율: %d%%\n" % retro["top_sector_ratio"]
	text += "🎖️ 투자 성향 판정: %s\n" % retro["user_title"]
	if bonus_mult > 1.05:
		text += "💰 스마트 머니 보너스: x%.2f 배율 적용!\n" % bonus_mult
	var ret_sign = "+" if final_return >= 0 else ""
	text += "📈 최종 실현 수익률: %s%.1f%%\n\n" % [ret_sign, final_return]
	text += "체결: 장마감 정산 완료 | 토스/키움 인증 완료"
	
	stats_label.text = text

func _on_leaderboard_pressed():
	SoundManager.haptic_tap()
	leaderboard_panel.visible = true
	
	var out = "[center][b][color=#FFD700][font_size=38]📊 역대 최고 수익률 TOP 5[/font_size][/color][/b][/center]\n\n"
	var scores = LeaderboardManager.high_scores
	if scores.is_empty():
		out += "[center][color=#A0AEC0]아직 기록된 매매 일지가 없습니다.\n게임을 플레이하여 첫 기록을 달성하세요![/color][/center]\n\n"
	else:
		var medals = ["🥇", "🥈", "🥉", "🏅", "🏅"]
		var colors = ["#FFD700", "#E2E8F0", "#ED8936", "#CBD5E0", "#CBD5E0"]
		for i in range(scores.size()):
			var entry = scores[i]
			var medal = medals[i] if i < medals.size() else "🏅"
			var col = colors[i] if i < colors.size() else "#CBD5E0"
			out += "%s [b][color=%s]%d위: +%.1f%%[/color][/b]  [color=#E2E8F0](%02d분 %02d초 | %d킬)[/color]\n" % [
				medal, col, i + 1, entry["return"], int(entry["time"]) / 60, int(entry["time"]) % 60, entry["kills"]
			]
			out += "     [color=#718096][font_size=26]기록 일시: %s[/font_size][/color]\n\n" % entry["date"]
			
	out += "\n[center][b][color=#63B3ED][font_size=38]🎖️ 개미 투자자 업적 달성 현황[/font_size][/color][/b][/center]\n\n"
	var achs = LeaderboardManager.achievements
	for ach_id in achs.keys():
		var item = achs[ach_id]
		if item["unlocked"]:
			out += " [color=#48BB78]✅[/color] [b][color=#48BB78]%s[/color][/b]\n" % item["name"]
			out += "     [color=#E2E8F0]%s[/color]\n\n" % item["desc"]
		else:
			out += " [color=#718096]🔒[/color] [b][color=#A0AEC0]%s[/color][/b]\n" % item["name"]
			out += "     [color=#718096]%s[/color]\n\n" % item["desc"]
		
	lboard_text.text = out

func _on_leaderboard_close_pressed():
	SoundManager.haptic_tap()
	leaderboard_panel.visible = false

func _on_capture_pressed():
	SoundManager.haptic_tap()
	capture_button.disabled = true
	notice_label.text = "📸 영수증 캡처 중..."
	
	await RenderingServer.frame_post_draw
	
	var img = get_viewport().get_texture().get_image()
	var filename = "user://stock_yield_receipt_%d.png" % int(Time.get_unix_time_from_system())
	var err = img.save_png(filename)
	
	var share_text = "[떡상 서바이버: 개미의 역습]\n내 최종 수익률: +%.1f%%!\n생존시간: %d초 | 처치수: %d마리" % [
		Global.portfolio_return, int(Global.game_time), Global.kills_count
	]
	DisplayServer.clipboard_set(share_text)
	
	if err == OK:
		notice_label.text = "✅ 캡처 저장 & 공유 텍스트 복사 완료!"
	else:
		notice_label.text = "✅ 공유 텍스트 클립보드 복사 완료!"
		
	capture_button.disabled = false

func _on_restart_pressed():
	SoundManager.haptic_tap()
	get_tree().paused = false
	Global.reset_game()
	get_tree().reload_current_scene()
