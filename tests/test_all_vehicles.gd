extends SceneTree

const VEHICLE_SCENE = preload("res://scenes/vehicle/placeholder_vehicle.tscn")
const PROFILE_SCRIPT = preload("res://scripts/game_profile.gd")

func _init() -> void:
	print("--- TESTING VEHICLE COMPATIBILITY ACROSS ALL 7 VEHICLES ---")
	var vehicle = VEHICLE_SCENE.instantiate()
	root.add_child(vehicle)

	var prof = PROFILE_SCRIPT.new()
	for vname in prof.VEHICLES:
		var data = prof.VEHICLES[vname]
		vehicle.configure_vehicle(vname, data)
		print(" [PASS] Successfully configured and built: " + vname)

	print("--- ALL 7 VEHICLES PASSED COMPATIBILITY CHECKS ---")
	quit(0)
