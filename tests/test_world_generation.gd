extends SceneTree

const DIFFICULTY_MANAGER = preload("res://scripts/difficulty_manager.gd")
const PROCEDURAL_TERRAIN = preload("res://scripts/procedural_terrain.gd")

func _init() -> void:
	print("--- BEGINNING WORLD GENERATION & PHYSICS VALIDATION ---")
	var diff_mgr = DIFFICULTY_MANAGER.new()
	var worlds = ["Highlands", "Desert", "Highway", "Snow", "Mars", "Moon"]

	# Test 1: Validate World Profiles
	for world_name in worlds:
		var cfg = diff_mgr.get_world_config(world_name)
		assert(cfg != null and not cfg.is_empty(), "Missing world profile for: " + world_name)
		assert(cfg.has("gravity"), "Missing gravity in: " + world_name)
		assert(cfg.has("grip"), "Missing grip in: " + world_name)
		assert(cfg.has("rolling_resistance"), "Missing rolling resistance in: " + world_name)
		assert(cfg.has("air_pitch"), "Missing air pitch in: " + world_name)
		assert(cfg.has("terrain_amplitude"), "Missing terrain amplitude in: " + world_name)
		print(" [PASS] Profile valid for: %s (Gravity: %.2fg, Grip: %.2fx, RollResist: %.2f)" % [
			world_name, cfg["gravity"], cfg["grip"], cfg["rolling_resistance"]
		])

	# Test 2: Verify Seeded Procedural Terrain Generation per World
	print("\n--- TESTING SEEDED TERRAIN HEIGHTS ACROSS WORLDS ---")
	var dummy_root = Node3D.new()
	root.add_child(dummy_root)

	# Add mock vehicle for terrain height tracking
	var mock_vehicle = Node3D.new()
	mock_vehicle.name = "PlaceholderVehicle"
	dummy_root.add_child(mock_vehicle)

	var terrain = PROCEDURAL_TERRAIN.new()
	dummy_root.add_child(terrain)

	for world_name in worlds:
		terrain.set_stage_theme(world_name)
		var h0 = terrain.get_height(0.0)
		var h50 = terrain.get_height(-50.0)
		var h100 = terrain.get_height(-100.0)
		var h200 = terrain.get_height(-200.0)
		# Determinism test
		var h0_repeat = terrain.get_height(0.0)
		var h100_repeat = terrain.get_height(-100.0)
		assert(is_equal_approx(h0, h0_repeat), "Height at 0 is not deterministic for " + world_name)
		assert(is_equal_approx(h100, h100_repeat), "Height at -100 is not deterministic for " + world_name)
		# Verify no NaN or Inf
		assert(not is_nan(h0) and not is_inf(h0), "Height is NaN/Inf for " + world_name)
		assert(not is_nan(h50) and not is_inf(h50), "Height is NaN/Inf for " + world_name)
		assert(not is_nan(h100) and not is_inf(h100), "Height is NaN/Inf for " + world_name)
		print(" [PASS] Terrain heights deterministic & valid for %s: h(0)=%.2fm, h(100)=%.2fm, h(200)=%.2fm" % [
			world_name, h0, h100, h200
		])

	print("\n--- ALL WORLD GENERATION TESTS PASSED SUCCESSFULLY! ---")
	quit(0)

