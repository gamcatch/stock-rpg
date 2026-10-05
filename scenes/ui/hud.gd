extends CanvasLayer

@onready var ticker_panel: Panel = $HUDControl/TickerPanel
@onready var ticker_label: Label = $HUDControl/TickerPanel/TickerLabel
@onready var exp_bar: TextureProgressBar = $HUDControl/EXPBar
@onready var header_panel: Panel = $HUDControl/HeaderPanel
@onready var hp_bar: TextureProgressBar = $HUDControl/HeaderPanel/HPBar
@onready var hp_label: Label = $HUDControl/HeaderPanel/HPLabel
@onready var level_label: Label = $HUDControl/HeaderPanel/LevelLabel
@onready var timer_label: Label = $HUDControl/HeaderPanel/TimerLabel
@onready var kills_label: Label = $HUDControl/HeaderPanel/KillsLabel
@onready var yield_label: Label = $HUDControl/HeaderPanel/YieldLabel
@onready var theme_button: Button = $HUDControl/HeaderPanel/ThemeButton
@onready var auto_button: Button = $HUDControl/HeaderPanel/AutoButton
@onready var speed_button: Button = $HUDControl/HeaderPanel/SpeedButton
@onready var sector_panel: Panel = $HUDControl/SectorPanel
@onready var sector_ticker_label: Label = $HUDControl/SectorPanel/SectorTickerLabel
@onready var radar_minimap: Control = $HUDControl/RadarMinimap

var ticker_news: Array = [
	"📈 KOSPI 3000P 돌파! 개미 군단 대반격 개시!",
	"🔥 [속보] 양봉 빔 연속 발사로 공매도 세력 대규모 청산!",
	"⚠️ 파월 의장: 추가 금리 인상 단행 가능성 시사...",
	"🚀 비트코인 1억 돌파! 존버는 반드시 승리한다!",
	"💥 패닉셀 개미들 폭락장에 집단 투매 발생!",
	"🛡️ 물타기(DCA) 전법으로 접촉 피해 최소화 성공!",
	"⚡ 손절 라이트닝 발동! 주가 반등 성공!"
]

var current_news_index: int = 0
var ticker_offset: float = 1080.0
var sector_ticker_offset: float = 1080.0
var cached_sector_text: String = ""
var sector_update_timer: float = 0.0
var target_player: Node2D = null

func _ready():
	Global.exp_changed.connect(_on_exp_changed)
	Global.hp_changed.connect(_on_hp_changed)
	Global.color_theme_changed.connect(_on_color_theme_changed)
	Global.market_event_triggered.connect(_on_market_event_triggered)
	MarketDataManager.breaking_news_alert.connect(_on_breaking_news_alert)
	MarketDataManager.market_mode_changed.connect(_on_market_mode_changed)
	MarketDataManager.live_news_received.connect(_on_live_news_received)
	MarketDataManager.live_rates_applied.connect(_on_live_rates_applied)
	
	if theme_button:
		theme_button.pressed.connect(_on_theme_button_pressed)
	if auto_button:
		auto_button.pressed.connect(_on_auto_button_pressed)
		_update_auto_button_ui()
	if speed_button:
		speed_button.pressed.connect(_on_speed_button_pressed)
		_update_speed_button_ui()
		
	get_tree().root.size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_refresh_ticker_news()
	_update_hud()
	_update_theme_ui(Global.is_korean_market_colors)

func _refresh_ticker_news():
	if MarketDataManager.current_market_type == MarketDataManager.MarketType.KOREA:
		ticker_news = [
			"📈 KOSPI 3000P 돌파! 개미 군단 대반격 개시!",
			"🔥 [한미반도체] 듀얼 TC본더 글로벌 수주 잭팟! AI 패키징 독점 지위 공고화",
			"🚀 [SK하이닉스] 5세대 HBM3E 엔비디아 공급 주도권 유지... 영업이익 사상 최대치",
			"💎 [알테오젠] MSD 키트루다 피하주사(SC) 독점 라이선스 마일스톤 유입",
			"🤖 [두산로보틱스] 북미 식음료 및 물류 자동화 협동로봇 솔루션 대규모 공급 체결",
			"⚠️ [에코프로비엠] 하이니켈 양극재 고객사 재고 소진 후 출하량 반등 모색",
			"⚡ [삼성전자] HBM3E 12단 퀄 테스트 최종 검증 진입 및 파운드리 수율 안정화",
			"🛡️ 물타기(DCA) 전법으로 접촉 피해 최소화! 우량 섹터로 진입하세요!"
		]
	else:
		ticker_news = [
			"📈 NASDAQ 신기록 경신! AI 혁명 랠리 지속!",
			"🔥 [NVIDIA] 블랙웰 B200 칩 공급 부족 2025년까지 지속... 빅테크 주문 쟁탈전",
			"🚀 [Broadcom] 커스텀 AI ASIC 칩 및 이더넷 스위치 매출 300% 폭증",
			"💎 [Microsoft] Azure AI 클라우드 30% 성장... Copilot 유료 구독자 급증",
			"💉 [Eli Lilly] 젭바운드 비만치료제 주간 처방량 신기록... 글로벌 생산 확대",
			"🤖 [Apple] Apple Intelligence 탑재로 아이폰 교체 슈퍼사이클 가동",
			"⚡ [Tesla] 로보택시(Cybercab) 완전 자율주행 시범 운행 승인 추진",
			"🛡️ 실리콘밸리 우량 테크주를 찾아 전진하세요!"
		]
	current_news_index = 0
	ticker_offset = 1080.0
	if ticker_label and ticker_news.size() > 0:
		ticker_label.text = ticker_news[0]

func _on_live_news_received(news_list: Array):
	if news_list.size() > 0:
		ticker_news.clear()
		ticker_news.append("⚡ [실시간 속보 연동] 국내/글로벌 시장 데이터 및 속보 수신 중!")
		for item in news_list:
			ticker_news.append(item)
		current_news_index = 0
		ticker_offset = 1080.0
		ticker_label.text = ticker_news[0]

func _on_live_rates_applied(_m_type):
	_update_sector_info()

func _apply_safe_area():
	# Dynamic Safe Area detection for Android Punch-hole / Notch cameras
	var safe_area = DisplayServer.get_display_safe_area()
	var screen_size = DisplayServer.screen_get_size()
	
	var top_offset = 80.0
	if screen_size.y > 0 and safe_area.position.y > 0:
		var safe_top_ratio = float(safe_area.position.y) / float(screen_size.y)
		var calculated_top = safe_top_ratio * 2400.0
		top_offset = max(80.0, calculated_top + 16.0)
		
	ticker_panel.offset_top = top_offset
	ticker_panel.offset_bottom = top_offset + 80.0
	exp_bar.offset_top = top_offset + 80.0
	exp_bar.offset_bottom = top_offset + 106.0
	header_panel.offset_top = top_offset + 114.0
	header_panel.offset_bottom = top_offset + 284.0
	if sector_panel:
		sector_panel.offset_top = top_offset + 292.0
		sector_panel.offset_bottom = top_offset + 382.0
	if radar_minimap:
		radar_minimap.offset_top = top_offset + 396.0
		radar_minimap.offset_bottom = top_offset + 596.0

func _process(delta):
	if Global.is_game_over:
		return
		
	Global.game_time += delta
	var mins = int(Global.game_time) / 60
	var secs = int(Global.game_time) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	
	kills_label.text = "처치: %d" % Global.kills_count
	var sign_str = "+" if Global.portfolio_return >= 0 else ""
	yield_label.text = "수익률: %s%.1f%%" % [sign_str, Global.portfolio_return]
	yield_label.modulate = Global.get_up_color() if Global.portfolio_return >= 0 else Global.get_down_color()
	
	# 1. Scroll top news ticker smoothly in 1080px width
	ticker_offset -= 100.0 * delta
	if ticker_offset < -900.0:
		ticker_offset = 1080.0
		current_news_index = (current_news_index + 1) % ticker_news.size()
		ticker_label.text = ticker_news[current_news_index]
	ticker_label.position.x = ticker_offset
	
	# 2. Scroll sector & stock ticker smoothly without any overlapping!
	if sector_ticker_label:
		sector_ticker_offset -= 120.0 * delta
		var text_len = sector_ticker_label.text.length()
		var approx_width = max(1400.0, text_len * 24.0)
		if sector_ticker_offset < -approx_width:
			sector_ticker_offset = 1080.0
		sector_ticker_label.position.x = sector_ticker_offset
	
	sector_update_timer += delta
	if sector_update_timer >= 0.15:
		sector_update_timer = 0.0
		_update_sector_info()

func _update_sector_info():
	if not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player")
		if not target_player:
			var main = get_parent()
			if main and main.has_node("Player"):
				target_player = main.get_node("Player")
				
	if not is_instance_valid(target_player):
		return
		
	var p_pos = target_player.global_position
	var cur_sec = MarketDataManager.get_sector_at(p_pos)
	var top_sec = MarketDataManager.get_top_bull_sector()
	var worst_sec = MarketDataManager.get_worst_bear_sector()
	var near_stock = MarketDataManager.get_nearest_stock_at(p_pos)
	
	var new_text = ""
	var new_color = Color(0.85, 0.95, 1.0)
	
	if not near_stock.is_empty():
		# Player is standing at an individual stock sanctuary
		var s_up = near_stock["rate"] >= 0.0
		var s_sign = "▲ +" if s_up else "▼ "
		new_color = Color(1.0, 0.9, 0.2) if near_stock["rate"] >= 10.0 else (Global.get_up_color() if s_up else Global.get_down_color())
		var st_news = MarketDataManager.get_news_for_stock(near_stock["name"])
		new_text = "📍 [탑승: %s %s%.1f%%]  ❖  📰 [종목 속보] %s  ❖  %s  ❖  배당금 젬 획득 중!" % [
			near_stock["name"], s_sign, abs(near_stock["rate"]), st_news, near_stock.get("desc", "")
		]
	elif cur_sec["key"] == "plaza":
		new_color = Color(0.85, 0.95, 1.0)
		new_text = "🏛️ [중앙 증시 대교차로]  ❖  360도 고속도로를 통해 4대 섹터로 전진하세요  ❖  실시간 섹터별/종목별 속보 및 호재를 확인하세요!"
	else:
		# Player has entered a specific sector: reveal its stock rates & sector news!
		var is_bull = (cur_sec.get("key", "") == top_sec.get("key", ""))
		var is_bear = (cur_sec.get("key", "") == worst_sec.get("key", ""))
		var sec_up = cur_sec["change_rate"] >= 0.0
		var rate_sign = "▲ +" if sec_up else "▼ "
		new_color = Global.get_up_color() if sec_up else Global.get_down_color()
		
		var sec_news = MarketDataManager.get_news_for_sector(cur_sec.get("key", ""))
		var stock_summary = ""
		if cur_sec.has("stocks"):
			for st in cur_sec["stocks"]:
				var st_sign = "▲ +" if st["rate"] >= 0 else "▼ "
				stock_summary += "%s %s%.1f%%  ❖  " % [st["name"], st_sign, abs(st["rate"])]
				
		var tag = "🔥 [주도주 구역 안착]" if is_bull else ("⚠️ [공매도 지대 진입]" if is_bear else "📍 [구역 진입]")
		new_text = "%s %s [%s%.1f%%]  ❖  📰 [섹터 속보] %s  ❖  %s외곽 도로를 따라 개별 종목 성역으로 이동하세요" % [
			tag, cur_sec["name"], rate_sign, abs(cur_sec["change_rate"]), sec_news, stock_summary
		]
		
	# Update label text only when content changed (preserves smooth marquee flow)
	if new_text != cached_sector_text and not new_text.is_empty():
		cached_sector_text = new_text
		if sector_ticker_label:
			sector_ticker_label.text = new_text
			sector_ticker_label.add_theme_color_override("font_color", new_color)

func _get_direction_arrow(diff: Vector2) -> String:
	var angle_deg = rad_to_deg(diff.angle())
	if angle_deg < 0:
		angle_deg += 360.0
		
	if angle_deg >= 337.5 or angle_deg < 22.5:
		return "동쪽 →"
	elif angle_deg >= 22.5 and angle_deg < 67.5:
		return "남동쪽 ↘"
	elif angle_deg >= 67.5 and angle_deg < 112.5:
		return "남쪽 ↓"
	elif angle_deg >= 112.5 and angle_deg < 157.5:
		return "남서쪽 ↙"
	elif angle_deg >= 157.5 and angle_deg < 202.5:
		return "서쪽 ←"
	elif angle_deg >= 202.5 and angle_deg < 247.5:
		return "북서쪽 ↖"
	elif angle_deg >= 247.5 and angle_deg < 292.5:
		return "북쪽 ↑"
	else:
		return "북동쪽 ↗"

func _on_breaking_news_alert(headline: String, sector_key: String, effect_type: String, duration: float):
	ticker_label.text = "🚨 " + headline
	ticker_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if effect_type == "debuff" else Color(1.0, 0.9, 0.2))
	ticker_offset = 1080.0
	SoundManager.haptic_pulse()

func _on_market_mode_changed(mode_name: String, is_korean: bool):
	_refresh_ticker_news()
	_update_theme_ui(is_korean)

func _on_market_event_triggered(event_name: String, event_desc: String):
	ticker_label.text = "%s  %s" % [event_name, event_desc]
	ticker_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	ticker_offset = 1080.0
	SoundManager.haptic_pulse()

func _on_theme_button_pressed():
	SoundManager.haptic_tap()
	var next_type = MarketDataManager.MarketType.US if MarketDataManager.current_market_type == MarketDataManager.MarketType.KOREA else MarketDataManager.MarketType.KOREA
	MarketDataManager.switch_market(next_type)

func _on_auto_button_pressed():
	SoundManager.haptic_tap()
	Global.auto_play_enabled = !Global.auto_play_enabled
	Global.auto_play_toggled.emit(Global.auto_play_enabled)
	_update_auto_button_ui()

func _update_auto_button_ui():
	if auto_button:
		if Global.auto_play_enabled:
			auto_button.text = "🤖 AUTO"
			auto_button.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		else:
			auto_button.text = "🕹️ 수동"
			auto_button.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))

func _on_speed_button_pressed():
	SoundManager.haptic_tap()
	if Engine.time_scale <= 1.0:
		Engine.time_scale = 2.0
		Global.game_speed_scale = 2.0
	else:
		Engine.time_scale = 1.0
		Global.game_speed_scale = 1.0
	Global.game_speed_toggled.emit(Global.game_speed_scale)
	_update_speed_button_ui()

func _update_speed_button_ui():
	if speed_button:
		if Engine.time_scale > 1.0:
			speed_button.text = "⚡ 2X"
			speed_button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			speed_button.text = "⚡ 1X"
			speed_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _on_color_theme_changed(is_korean: bool):
	_update_theme_ui(is_korean)

func _update_theme_ui(is_korean: bool):
	if theme_button:
		theme_button.text = "🇰🇷 국장 🔴" if is_korean else "🇺🇸 미장 🟢"
	if yield_label:
		yield_label.add_theme_color_override("font_color", Global.get_up_color())

func _on_exp_changed(current: int, max_val: int):
	exp_bar.max_value = max_val
	exp_bar.value = current
	level_label.text = "Lv. %d" % Global.player_level

func _on_hp_changed(current: float, max_val: float):
	hp_bar.max_value = max_val
	hp_bar.value = current
	hp_label.text = "HP %.0f / %.0f" % [current, max_val]

func _update_hud():
	level_label.text = "Lv. %d" % Global.player_level
	_on_exp_changed(Global.current_exp, Global.exp_to_next_level)
	_on_hp_changed(Global.player_hp, Global.player_max_hp)
	ticker_label.text = ticker_news[0]
	ticker_offset = 1080.0
