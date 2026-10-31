extends Node
class_name GameProfileStore

const SAVE_PATH := "user://car_driving_profile.json"

var coins := 0
var best_distance := 0.0
var selected_vehicle := "Buggy"
var selected_stage := "Highlands"
var master_volume := 1.0
var music_volume := 1.0
var effects_volume := 1.0
var graphics_quality := "High"

const VEHICLES := {
	"Buggy": {"price": 0, "torque": 1.0, "grip": 1.0, "nitro": 1.0, "color": Color(1.0, 0.18, 0.015)},
	"Trail Bike": {"price": 1, "torque": 0.78, "grip": 0.86, "nitro": 1.3, "color": Color(0.08, 0.62, 1.0)},
	"Quad Runner": {"price": 1, "torque": 1.12, "grip": 1.18, "nitro": 0.92, "color": Color(0.95, 0.72, 0.08)},
	"Monster Truck": {"price": 1, "torque": 1.38, "grip": 1.28, "nitro": 0.78, "color": Color(0.72, 0.12, 0.08)},
}

const STAGES := {
	"Highlands": {"price": 0, "label": "GREEN HIGHLANDS"},
	"Desert": {"price": 1, "label": "EMBER DESERT"},
	"Highway": {"price": 1, "label": "NEON HIGHWAY"},
	"Snow": {"price": 1, "label": "FROST RUN"},
	"Mars": {"price": 1, "label": "MARS FRONTIER"},
	"Moon": {"price": 1, "label": "LUNAR CRATER"},
}


func _ready() -> void:
	load_profile()


func is_vehicle_unlocked(vehicle_name: String) -> bool:
	return vehicle_name == "Buggy" or coins >= int(VEHICLES[vehicle_name]["price"])


func is_stage_unlocked(stage_name: String) -> bool:
	return stage_name == "Highlands" or coins >= int(STAGES[stage_name]["price"])


func purchase_vehicle(vehicle_name: String) -> bool:
	if not VEHICLES.has(vehicle_name) or is_vehicle_unlocked(vehicle_name):
		return is_vehicle_unlocked(vehicle_name)
	var price := int(VEHICLES[vehicle_name]["price"])
	if coins < price:
		return false
	coins -= price
	save_profile()
	return true


func purchase_stage(stage_name: String) -> bool:
	if not STAGES.has(stage_name) or is_stage_unlocked(stage_name):
		return is_stage_unlocked(stage_name)
	var price := int(STAGES[stage_name]["price"])
	if coins < price:
		return false
	coins -= price
	save_profile()
	return true


func save_profile() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"coins": coins,
		"best_distance": best_distance,
		"selected_vehicle": selected_vehicle,
		"selected_stage": selected_stage,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"effects_volume": effects_volume,
		"graphics_quality": graphics_quality,
	}))


func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	coins = maxi(int(parsed.get("coins", coins)), 0)
	best_distance = maxf(float(parsed.get("best_distance", best_distance)), 0.0)
	selected_vehicle = str(parsed.get("selected_vehicle", selected_vehicle))
	selected_stage = str(parsed.get("selected_stage", selected_stage))
	master_volume = clampf(float(parsed.get("master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(parsed.get("music_volume", music_volume)), 0.0, 1.0)
	effects_volume = clampf(float(parsed.get("effects_volume", effects_volume)), 0.0, 1.0)
	graphics_quality = str(parsed.get("graphics_quality", graphics_quality))
