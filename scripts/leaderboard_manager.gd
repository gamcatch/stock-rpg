extends Node

# Leaderboard & Achievement Manager

const SAVE_PATH = "user://stock_records.json"

signal achievement_unlocked(ach_id, ach_name, ach_desc)

var high_scores: Array = [] # [{ "date": "...", "return": 1420.5, "time": 180, "kills": 80 }]
var achievements = {
	"first_margin_call": { "name": "첫 깡통의 눈물", "desc": "첫 게임 오버를 당했습니다.", "unlocked": false },
	"moon_shot": { "name": "화성 갈끄니까!", "desc": "수익률 +50% 이상을 달성했습니다.", "unlocked": false },
	"super_rich": { "name": "슈퍼 개미 탄생", "desc": "수익률 +100% 이상을 달성했습니다.", "unlocked": false },
	"leverage_master": { "name": "야수의 심장", "desc": "100배 레버리지를 켜고 1분 이상 생존했습니다.", "unlocked": false },
	"trump_slayer": { "name": "관세맨 길들이기", "desc": "주요 결전 보스 트럼프를 격파하고 글로벌 증시를 수호했습니다.", "unlocked": false }
}

func _ready():
	load_data()

func save_record(portfolio_return: float, game_time: float, kills: int) -> bool:
	var date_str = Time.get_datetime_string_from_system(false, true).substr(0, 16)
	var new_entry = {
		"date": date_str,
		"return": portfolio_return,
		"time": int(game_time),
		"kills": kills
	}
	
	high_scores.append(new_entry)
	high_scores.sort_custom(func(a, b): return a["return"] > b["return"])
	if high_scores.size() > 5:
		high_scores = high_scores.slice(0, 5)
		
	# Check Achievements (방치형 지속 플레이에 맞춘 현실적인 수익률 구간)
	if portfolio_return >= 50.0:
		unlock_achievement("moon_shot")
	if portfolio_return >= 100.0:
		unlock_achievement("super_rich")
		
	save_data()
	return high_scores.has(new_entry)

func unlock_achievement(ach_id: String):
	if achievements.has(ach_id) and not achievements[ach_id]["unlocked"]:
		achievements[ach_id]["unlocked"] = true
		save_data()
		SoundManager.haptic_pulse()
		emit_signal("achievement_unlocked", ach_id, achievements[ach_id]["name"], achievements[ach_id]["desc"])

func save_data():
	var data = {
		"high_scores": high_scores,
		"achievements": achievements
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(content)
		if parse_result == OK and typeof(json.data) == TYPE_DICTIONARY:
			var data = json.data
			if data.has("high_scores") and typeof(data["high_scores"]) == TYPE_ARRAY:
				high_scores = data["high_scores"]
			if data.has("achievements") and typeof(data["achievements"]) == TYPE_DICTIONARY:
				for k in data["achievements"].keys():
					if achievements.has(k):
						achievements[k]["unlocked"] = data["achievements"][k].get("unlocked", false)
