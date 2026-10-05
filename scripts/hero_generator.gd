# ==============================================================================
# Stock RPG : 데이터 기반 종목 영웅 자동 생성기 (HeroGenerator)
# ==============================================================================
# 종목 데이터(시가총액, PER, 배당률, 등락률, 섹터 등)를 파싱하여
# RPG 영웅의 클래스, 스탯, 궁극기, 모듈러 비주얼을 절차적으로 생성합니다.
# ==============================================================================
class_name HeroGenerator
extends RefCounted

enum HeroClass {
	TANKER,    # 🛡️ 가치주 탱커 (높은 HP/방어력, 도발, 실드)
	DEALER,    # ⚔️ 성장주 딜러 (단일 폭딜, 높은 치명타, 빠른 공속)
	CASTER,    # 🪄 테마주 캐스터 (광역 마법, 군중제어 CC, 폭풍 탄막)
	SUPPORTER  # 💚 배당주 서포터/힐러 (파티 치유, 쿨감, 배당 골드 가산)
}

enum HeroAttribute {
	BULL,      # 🔴 상승/불장 (공격력 및 치명타 특화)
	BEAR,      # 🔵 하락/베어 (빙결, 적 방어력 감소 디버프)
	DIVIDEND,  # 🟡 배당/현금흐름 (지속 재생, 흡혈, 골드 보너스)
	VALUE      # ⚪ 가치/중립 (슈퍼 아머, 상태이상 저항)
}

# ------------------------------------------------------------------------------
# 🚀 메인 함수: 종목 딕셔너리로부터 완제품 영웅 데이터 생성
# ------------------------------------------------------------------------------
static func generate_hero_from_stock(stock_info: Dictionary, sector_key: String = "", is_korean: bool = true) -> Dictionary:
	var name: String = stock_info.get("name", "개미 전사")
	var code: String = stock_info.get("code", "")
	var rate: float = float(stock_info.get("rate", 0.0))
	var price_str: String = str(stock_info.get("price", "100,000"))
	
	if sector_key.is_empty():
		sector_key = stock_info.get("sector", "semiconductor")
	
	var ticker_seed: int = abs(code.hash()) if not code.is_empty() else abs(name.hash())
	
	# 1. 시가총액 & 등급 (Rarity) 판별
	var rarity_info = _determine_rarity(name, code, is_korean, ticker_seed)
	var rarity: String = rarity_info["rarity"]
	var rarity_multiplier: float = rarity_info["multiplier"]
	
	# 2. 클래스 (Class) 판별
	var hero_class: HeroClass = _determine_class(name, sector_key, rate, ticker_seed)
	
	# 3. 속성/극성 (Attribute) 판별
	var attribute: HeroAttribute = _determine_attribute(rate, sector_key, hero_class)
	
	# 4. 배당률 추정 (Dividend Yield)
	var dividend_yield: float = _calculate_dividend_yield(sector_key, hero_class, ticker_seed)
	
	# 5. 베이스 스탯 산출 (Base Stats)
	var stats: Dictionary = _calculate_stats(hero_class, attribute, rarity_multiplier, rate)
	
	# 6. 스킬 및 대사 자동 생성
	var skills: Dictionary = _generate_skills(name, sector_key, hero_class, attribute)
	var dialogues: Dictionary = _generate_dialogues(name, hero_class, rate)
	
	# 7. 모듈러 비주얼 및 이펙트 팔레트
	var visual: Dictionary = _generate_visual_profile(sector_key, hero_class, attribute, rate, ticker_seed)
	
	# 8. 전투력 (Combat Power) 계산
	var cp: int = int((stats["max_hp"] * 0.4) + (stats["atk"] * 3.5) + (stats["def"] * 2.0) + (stats["crit_rate"] * 1000))
	
	return {
		"id": code if not code.is_empty() else name,
		"name": name,
		"code": code,
		"sector": sector_key,
		"is_korean": is_korean,
		"rarity": rarity,
		"class_type": hero_class,
		"class_name": _get_class_display_name(hero_class),
		"attribute": attribute,
		"attribute_name": _get_attribute_display_name(attribute),
		"level": 1,
		"star": 1,
		"stake_shares": 1, # 보유 지분(승급 조각)
		"rate": rate,
		"price_str": price_str,
		"dividend_yield": dividend_yield,
		"combat_power": cp,
		"stats": stats,
		"skills": skills,
		"dialogues": dialogues,
		"visual": visual
	}

# ------------------------------------------------------------------------------
# 1. 시가총액 & 등급 판별
# ------------------------------------------------------------------------------
static func _determine_rarity(name: String, code: String, is_korean: bool, seed_val: int) -> Dictionary:
	# 초우량 대장주 (UR / SSR 고정)
	var mega_caps_kor = ["삼성전자", "SK하이닉스", "LG에너지솔루션", "현대차", "KB금융", "삼성바이오로직스", "NAVER"]
	var mega_caps_us = ["NVIDIA", "Microsoft", "Apple", "Alphabet", "Amazon", "Meta", "Tesla", "Berkshire Hathaway"]
	
	if (is_korean and name in mega_caps_kor) or (!is_korean and name in mega_caps_us):
		return {"rarity": "SSR", "multiplier": 1.45}
	
	# 우량주 (SR 이상)
	var high_caps_kor = ["한미반도체", "두산에너빌리티", "HD현대일렉트릭", "HD한국조선해양", "두산로보틱스", "신한지주", "알테오젠", "한화에어로스페이스"]
	var high_caps_us = ["Broadcom", "AMD", "Eli Lilly", "JPMorgan", "Costco", "Palantir", "Lockheed Martin"]
	
	if (is_korean and name in high_caps_kor) or (!is_korean and name in high_caps_us):
		return {"rarity": "SR", "multiplier": 1.25}
		
	# 시드 기반 결정론적 배정
	var roll = seed_val % 100
	if roll < 20:
		return {"rarity": "SSR", "multiplier": 1.40}
	elif roll < 60:
		return {"rarity": "SR", "multiplier": 1.20}
	else:
		return {"rarity": "R", "multiplier": 1.00}

# ------------------------------------------------------------------------------
# 2. 클래스 결정
# ------------------------------------------------------------------------------
static func _determine_class(name: String, sector_key: String, rate: float, seed_val: int) -> HeroClass:
	# 섹터 고유 성향 우선 매핑
	match sector_key:
		"semiconductor", "us_ai_chips":
			return HeroClass.DEALER # 반도체 = 관통 폭딜러
		"power_grid", "us_power_smr":
			return HeroClass.DEALER if rate >= 5.0 else HeroClass.SUPPORTER
		"finance", "us_wallst_banks":
			return HeroClass.SUPPORTER # 금융 = 고배당/자사주 힐러
		"shipbuilding":
			return HeroClass.TANKER # 조선 = 쇄빙선 철통 탱커
		"battery", "us_ev_robotaxi":
			return HeroClass.CASTER # 배터리/전기차 = 광역 마법/디버프
		"robot_ai", "us_bigtech_m7":
			return HeroClass.CASTER # 로봇/빅테크 = 군중제어 및 탄막
		"bio", "us_healthcare":
			return HeroClass.SUPPORTER if (seed_val % 2 == 0) else HeroClass.DEALER
		"defense", "us_defense_ai":
			return HeroClass.DEALER
		_:
			# 이름 기반 가치주/성장주 판별
			if name.contains("홀딩스") or name.contains("지주") or name.contains("제철") or name.contains("Bank"):
				return HeroClass.TANKER
			elif name.contains("로보") or name.contains("AI") or name.contains("바이오"):
				return HeroClass.CASTER
			elif rate >= 6.0:
				return HeroClass.DEALER
			else:
				var classes = [HeroClass.TANKER, HeroClass.DEALER, HeroClass.CASTER, HeroClass.SUPPORTER]
				return classes[seed_val % classes.size()]

# ------------------------------------------------------------------------------
# 3. 속성/극성 결정
# ------------------------------------------------------------------------------
static func _determine_attribute(rate: float, sector_key: String, hero_class: HeroClass) -> HeroAttribute:
	if hero_class == HeroClass.SUPPORTER:
		return HeroAttribute.DIVIDEND
	elif hero_class == HeroClass.TANKER:
		return HeroAttribute.VALUE
	elif rate >= 2.0:
		return HeroAttribute.BULL
	elif rate <= -2.0:
		return HeroAttribute.BEAR
	else:
		return HeroAttribute.BULL if rate >= 0.0 else HeroAttribute.BEAR

# ------------------------------------------------------------------------------
# 4. 배당률 산출
# ------------------------------------------------------------------------------
static func _calculate_dividend_yield(sector_key: String, hero_class: HeroClass, seed_val: int) -> float:
	if hero_class == HeroClass.SUPPORTER or sector_key in ["finance", "us_wallst_banks"]:
		return snappedf(4.5 + (seed_val % 35) * 0.1, 0.1) # 4.5% ~ 8.0%
	elif hero_class == HeroClass.TANKER:
		return snappedf(2.5 + (seed_val % 25) * 0.1, 0.1) # 2.5% ~ 5.0%
	else:
		return snappedf(0.8 + (seed_val % 20) * 0.1, 0.1) # 0.8% ~ 2.8%

# ------------------------------------------------------------------------------
# 5. 스탯 산출 알고리즘
# ------------------------------------------------------------------------------
static func _calculate_stats(hero_class: HeroClass, attribute: HeroAttribute, rarity_mult: float, rate: float) -> Dictionary:
	var base_hp: float = 1500.0
	var base_atk: float = 220.0
	var base_def: float = 50.0
	var atk_speed: float = 1.2 # 초당 공격
	var attack_range: float = 320.0 # 픽셀
	var crit_rate: float = 0.15
	var crit_dmg: float = 1.5
	var move_speed: float = 260.0
	
	match hero_class:
		HeroClass.TANKER:
			base_hp = 3500.0
			base_atk = 130.0
			base_def = 120.0
			atk_speed = 0.9
			attack_range = 140.0
			move_speed = 220.0
			crit_rate = 0.08
		HeroClass.DEALER:
			base_hp = 1600.0
			base_atk = 380.0
			base_def = 45.0
			atk_speed = 1.6
			attack_range = 380.0
			move_speed = 280.0
			crit_rate = 0.28
			crit_dmg = 2.0
		HeroClass.CASTER:
			base_hp = 1250.0
			base_atk = 430.0
			base_def = 35.0
			atk_speed = 1.1
			attack_range = 480.0
			move_speed = 240.0
			crit_rate = 0.22
			crit_dmg = 1.8
		HeroClass.SUPPORTER:
			base_hp = 2000.0
			base_atk = 180.0
			base_def = 65.0
			atk_speed = 1.0
			attack_range = 340.0
			move_speed = 250.0
			crit_rate = 0.12
	
	# 상승장 버프 (+등락률 보너스)
	if rate > 0.0:
		base_atk *= (1.0 + (min(rate, 30.0) * 0.015))
		crit_rate += min(rate * 0.005, 0.10)
	
	return {
		"max_hp": int(base_hp * rarity_mult),
		"current_hp": int(base_hp * rarity_mult),
		"atk": int(base_atk * rarity_mult),
		"def": int(base_def * rarity_mult),
		"atk_speed": snappedf(atk_speed, 0.1),
		"attack_range": attack_range,
		"crit_rate": snappedf(crit_rate, 0.01),
		"crit_dmg": snappedf(crit_dmg, 0.1),
		"move_speed": move_speed
	}

# ------------------------------------------------------------------------------
# 6. 스킬 및 대사 생성
# ------------------------------------------------------------------------------
static func _generate_skills(name: String, sector_key: String, hero_class: HeroClass, attribute: HeroAttribute) -> Dictionary:
	var active_name: String = ""
	var active_desc: String = ""
	var effect_type: String = "DAMAGE"
	var cooldown: float = 12.0
	var damage_ratio: float = 3.5
	
	match hero_class:
		HeroClass.TANKER:
			active_name = "%s 불멸의 존버 쉴드" % name
			active_desc = "6초간 받는 피해 60% 감소 및 주변 모든 적을 자신에게 도발합니다."
			effect_type = "SHIELD_TAUNT"
			cooldown = 14.0
		HeroClass.DEALER:
			active_name = "%s 초고속 양봉 빔" % name
			active_desc = "일직선 상의 모든 적을 관통하여 480% 치명타 피해를 입힙니다."
			effect_type = "PIERCE_BEAM"
			damage_ratio = 4.8
			cooldown = 11.0
		HeroClass.CASTER:
			active_name = "%s 100배 레버리지 폭풍" % name
			active_desc = "전 화면에 파괴적인 주가 급등락 폭풍을 일으켜 광역 420% 피해를 주고 2.5초간 기절시킵니다."
			effect_type = "AOE_STUN"
			damage_ratio = 4.2
			cooldown = 15.0
		HeroClass.SUPPORTER:
			active_name = "%s 황금 특별 배당금 파티" % name
			active_desc = "전 파티원 체력을 즉시 45% 회복시키고 8초간 공격속도를 30% 증가시킵니다."
			effect_type = "HEAL_BUFF"
			cooldown = 13.0
			
	var passive_name = "%s 주주가치 제고" % name
	var passive_desc = "출전 시 파티 전체 전투력 +10% 및 배당금 수령 효율 +15%"
	
	return {
		"normal_attack": {
			"name": "%s 기본 매수 타격" % name,
			"ratio": 1.0
		},
		"active_skill": {
			"name": active_name,
			"desc": active_desc,
			"effect_type": effect_type,
			"cooldown": cooldown,
			"damage_ratio": damage_ratio
		},
		"passive_skill": {
			"name": passive_name,
			"desc": passive_desc
		}
	}

static func _generate_dialogues(name: String, hero_class: HeroClass, rate: float) -> Dictionary:
	var spawn_msg = "[%s] 상한가를 향해 전진하라!" % name
	if rate >= 5.0:
		spawn_msg = "[%s] 떡상 랠리가 시작된다! 전원 풀매수!" % name
	elif rate < 0.0:
		spawn_msg = "[%s] 하락장은 기회다, 저점 매수로 반등을 노린다!" % name
		
	return {
		"spawn": spawn_msg,
		"skill": "[%s] 이것이 주주환원의 힘이다!" % name,
		"win": "[%s] 목표 수익률 달성 완료! 계좌 떡상!" % name
	}

# ------------------------------------------------------------------------------
# 7. 비주얼 및 이펙트 프로필
# ------------------------------------------------------------------------------
static func _generate_visual_profile(sector_key: String, hero_class: HeroClass, attribute: HeroAttribute, rate: float, seed_val: int) -> Dictionary:
	var body_style: String = "medium_humanoid"
	var weapon_style: String = "sword"
	var primary_color: Color = Color(1.0, 0.3, 0.3) # 🔴 기본 불장 빨강
	var accent_color: Color = Color(1.0, 0.85, 0.2) # 🟡 골드
	var aura_type: String = "bull_fire"
	
	match attribute:
		HeroAttribute.BULL:
			primary_color = Color(1.0, 0.25, 0.25) # 진한 빨강
			aura_type = "bull_fire"
		HeroAttribute.BEAR:
			primary_color = Color(0.25, 0.6, 1.0) # 차가운 블루
			aura_type = "bear_frost"
		HeroAttribute.DIVIDEND:
			primary_color = Color(1.0, 0.85, 0.15) # 번쩍이는 골드
			aura_type = "gold_sparkle"
		HeroAttribute.VALUE:
			primary_color = Color(0.85, 0.9, 0.95) # 플래티넘 화이트
			aura_type = "steel_guard"
			
	match hero_class:
		HeroClass.TANKER:
			body_style = "heavy_armored_ant"
			weapon_style = "shield_and_hammer"
		HeroClass.DEALER:
			body_style = "agile_scout_ant"
			weapon_style = "laser_candlestick_blade"
		HeroClass.CASTER:
			body_style = "mystic_robed_ant"
			weapon_style = "ticker_chart_staff"
		HeroClass.SUPPORTER:
			body_style = "fairy_winged_ant"
			weapon_style = "golden_chalice"
			
	return {
		"body_style": body_style,
		"weapon_style": weapon_style,
		"primary_color": primary_color,
		"accent_color": accent_color,
		"aura_type": aura_type,
		"sprite_scale": 1.2 if hero_class == HeroClass.TANKER else 1.0
	}

# ------------------------------------------------------------------------------
# 헬퍼 명칭 반환
# ------------------------------------------------------------------------------
static func _get_class_display_name(c: HeroClass) -> String:
	match c:
		HeroClass.TANKER: return "🛡️ 가치주 탱커"
		HeroClass.DEALER: return "⚔️ 성장주 딜러"
		HeroClass.CASTER: return "🪄 테마주 캐스터"
		HeroClass.SUPPORTER: return "💚 배당주 서포터"
	return "모험가"

static func _get_attribute_display_name(a: HeroAttribute) -> String:
	match a:
		HeroAttribute.BULL: return "🔴 상승 (BULL)"
		HeroAttribute.BEAR: return "🔵 하락 (BEAR)"
		HeroAttribute.DIVIDEND: return "🟡 배당 (DIVIDEND)"
		HeroAttribute.VALUE: return "⚪ 가치 (VALUE)"
	return "중립"
