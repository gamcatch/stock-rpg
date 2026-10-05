extends Node

signal level_up(new_level)
signal exp_changed(current_exp, max_exp)
signal hp_changed(current_hp, max_hp)
signal game_over_signal(victory)
signal upgrade_selected(upgrade_id)
signal color_theme_changed(is_korean)
signal market_event_triggered(event_name, event_desc)
signal auto_play_toggled(is_enabled)
signal game_speed_toggled(new_speed)

var is_korean_market_colors: bool = true # True: Red=Rise (한국형), False: Green=Rise (글로벌형)
var auto_play_enabled: bool = true # 방치형 오토플레이 기본 활성화
var game_speed_scale: float = 1.0 # 게임 진행 배속 (1.0x / 2.0x)

var game_time: float = 0.0
var is_game_over: bool = false
var is_paused: bool = false

# Market Event Modifiers
var enemy_speed_multiplier: float = 1.0
var exp_multiplier: float = 1.0
var current_market_event: String = ""
var event_remaining_time: float = 0.0
var player_speed_modifier: float = 1.0
var in_bear_hazard: bool = false
var in_bull_zone: bool = false

# Player stats
var player_level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 10
var player_hp: float = 350.0
var player_max_hp: float = 350.0
var kills_count: int = 0
var total_damage_dealt: float = 0.0
var portfolio_return: float = 0.0 # Yield percentage calculation
var account_balance: int = 1000000 # 시드머니 (기본 100만 원)
var current_return_rate: float = 0.0 # 누적 수익률 %
var joystick_vector: Vector2 = Vector2.ZERO # Mobile virtual joystick input
var bonus_damage_multiplier: float = 1.0
var bonus_speed_multiplier: float = 1.0

# 방치형 생존 & 무적/회복 시스템
var player_iframe_timer: float = 0.0
var emergency_hodl_ready: bool = true
var emergency_hodl_cooldown: float = 60.0
var natural_regen_timer: float = 0.0

# Skill levels
var skills = {
	"green_beam": {"level": 1, "max_level": 5, "name": "양봉 빔", "desc": "전방으로 관통하는 초록색 차트 광선 발사", "icon": "🟢"},
	"dca_shield": {"level": 0, "max_level": 5, "name": "물타기 (DCA)", "desc": "주변에 분신 쉴드를 생성하여 적 접촉 피해 감소 & 데미지", "icon": "💧"},
	"stop_loss": {"level": 0, "max_level": 5, "name": "손절 라이트닝", "desc": "HP 위기 시 주변 적 대폭 노크백 & 힐링 충격파", "icon": "⚡"},
	"hodl_shield": {"level": 0, "max_level": 5, "name": "존버 쉴드", "desc": "주기적으로 무적 상태 돌입 및 대시 충돌 데미지", "icon": "🛡️"},
	"leverage_100x": {"level": 0, "max_level": 1, "name": "레버리지 100배", "desc": "데미지 +900% 증가, 입는 피해 +400% 증가 (하이리스크)", "icon": "🚀"},
	"dividend_reinvest": {"level": 0, "max_level": 5, "name": "배당 재투자", "desc": "최대 HP +25 및 2초마다 지속적으로 체력 자동 회복", "icon": "💵"},
	"scalping": {"level": 0, "max_level": 5, "name": "초단타 스캘핑", "desc": "이동 속도 +10% 및 양봉 빔 연사 속도 +15% 가속", "icon": "⚡"},
	"quant_ai": {"level": 0, "max_level": 5, "name": "퀀트 AI 모델", "desc": "모든 무기 공격력 +25% 및 관통력 +1 추가", "icon": "🤖"},
	"liquidity_magnet": {"level": 0, "max_level": 5, "name": "유동성 흡수 (자석)", "desc": "배당금 젬 흡입 범위 +70% 및 흡입 속도 대폭 증가", "icon": "🧲"}
}

func _ready():
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

func _process(delta: float):
	if is_game_over or is_paused:
		return
		
	# 1. 피격 무적 시간 (i-frame) 감쇄
	if player_iframe_timer > 0.0:
		player_iframe_timer -= delta
		
	# 2. 비상 존버 실드 쿨다운 회복 (60초 주기)
	if not emergency_hodl_ready:
		emergency_hodl_cooldown -= delta
		if emergency_hodl_cooldown <= 0.0:
			emergency_hodl_ready = true
			emergency_hodl_cooldown = 60.0
			
	# 3. 방치형 기본 배당금 자연 치유 (초당 4.0 HP 지속 회복)
	if player_hp < player_max_hp:
		natural_regen_timer += delta
		if natural_regen_timer >= 1.0:
			natural_regen_timer = 0.0
			heal_player(4.0)

func reset_game():
	game_time = 0.0
	is_game_over = false
	is_paused = false
	player_level = 1
	current_exp = 0
	exp_to_next_level = 10
	player_max_hp = 350.0
	player_hp = 350.0
	player_iframe_timer = 0.0
	emergency_hodl_ready = true
	emergency_hodl_cooldown = 60.0
	kills_count = 0
	total_damage_dealt = 0.0
	portfolio_return = 0.0
	joystick_vector = Vector2.ZERO
	enemy_speed_multiplier = 1.0
	exp_multiplier = 1.0
	current_market_event = ""
	event_remaining_time = 0.0
	player_speed_modifier = 1.0
	bonus_damage_multiplier = 1.0
	bonus_speed_multiplier = 1.0
	in_bear_hazard = false
	in_bull_zone = false
	
	skills["green_beam"]["level"] = 1
	skills["dca_shield"]["level"] = 0
	skills["stop_loss"]["level"] = 0
	skills["hodl_shield"]["level"] = 0
	skills["leverage_100x"]["level"] = 0
	skills["dividend_reinvest"]["level"] = 0
	skills["scalping"]["level"] = 0
	skills["quant_ai"]["level"] = 0
	skills["liquidity_magnet"]["level"] = 0

func add_exp(amount: int):
	if is_game_over:
		return
	var actual_amount = int(amount * exp_multiplier)
	current_exp += actual_amount
	portfolio_return += actual_amount * 1.5
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		player_level += 1
		exp_to_next_level = int(exp_to_next_level * 1.35 + 5)
		
		# 📈 레벨업 보너스: 최대 HP 증가 및 35% 즉시 회복!
		player_max_hp += 20.0
		heal_player(player_max_hp * 0.35)
		
		emit_signal("level_up", player_level)
	emit_signal("exp_changed", current_exp, exp_to_next_level)

func take_player_damage(amount: float):
	if is_game_over:
		return
		
	# 피격 무적 판정 (연타로 순식간에 녹는 현상 방지)
	if player_iframe_timer > 0.0:
		return
	
	var damage_multiplier = 0.45 # 방치형 RPG 편안한 난이도 튜닝
	if skills["leverage_100x"]["level"] > 0:
		damage_multiplier = 2.0
		
	var actual_damage = amount * damage_multiplier
	player_hp = max(0.0, player_hp - actual_damage)
	player_iframe_timer = 0.45 # 피격 후 0.45초간 무적 보호
	SoundManager.haptic_impact()
	emit_signal("hp_changed", player_hp, player_max_hp)
	
	# 🛡️ HP 20% 이하 위기 시 자동 [비상 존버] 발동 (1회 생명선)
	if player_hp > 0 and (player_hp / player_max_hp) <= 0.20 and emergency_hodl_ready:
		emergency_hodl_ready = false
		player_iframe_timer = 3.0 # 3초간 절대 무적
		heal_player(player_max_hp * 0.35) # 35% 긴급 수혈
		SoundManager.play_level_up()
		market_event_triggered.emit("🛡️ [개미의 비상 존버 발동!]", "HP 위기 감지! 3초간 절대 무적 & 35% 긴급 수혈 완료!")
	
	if player_hp <= 0 and not is_game_over:
		trigger_game_over(false)

func heal_player(amount: float):
	player_hp = min(player_max_hp, player_hp + amount)
	emit_signal("hp_changed", player_hp, player_max_hp)

func trigger_game_over(victory: bool):
	is_game_over = true
	SoundManager.haptic_heavy()
	emit_signal("game_over_signal", victory)

func toggle_color_theme():
	is_korean_market_colors = not is_korean_market_colors
	emit_signal("color_theme_changed", is_korean_market_colors)

func get_up_color() -> Color:
	return Color(1.0, 0.25, 0.25) # Always Red for Rise/Bull

func get_down_color() -> Color:
	return Color(0.2, 0.55, 1.0) # Always Blue for Fall/Bear

func get_damage_multiplier() -> float:
	var mult = 1.0
	if skills["leverage_100x"]["level"] > 0:
		mult *= 10.0 # 10x damage dealt
	if skills.has("quant_ai") and skills["quant_ai"]["level"] > 0:
		mult *= (1.0 + skills["quant_ai"]["level"] * 0.25)
	return mult * bonus_damage_multiplier
