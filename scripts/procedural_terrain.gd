extends Node3D
class_name ProceduralTerrain

signal coin_collected(value: int)
signal fuel_collected(amount: float)

const DIFFICULTY_MANAGER_SCRIPT = preload("res://scripts/difficulty_manager.gd")
const OBSTACLE_GENERATOR_SCRIPT = preload("res://scripts/obstacle_generator.gd")
const COIN_SCENE = preload("res://scenes/coin.tscn")
const FUEL_SCENE = preload("res://scenes/fuel_can.tscn")
const CHUNK_LENGTH := 32.0
const TERRAIN_WIDTH := 8.0
const SAMPLE_COUNT := 17
const ACTIVE_AHEAD := 8
const ACTIVE_BEHIND := 2

@export var seed_value := 73421
@export var chunk_length := CHUNK_LENGTH
@export var active_ahead := ACTIVE_AHEAD
@export var active_behind := ACTIVE_BEHIND
@export var terrain_width := TERRAIN_WIDTH

var _vehicle: VehicleController
var _chunks: Dictionary = {}
var _features: Array[Dictionary] = []
var _terrain_materials: Array[StandardMaterial3D] = []
var _terrain_side_material: StandardMaterial3D
var _grass_edge_material: StandardMaterial3D
var _grass_material: StandardMaterial3D
var _rock_material: StandardMaterial3D
var _rock_mesh: SphereMesh
var _difficulty = DIFFICULTY_MANAGER_SCRIPT.new()
var _obstacle_generator = OBSTACLE_GENERATOR_SCRIPT.new()
var _last_center_chunk := 999999
var _stage_theme := "Highlands"


func _ready() -> void:
	_vehicle = get_parent().get_node("PlaceholderVehicle") as VehicleController
	_create_materials()
	_create_height_features()
	_update_chunks(true)


func _physics_process(_delta: float) -> void:
	_update_chunks(false)


func get_active_chunk_count() -> int:
	return _chunks.size()


func get_obstacle_count() -> int:
	var count := 0
	for chunk: Node3D in _chunks.values():
		for child: Node in chunk.get_children():
			if child is StaticBody3D and child.name.begins_with("CollisionObstacle_"):
				count += 1
	return count


func get_fuel_count() -> int:
	var count := 0
	for chunk: Node3D in _chunks.values():
		for child: Node in chunk.get_children():
			if child.name.begins_with("FuelCan"):
				count += 1
	return count


func get_coin_count() -> int:
	var count := 0
	for chunk: Node3D in _chunks.values():
		for child: Node in chunk.get_children():
			if child.name.begins_with("Coin"):
				count += 1
	return count


func reset_run() -> void:
	for chunk: Node3D in _chunks.values():
		chunk.free()
	_chunks.clear()
	_last_center_chunk = 999999
	_update_chunks(true)


func set_stage_theme(stage_name: String) -> void:
	_stage_theme = stage_name
	_apply_stage_materials()
	reset_run()


func get_world_config() -> Dictionary:
	return _difficulty.get_world_config(_stage_theme)


func get_difficulty_profile() -> Dictionary:
	return _difficulty.get_profile(absf(_vehicle.global_position.z), _stage_theme)


# ==============================================================================
# REALISTIC PROCEDURAL TERRAIN HEIGHT GENERATORS PER WORLD
# ==============================================================================
func get_height(z: float) -> float:
	# Smooth spawn plateau near start
	if z > -4.0:
		return 0.0

	var profile: Dictionary = _difficulty.get_profile(absf(z), _stage_theme)
	var amp: float = float(profile["terrain_amplitude"])
	var slope_mult: float = float(profile["slope_multiplier"])

	var h := 0.0

	match _stage_theme:
		"Desert":
			# Realistic asymmetric wind-blown sand dunes with slip-faces and deep depressions
			var dune_phase := z * 0.034 + 0.6
			var dune_curve := pow(0.5 + 0.5 * sin(dune_phase), 1.55) * 3.6 - 1.1
			var canyon_wave := sin(z * 0.013 - 0.7) * 1.6
			var sand_ripple := sin(z * 0.17 + 1.2) * 0.22
			h = (dune_curve + canyon_wave + sand_ripple) * amp

		"Highway":
			# Engineered asphalt road grades with overpasses, sudden bridge steps, and road drops
			var road_grade := sin(z * 0.016 + 0.3) * 1.2 + sin(z * 0.054) * 0.35
			var bridge_cycle := fmod(absf(z), 240.0)
			if bridge_cycle > 140.0 and bridge_cycle < 210.0:
				var b_t := (bridge_cycle - 140.0) / 70.0
				road_grade += sin(b_t * PI) * 2.8
			h = road_grade * amp

		"Snow":
			# Glacial mountain slopes with undulating snowbanks and sharp icy moguls
			var snow_waves := sin(z * 0.052) * 2.0 + sin(z * 0.12 + 1.4) * 0.85
			var moguls := absf(sin(z * 0.24 - 0.5)) * 0.48
			var downhill := sin(z * 0.022 - 1.1) * 1.5
			h = (snow_waves + moguls + downhill) * amp

		"Mars":
			# Volcanic plateaus, wide impact basins (craters), and jagged fault scarps
			var plateau := sin(z * 0.024) * 1.8 + sin(z * 0.072 - 0.8) * 1.1
			var crater_cycle := fmod(absf(z) + 60.0, 320.0)
			var crater_offset := 0.0
			if crater_cycle < 120.0:
				var c_t := crater_cycle / 120.0
				crater_offset = (sin(c_t * TAU) * 0.9 - sin(c_t * PI) * 2.6)
			h = (plateau + crater_offset) * amp

		"Moon":
			# Realistic lunar surface: stark craters, sharp crater lips, and deep regolith bowls
			var regolith := sin(z * 0.018 + 0.4) * 1.5 + sin(z * 0.058 - 1.2) * 0.9
			var crater_cycle := fmod(absf(z) + 110.0, 260.0)
			var crater_depth := 0.0
			if crater_cycle < 140.0:
				var c_t := crater_cycle / 140.0
				crater_depth = pow(sin(c_t * PI), 0.75) * -3.4 + sin(c_t * TAU) * 1.1
			h = (regolith + crater_depth) * amp

		_: # Highlands default
			# Rolling green hills, steep mountain climbs, and rocky slopes
			var base := sin(z * 0.048 + 0.6) * 1.6 + sin(z * 0.115 - 0.4) * 0.55 + sin(z * 0.28) * 0.14
			if absf(z) > 800.0:
				var climb := maxf(sin(absf(z) * 0.014 - 0.7), 0.0)
				var crest := maxf(sin(absf(z) * 0.032 + 1.2), 0.0)
				base += (climb * climb * 2.4 + crest * 0.8) * float(profile["climb_progress"])
			h = base * amp

	# Add seeded localized features
	for feature: Dictionary in _features:
		var distance := absf(z - float(feature["center"]))
		var width := float(feature["width"])
		if distance < width:
			var fade := 1.0 - distance / width
			fade = fade * fade * (3.0 - 2.0 * fade)
			h += float(feature["amplitude"]) * fade * slope_mult

	# Smooth spawn blend near start line (from z = -4 to z = -14)
	if z > -14.0:
		var blend := clampf((-z - 4.0) / 10.0, 0.0, 1.0)
		h = lerpf(0.0, h, blend)

	return h


func _update_chunks(force: bool) -> void:
	if _vehicle == null:
		return
	var center_chunk := floori(-_vehicle.global_position.z / chunk_length)
	if not force and center_chunk == _last_center_chunk:
		return
	_last_center_chunk = center_chunk

	for chunk_index in range(center_chunk - active_behind, center_chunk + active_ahead + 1):
		if not _chunks.has(chunk_index):
			_chunks[chunk_index] = _create_chunk(chunk_index)

	var to_remove: Array[int] = []
	for chunk_index: int in _chunks:
		if chunk_index < center_chunk - active_behind or chunk_index > center_chunk + active_ahead:
			to_remove.append(chunk_index)
	for chunk_index: int in to_remove:
		var chunk: Node3D = _chunks[chunk_index]
		chunk.queue_free()
		_chunks.erase(chunk_index)


func _create_height_features() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for index in range(-4, 160):
		var center := -float(index) * 24.0 - rng.randf_range(-6.0, 6.0)
		var amplitude := rng.randf_range(-1.1, 1.4)
		var width := rng.randf_range(6.0, 12.0)
		if index % 8 == 0:
			amplitude = rng.randf_range(1.2, 2.1)
			width = rng.randf_range(10.0, 16.0)
		_features.append({
			"center": center,
			"amplitude": amplitude,
			"width": width,
		})


func _create_chunk(chunk_index: int) -> Node3D:
	var z_end := -float(chunk_index) * chunk_length
	var z_start := z_end - chunk_length
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var top_near_x := terrain_width * 0.5
	var top_far_x := -terrain_width * 0.5

	for sample_index in range(SAMPLE_COUNT):
		var z := lerpf(z_start, z_end, float(sample_index) / float(SAMPLE_COUNT - 1))
		var height := get_height(z)
		var bottom_y := -6.5 + 0.34 * sin(z * 0.075 + 1.2) + 0.16 * sin(z * 0.19)
		var slope := (get_height(z - 0.1) - get_height(z + 0.1)) * 5.0
		var top_normal := Vector3(0.0, 1.0, slope).normalized()
		vertices.append(Vector3(top_near_x, height, z))
		normals.append(top_normal)
		vertices.append(Vector3(top_far_x, height, z))
		normals.append(top_normal)
		vertices.append(Vector3(top_near_x, bottom_y, z))
		normals.append(Vector3(0.0, 0.0, 1.0))
		vertices.append(Vector3(top_far_x, bottom_y, z))
		normals.append(Vector3(0.0, 0.0, 1.0))

	for sample_index in range(SAMPLE_COUNT - 1):
		var current := sample_index * 4
		var next := current + 4
		var near_top_a := current
		var far_top_a := current + 1
		var near_bottom_a := current + 2
		var far_bottom_a := current + 3
		var near_top_b := next
		var far_top_b := next + 1
		var near_bottom_b := next + 2
		var far_bottom_b := next + 3
		indices.append_array(PackedInt32Array([
			near_top_a, near_top_b, far_top_a,
			far_top_a, near_top_b, far_top_b,
			near_top_a, near_bottom_a, near_top_b,
			near_top_b, near_bottom_a, near_bottom_b,
			far_top_a, far_top_b, far_bottom_a,
			far_bottom_a, far_top_b, far_bottom_b,
			near_bottom_a, far_bottom_a, near_bottom_b,
			near_bottom_b, far_bottom_a, far_bottom_b,
		]))

	var mesh := ArrayMesh.new()
	var top_vertices := PackedVector3Array()
	var top_normals := PackedVector3Array()
	var top_indices := PackedInt32Array()
	for sample_index in range(SAMPLE_COUNT):
		var vertex_index := sample_index * 4
		top_vertices.append(vertices[vertex_index])
		top_vertices.append(vertices[vertex_index + 1])
		top_normals.append(normals[vertex_index])
		top_normals.append(normals[vertex_index + 1])
	for sample_index in range(SAMPLE_COUNT - 1):
		var current := sample_index * 2
		var next := current + 2
		top_indices.append_array(PackedInt32Array([
			current, next, current + 1,
			current + 1, next, next + 1,
		]))
	var top_arrays := []
	top_arrays.resize(Mesh.ARRAY_MAX)
	top_arrays[Mesh.ARRAY_VERTEX] = top_vertices
	top_arrays[Mesh.ARRAY_NORMAL] = top_normals
	top_arrays[Mesh.ARRAY_INDEX] = top_indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, top_arrays)

	var side_vertices := PackedVector3Array()
	var side_normals := PackedVector3Array()
	var side_indices := PackedInt32Array()
	for sample_index in range(SAMPLE_COUNT - 1):
		var current := sample_index * 4
		var next := current + 4
		var base := side_vertices.size()
		side_vertices.append_array(PackedVector3Array([
			Vector3(vertices[current].x, vertices[current].y - 0.16, vertices[current].z),
			Vector3(vertices[next].x, vertices[next].y - 0.16, vertices[next].z),
			vertices[current + 2], vertices[next + 2],
		]))
		side_normals.append_array(PackedVector3Array([
			Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0),
			Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0),
		]))
		side_indices.append_array(PackedInt32Array([
			base, base + 2, base + 1,
			base + 1, base + 2, base + 3,
		]))
	var side_arrays := []
	side_arrays.resize(Mesh.ARRAY_MAX)
	side_arrays[Mesh.ARRAY_VERTEX] = side_vertices
	side_arrays[Mesh.ARRAY_NORMAL] = side_normals
	side_arrays[Mesh.ARRAY_INDEX] = side_indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, side_arrays)

	var edge_vertices := PackedVector3Array()
	var edge_normals := PackedVector3Array()
	var edge_indices := PackedInt32Array()
	for sample_index in range(SAMPLE_COUNT - 1):
		var current := sample_index * 4
		var next := current + 4
		var base := edge_vertices.size()
		edge_vertices.append_array(PackedVector3Array([
			vertices[current], vertices[next],
			Vector3(vertices[current].x, vertices[current].y - 0.16, vertices[current].z),
			Vector3(vertices[next].x, vertices[next].y - 0.16, vertices[next].z),
		]))
		edge_normals.append_array(PackedVector3Array([
			Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0),
			Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0),
		]))
		edge_indices.append_array(PackedInt32Array([
			base, base + 2, base + 1,
			base + 1, base + 2, base + 3,
		]))
	var edge_arrays := []
	edge_arrays.resize(Mesh.ARRAY_MAX)
	edge_arrays[Mesh.ARRAY_VERTEX] = edge_vertices
	edge_arrays[Mesh.ARRAY_NORMAL] = edge_normals
	edge_arrays[Mesh.ARRAY_INDEX] = edge_indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, edge_arrays)

	var body := StaticBody3D.new()
	body.name = "TerrainChunk_%d" % chunk_index
	body.position = Vector3.ZERO
	add_child(body)

	var collision := CollisionShape3D.new()
	var collision_shape := ConcavePolygonShape3D.new()
	var triangles := PackedVector3Array()
	for index in range(0, indices.size(), 3):
		triangles.append(vertices[indices[index]])
		triangles.append(vertices[indices[index + 1]])
		triangles.append(vertices[indices[index + 2]])
	collision_shape.set_faces(triangles)
	collision.shape = collision_shape
	body.add_child(collision)

	var visual := MeshInstance3D.new()
	visual.name = "TerrainMesh"
	visual.mesh = mesh
	visual.set_surface_override_material(0, _terrain_materials[0])
	visual.set_surface_override_material(1, _terrain_side_material)
	visual.set_surface_override_material(2, _grass_edge_material)
	body.add_child(visual)

	_add_decorations(body, chunk_index, z_start, z_end)
	_add_coins(body, chunk_index, z_start, z_end)
	_add_fuel(body, chunk_index, z_start, z_end)
	return body


func _add_fuel(parent: Node3D, chunk_index: int, z_start: float, z_end: float) -> void:
	if chunk_index <= 0 or chunk_index % 3 != 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + chunk_index * 32452843
	var z := rng.randf_range(z_start + 8.0, z_end - 8.0)
	var fuel := FUEL_SCENE.instantiate() as Node3D
	fuel.position = Vector3(
		0.0,
		get_height(z) + 1.08,
		z
	)
	fuel.connect("collected", Callable(self, "_on_fuel_collected"))
	parent.add_child(fuel)


func _add_coins(parent: Node3D, chunk_index: int, z_start: float, z_end: float) -> void:
	if chunk_index <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + chunk_index * 15485863
	var profile: Dictionary = _difficulty.get_profile(absf(z_start), _stage_theme)
	var coin_val := _get_coin_value(absf(z_start), rng)
	var pattern := rng.randi_range(0, 3)
	var coin_count := 3 + int(float(profile["climb_progress"]) * 2.0)
	if pattern == 0:
		var line_start := z_start + 7.0
		for index in range(coin_count):
			_spawn_coin(parent, 0.0, line_start - float(index) * 1.15, 1.15, coin_val)
	elif pattern == 1:
		var arc_start := z_start + 8.0
		for index in range(coin_count):
			var progress := float(index) / float(maxi(coin_count - 1, 1))
			var arc_height := 1.0 + sin(progress * PI) * 0.8
			_spawn_coin(parent, 0.0, arc_start - float(index) * 1.05, arc_height, coin_val)
	elif pattern == 2:
		var cluster_z := rng.randf_range(z_start + 8.0, z_end - 8.0)
		for index in range(4):
			var angle := TAU * float(index) / 4.0
			_spawn_coin(parent, sin(angle) * 0.7, cluster_z + cos(angle) * 0.7, 1.35, coin_val)
	else:
		var trail_start := z_start + 6.0
		for index in range(coin_count):
			var z := trail_start - float(index) * 1.2
			var slope := absf((get_height(z - 0.1) - get_height(z + 0.1)) * 5.0)
			_spawn_coin(parent, 0.0, z, 1.0 + slope * 0.22, coin_val)


func _get_coin_value(distance: float, rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	if roll < 0.01 and distance >= 2500.0:
		return 1000
	if roll < 0.04 and distance >= 1800.0:
		return 500
	if roll < 0.10 and distance >= 1200.0:
		return 250
	if distance >= 2500.0:
		return 200
	if distance >= 1800.0:
		return 100
	if distance >= 1100.0:
		return 50
	if distance >= 700.0:
		return 25
	if distance >= 350.0:
		return 20
	if distance >= 150.0:
		return 15
	return 10


func _spawn_coin(parent: Node3D, x: float, z: float, clearance: float, val: int) -> void:
	var coin := COIN_SCENE.instantiate() as Coin
	coin.value = val
	coin.position = Vector3(
		clampf(x, -terrain_width * 0.3, terrain_width * 0.3),
		get_height(z) + clearance,
		z
	)
	coin.connect("collected", Callable(self, "_on_coin_collected"))
	parent.add_child(coin)


func _on_coin_collected(val: int) -> void:
	coin_collected.emit(val)


func _on_fuel_collected(amount: float) -> void:
	fuel_collected.emit(amount)


func _add_decorations(parent: Node3D, chunk_index: int, z_start: float, z_end: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + chunk_index * 7919

	# World-themed decorative rocks
	for index in range(2):
		var z := rng.randf_range(z_start + 2.0, z_end - 2.0)
		var rock := MeshInstance3D.new()
		rock.name = "DecorationRock_%d" % index
		rock.mesh = _rock_mesh
		rock.material_override = _rock_material
		var scale := rng.randf_range(0.18, 0.38)
		rock.scale = Vector3(scale, scale * rng.randf_range(0.65, 1.25), scale)
		rock.position = Vector3(
			rng.randf_range(-terrain_width * 0.42, terrain_width * 0.42),
			get_height(z) + scale * 0.45,
			z
		)
		parent.add_child(rock)

	# World-themed vegetation / surface tufts (Highlands, Desert, Snow)
	if _stage_theme != "Moon":
		for index in range(2):
			var grass_z := rng.randf_range(z_start + 2.5, z_end - 2.5)
			var grass := MeshInstance3D.new()
			grass.name = "SurfaceTuft_%d" % index
			var grass_mesh := CylinderMesh.new()
			grass_mesh.top_radius = 0.01
			grass_mesh.bottom_radius = 0.12
			grass_mesh.height = rng.randf_range(0.25, 0.45)
			grass_mesh.radial_segments = 3
			grass.mesh = grass_mesh
			grass.material_override = _grass_material
			grass.position = Vector3(
				rng.randf_range(-terrain_width * 0.38, terrain_width * 0.38),
				get_height(grass_z) + grass_mesh.height * 0.5,
				grass_z
			)
			grass.rotation.y = rng.randf_range(0.0, TAU)
			parent.add_child(grass)

	# World-specific obstacles
	_obstacle_generator.populate_chunk(
		parent,
		chunk_index,
		z_start,
		z_end,
		seed_value,
		terrain_width,
		self,
		_difficulty,
		_stage_theme
	)


func _create_materials() -> void:
	for _i in range(3):
		var mat := StandardMaterial3D.new()
		mat.roughness = 0.92
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_terrain_materials.append(mat)

	_terrain_side_material = StandardMaterial3D.new()
	_terrain_side_material.roughness = 0.96
	_terrain_side_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_grass_edge_material = StandardMaterial3D.new()
	_grass_edge_material.roughness = 0.95
	_grass_edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	_grass_material = StandardMaterial3D.new()
	_grass_material.roughness = 0.95

	_rock_material = StandardMaterial3D.new()
	_rock_material.roughness = 0.92

	_rock_mesh = SphereMesh.new()
	_rock_mesh.radial_segments = 8
	_rock_mesh.rings = 4
	_rock_mesh.radius = 1.0
	_rock_mesh.height = 1.4

	_apply_stage_materials()


func _apply_stage_materials() -> void:
	if _terrain_materials.is_empty():
		return

	var top_colors: Array[Color]
	var side_color: Color
	var edge_color: Color
	var grass_color: Color
	var rock_color: Color

	match _stage_theme:
		"Desert":
			top_colors = [Color(0.85, 0.56, 0.22), Color(0.92, 0.64, 0.28), Color(0.78, 0.48, 0.18)]
			side_color = Color(0.52, 0.24, 0.10) # Red sandstone canyon strata
			edge_color = Color(0.78, 0.48, 0.16)
			grass_color = Color(0.58, 0.36, 0.12)
			rock_color = Color(0.60, 0.35, 0.18)

		"Highway":
			top_colors = [Color(0.14, 0.16, 0.18), Color(0.18, 0.20, 0.22), Color(0.12, 0.14, 0.16)]
			side_color = Color(0.24, 0.26, 0.28) # Concrete embankment
			edge_color = Color(0.92, 0.75, 0.14) # Yellow road marking edge
			grass_color = Color(0.20, 0.24, 0.26)
			rock_color = Color(0.32, 0.34, 0.36)

		"Snow":
			top_colors = [Color(0.92, 0.96, 1.0), Color(0.96, 0.98, 1.0), Color(0.85, 0.92, 0.98)]
			side_color = Color(0.26, 0.34, 0.42) # Frozen slate
			edge_color = Color(0.75, 0.88, 0.98) # Frost trim
			grass_color = Color(0.50, 0.65, 0.75)
			rock_color = Color(0.40, 0.48, 0.54)

		"Mars":
			top_colors = [Color(0.72, 0.25, 0.12), Color(0.82, 0.32, 0.16), Color(0.62, 0.18, 0.08)]
			side_color = Color(0.32, 0.10, 0.06) # Volcanic basalt
			edge_color = Color(0.65, 0.20, 0.10)
			grass_color = Color(0.45, 0.12, 0.06)
			rock_color = Color(0.52, 0.16, 0.08)

		"Moon":
			top_colors = [Color(0.48, 0.50, 0.52), Color(0.56, 0.58, 0.60), Color(0.40, 0.42, 0.44)]
			side_color = Color(0.18, 0.20, 0.22) # Impact breccia
			edge_color = Color(0.64, 0.66, 0.68) # Crater rim edge
			grass_color = Color(0.22, 0.24, 0.26)
			rock_color = Color(0.32, 0.34, 0.36)

		_: # Highlands
			top_colors = [Color(0.50, 0.74, 0.20), Color(0.56, 0.78, 0.24), Color(0.44, 0.68, 0.17)]
			side_color = Color(0.38, 0.25, 0.17) # Earthy rock strata
			edge_color = Color(0.52, 0.76, 0.18) # Fresh meadow trim
			grass_color = Color(0.48, 0.72, 0.15)
			rock_color = Color(0.42, 0.42, 0.38)

	for index in range(_terrain_materials.size()):
		_terrain_materials[index].albedo_color = top_colors[index]
	_terrain_side_material.albedo_color = side_color
	_grass_edge_material.albedo_color = edge_color
	_grass_material.albedo_color = grass_color
	_rock_material.albedo_color = rock_color
