# ==============================================================================
# Stock RPG : 5인 포트폴리오 파티 매니저 (PartyManager)
# ==============================================================================
# 5개 슬롯의 종목 영웅 배치, 실시간 섹터/속성 시너지 버프 연산,
# 총 전투력(CP) 및 시간당 분당 배당 수익률을 관리하는 핵심 싱글톤입니다.
# ==============================================================================
extends Node

signal party_updated()
signal synergy_changed(synergies: Array)
signal hero_unlocked(hero_data: Dictionary)

const SAVE_PATH: String = "user://portfolio_party.json"
const MAX_PARTY_SLOTS: int = 5

# 5인 포트폴리오 슬롯 (0: 전열 탱커, 1~2: 중열 딜러, 3: 후열 캐스터, 4: 후열 힐러)
var party_slots: Array = [null, null, null, null, null]

# 플레이어가 보유 중인 전체 영웅 풀 { "hero_id": hero_dict }
var unlocked_heroes: Dictionary = {}

# 현재 활성화된 시너지 효과 목록
var active_synergies: Array = []

func _ready():
	load_party_data()
	if unlocked_heroes.is_empty():
		_initialize_starter_heroes()
	update_party_synergies()

# ------------------------------------------------------------------------------
# 🎁 게임 시작 시 스타터 5인 포트폴리오 지급 (국장 우량 분산투자)
# ------------------------------------------------------------------------------
func _initialize_starter_heroes():
	print("[PartyManager] 초기 스타터 포트폴리오(5종목)를 생성합니다.")
	
	# 1. 삼성전자 (전열 탱커 / 국민주)
	var sam = HeroGenerator.generate_hero_from_stock({
		"name": "삼성전자", "code": "005930", "rate": 1.5, "price": "78,400", "sector": "semiconductor"
	}, "semiconductor", true)
	sam["class_type"] = HeroGenerator.HeroClass.TANKER
	sam["class_name"] = HeroGenerator._get_class_display_name(sam["class_type"])
	
	# 2. SK하이닉스 (중열 L 딜러 / HBM 대장)
	var hynix = HeroGenerator.generate_hero_from_stock({
		"name": "SK하이닉스", "code": "000660", "rate": 6.8, "price": "189,200", "sector": "semiconductor"
	}, "semiconductor", true)
	
	# 3. 한미반도체 (중열 R 딜러 / 상한가 TC본더)
	var hanmi = HeroGenerator.generate_hero_from_stock({
		"name": "한미반도체", "code": "042700", "rate": 14.8, "price": "142,500", "sector": "semiconductor"
	}, "semiconductor", true)
	
	# 4. 두산로보틱스 (후열 L 캐스터 / 지능형 협동로봇)
	var doosan = HeroGenerator.generate_hero_from_stock({
		"name": "두산로보틱스", "code": "454910", "rate": 4.5, "price": "73,500", "sector": "robot_ai"
	}, "robot_ai", true)
	
	# 5. KB금융 (후열 R 서포터 / 밸류업 대장 고배당)
	var kb = HeroGenerator.generate_hero_from_stock({
		"name": "KB금융", "code": "105560", "rate": 2.8, "price": "84,200", "sector": "finance"
	}, "finance", true)
	
	register_hero(sam)
	register_hero(hynix)
	register_hero(hanmi)
	register_hero(doosan)
	register_hero(kb)
	
	# 슬롯 자동 배치
	party_slots[0] = sam
	party_slots[1] = hynix
	party_slots[2] = hanmi
	party_slots[3] = doosan
	party_slots[4] = kb
	
	save_party_data()

# ------------------------------------------------------------------------------
# 📥 영웅 획득 / 등록
# ------------------------------------------------------------------------------
func register_hero(hero_data: Dictionary):
	var hid = hero_data["id"]
	if not unlocked_heroes.has(hid):
		unlocked_heroes[hid] = hero_data
		hero_unlocked.emit(hero_data)
	else:
		# 중복 획득 시 지분(승급 조각) 누적
		unlocked_heroes[hid]["stake_shares"] += 1
		print("[PartyManager] %s 지분 추가 획득! 현재 지분: %d주" % [hero_data["name"], unlocked_heroes[hid]["stake_shares"]])

# ------------------------------------------------------------------------------
# 🔄 파티 슬롯 배정 / 교체
# ------------------------------------------------------------------------------
func assign_hero_to_slot(slot_idx: int, hero_id: String) -> bool:
	if slot_idx < 0 or slot_idx >= MAX_PARTY_SLOTS:
		return false
	if not unlocked_heroes.has(hero_id):
		return false
		
	var target_hero = unlocked_heroes[hero_id]
	
	# 이미 다른 슬롯에 배치되어 있다면 해당 슬롯과 스왑
	for i in range(MAX_PARTY_SLOTS):
		if party_slots[i] != null and party_slots[i]["id"] == hero_id:
			party_slots[i] = party_slots[slot_idx]
			break
			
	party_slots[slot_idx] = target_hero
	update_party_synergies()
	save_party_data()
	party_updated.emit()
	return true

func remove_from_slot(slot_idx: int):
	if slot_idx >= 0 and slot_idx < MAX_PARTY_SLOTS:
		party_slots[slot_idx] = null
		update_party_synergies()
		save_party_data()
		party_updated.emit()

# ------------------------------------------------------------------------------
# ⚡ 포트폴리오 시너지 연산 (Synergy Engine)
# ------------------------------------------------------------------------------
func update_party_synergies():
	active_synergies.clear()
	
	var sector_counts: Dictionary = {}
	var attribute_counts: Dictionary = {}
	
	for slot in party_slots:
		if slot == null:
			continue
		var sec = slot.get("sector", "")
		var attr = slot.get("attribute", HeroGenerator.HeroAttribute.BULL)
		
		sector_counts[sec] = sector_counts.get(sec, 0) + 1
		attribute_counts[attr] = attribute_counts.get(attr, 0) + 1
	
	# 1. 섹터별 시너지 체크
	if sector_counts.get("semiconductor", 0) >= 3:
		active_synergies.append({
			"name": "🔥 AI 반도체 동맹 (3종목)",
			"desc": "파티 전체 치명타 피해량 +40%, 방어 관통력 +20%",
			"buff_crit_dmg": 0.40,
			"buff_pen": 0.20
		})
	elif sector_counts.get("semiconductor", 0) >= 2:
		active_synergies.append({
			"name": "✨ AI 반도체 동맹 (2종목)",
			"desc": "파티 전체 치명타 확률 +15%",
			"buff_crit_rate": 0.15
		})
		
	if sector_counts.get("power_grid", 0) >= 2 or sector_counts.get("us_power_smr", 0) >= 2:
		active_synergies.append({
			"name": "⚡ K-원전 르네상스 (2종목)",
			"desc": "스킬 쿨타임 20% 단축 및 초기 모멘텀 30% 충전",
			"buff_cooldown": 0.20
		})
		
	if sector_counts.get("finance", 0) >= 2 or sector_counts.get("us_wallst_banks", 0) >= 2:
		active_synergies.append({
			"name": "💰 황금 밸류업 (2종목)",
			"desc": "방치 배당금 획득량 +30%, 파티 최대 체력 +20%",
			"buff_dividend": 0.30,
			"buff_hp": 0.20
		})
		
	if sector_counts.get("battery", 0) >= 2:
		active_synergies.append({
			"name": "🔋 캐즘 극복 퀀텀 (2종목)",
			"desc": "적 전체 공격력 20% 감소, 도트 피해 50% 증폭",
			"debuff_enemy_atk": 0.20
		})
		
	if sector_counts.get("shipbuilding", 0) >= 2:
		active_synergies.append({
			"name": "⚓ 해상 도크 철옹성 (2종목)",
			"desc": "파티 전체 방어력 +35%, 넉백 저항 100%",
			"buff_def": 0.35
		})
		
	# 2. 속성 밸런스 체크 (4색 올웨더 포트폴리오)
	if attribute_counts.size() >= 4:
		active_synergies.append({
			"name": "🌐 올웨더 4색 포트폴리오 (완전 분산)",
			"desc": "전 속성 공격력 +20%, 받는 모든 피해 -15%",
			"buff_all_atk": 0.20,
			"buff_dmg_reduction": 0.15
		})
		
	synergy_changed.emit(active_synergies)

# ------------------------------------------------------------------------------
# 📊 파티 종합 지표 계산 (Combat Power & Dividend)
# ------------------------------------------------------------------------------
func get_total_combat_power() -> int:
	var total_cp: int = 0
	for slot in party_slots:
		if slot != null:
			total_cp += slot.get("combat_power", 0)
			
	# 시너지 가산
	for syn in active_synergies:
		if syn.has("buff_all_atk") or syn.has("buff_crit_dmg"):
			total_cp = int(total_cp * 1.15)
	return total_cp

func get_total_dividend_rate() -> float:
	var total_rate: float = 0.0
	for slot in party_slots:
		if slot != null:
			total_rate += slot.get("dividend_yield", 0.0)
			
	for syn in active_synergies:
		if syn.has("buff_dividend"):
			total_rate += syn["buff_dividend"] * 10.0
	return snappedf(total_rate, 0.1)

func get_active_hero_list() -> Array:
	var list = []
	for slot in party_slots:
		if slot != null:
			list.append(slot)
	return list

# ------------------------------------------------------------------------------
# 💾 저장 및 불러오기
# ------------------------------------------------------------------------------
func save_party_data():
	var save_dict = {
		"slots": [],
		"heroes": unlocked_heroes
	}
	for slot in party_slots:
		if slot == null:
			save_dict["slots"].append("")
		else:
			save_dict["slots"].append(slot["id"])
			
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save_dict, "\t"))
		f.close()

func load_party_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var json_str = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return
	var data = json.get_data()
	if not data is Dictionary:
		return
		
	if data.has("heroes") and data["heroes"] is Dictionary:
		unlocked_heroes = data["heroes"]
		
	if data.has("slots") and data["slots"] is Array:
		var slot_ids = data["slots"]
		for i in range(min(slot_ids.size(), MAX_PARTY_SLOTS)):
			var hid = slot_ids[i]
			if not hid.is_empty() and unlocked_heroes.has(hid):
				party_slots[i] = unlocked_heroes[hid]
			else:
				party_slots[i] = null
