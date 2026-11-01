extends RefCounted
class_name ObstacleGenerator


func populate_chunk(
	parent: Node3D,
	chunk_index: int,
	z_start: float,
	z_end: float,
	seed_value: int,
	terrain_width: float,
	terrain: Node3D,
	difficulty: RefCounted,
	stage_theme: String = "Highlands"
) -> int:
	if chunk_index <= 0:
		return 0

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + chunk_index * 104729 + stage_theme.hash()
	var profile: Dictionary = difficulty.get_profile(absf(z_start), stage_theme)
	var count := 0
	var placed_z: Array[float] = []

	var candidate_count := 2 + int(float(profile["obstacle_density"]) * 4.5)
	for _index in range(candidate_count):
		var z := rng.randf_range(z_start + 4.5, z_end - 4.5)
		if absf(z) < 18.0:
			continue

		var too_close := false
		for prev_z: float in placed_z:
			if absf(z - prev_z) < 5.8:
				too_close = true
				break
		if too_close:
			continue

		var roll := rng.randf()
		var spawn_chance: float = 0.35 + float(profile["obstacle_density"]) * 0.65
		if roll > spawn_chance:
			continue

		var kind := _pick_obstacle_kind(stage_theme, profile, rng)
		var obstacle := _create_world_obstacle(kind, stage_theme, rng, terrain.get_height(z))
		var slope: float = (terrain.get_height(z - 0.1) - terrain.get_height(z + 0.1)) * 5.0
		obstacle.rotation.x = atan(slope)
		obstacle.position.x = 0.0
		obstacle.position.z = z
		parent.add_child(obstacle)
		placed_z.append(z)
		count += 1

	# Rope bridges specifically for Highlands
	if stage_theme == "Highlands":
		for bridge_dist in range(1024, 6000, 768):
			var bridge_z := -float(bridge_dist)
			if bridge_z >= z_start + 6.0 and bridge_z <= z_end - 6.0:
				var bridge := _create_rope_bridge(rng, terrain.get_height(bridge_z))
				var bridge_slope: float = (terrain.get_height(bridge_z - 0.1) - terrain.get_height(bridge_z + 0.1)) * 5.0
				bridge.rotation.x = atan(bridge_slope)
				bridge.position.x = 0.0
				bridge.position.z = bridge_z
				parent.add_child(bridge)
				count += 1

	return count


func _pick_obstacle_kind(stage_theme: String, profile: Dictionary, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	var ramp_chance := float(profile["ramp_chance"])
	var large_chance := float(profile["large_obstacle_chance"])

	match stage_theme:
		"Desert":
			if roll < ramp_chance:
				return "dune_ramp"
			elif roll < ramp_chance + large_chance:
				return "sandstone_monolith"
			elif roll < 0.65:
				return "cactus_cluster"
			else:
				return "desert_rock"

		"Highway":
			if roll < ramp_chance:
				return "overpass_ramp"
			elif roll < ramp_chance + large_chance:
				return "abandoned_wreck"
			elif roll < 0.62:
				return "jersey_barrier"
			else:
				return "highway_sign"

		"Snow":
			if roll < ramp_chance:
				return "snow_jump"
			elif roll < ramp_chance + large_chance:
				return "ice_spire"
			elif roll < 0.60:
				return "snowdrift"
			else:
				return "frozen_log"

		"Mars":
			if roll < ramp_chance:
				return "martian_ridge_ramp"
			elif roll < ramp_chance + large_chance:
				return "alien_spire"
			elif roll < 0.62:
				return "rover_wreckage"
			else:
				return "martian_boulder"

		"Moon":
			if roll < ramp_chance:
				return "crater_lip_ramp"
			elif roll < ramp_chance + large_chance:
				return "apollo_module"
			elif roll < 0.60:
				return "space_monolith"
			else:
				return "lunar_boulder"

		_: # Highlands default
			if roll < ramp_chance:
				return "wooden_ramp"
			elif roll < ramp_chance + large_chance:
				return "large_boulder"
			elif roll < 0.58:
				return "fallen_log"
			elif roll < 0.78:
				return "mud_pit"
			else:
				return "small_rock"


func _create_world_obstacle(kind: String, stage_theme: String, rng: RandomNumberGenerator, ground_height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CollisionObstacle_%s" % kind

	match kind:
		"wooden_ramp", "dune_ramp", "overpass_ramp", "snow_jump", "martian_ridge_ramp", "crater_lip_ramp":
			_build_ramp(body, kind, stage_theme, rng, ground_height)
		"fallen_log", "frozen_log":
			_build_log(body, kind, stage_theme, rng, ground_height)
		"cactus_cluster":
			_build_cactus(body, rng, ground_height)
		"jersey_barrier":
			_build_barrier(body, ground_height)
		"abandoned_wreck", "rover_wreckage", "apollo_module":
			_build_wreckage(body, kind, ground_height)
		"ice_spire", "alien_spire", "space_monolith", "sandstone_monolith":
			_build_spire(body, kind, ground_height)
		"snowdrift", "mud_pit":
			_build_ground_hazard(body, kind, ground_height)
		_:
			_build_boulder(body, kind, stage_theme, rng, ground_height)

	return body


func _build_ramp(body: StaticBody3D, kind: String, stage_theme: String, rng: RandomNumberGenerator, ground_h: float) -> void:
	var width := 4.2
	var length := 3.2
	var height := 0.55

	var mat := StandardMaterial3D.new()
	mat.roughness = 0.85
	match stage_theme:
		"Desert":
			mat.albedo_color = Color(0.72, 0.44, 0.22)
		"Highway":
			mat.albedo_color = Color(0.18, 0.20, 0.24)
			mat.metallic = 0.25
		"Snow":
			mat.albedo_color = Color(0.85, 0.92, 0.98)
		"Mars":
			mat.albedo_color = Color(0.55, 0.20, 0.12)
		"Moon":
			mat.albedo_color = Color(0.35, 0.38, 0.42)
		_:
			mat.albedo_color = Color(0.42, 0.26, 0.14)

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, length)
	mesh.material = mat
	mesh_inst.mesh = mesh
	mesh_inst.rotation_degrees.x = -9.5

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	col.shape = shape
	col.rotation_degrees = mesh_inst.rotation_degrees

	body.position.y = ground_h + height * 0.48
	body.add_child(col)
	body.add_child(mesh_inst)


func _build_log(body: StaticBody3D, kind: String, stage_theme: String, rng: RandomNumberGenerator, ground_h: float) -> void:
	var radius := 0.24
	var length := rng.randf_range(1.6, 2.4)
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.95
	mat.albedo_color = Color(0.25, 0.16, 0.08) if kind == "fallen_log" else Color(0.20, 0.28, 0.32)

	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.material = mat
	mesh_inst.mesh = mesh
	mesh_inst.rotation_degrees = Vector3(0.0, 90.0, 90.0)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = length
	col.shape = shape
	col.rotation_degrees = mesh_inst.rotation_degrees

	body.position.y = ground_h + radius
	body.add_child(col)
	body.add_child(mesh_inst)


func _build_cactus(body: StaticBody3D, rng: RandomNumberGenerator, ground_h: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.42, 0.14)
	mat.roughness = 0.88

	var trunk_h := 1.4
	var trunk_r := 0.14
	var trunk := MeshInstance3D.new()
	var t_mesh := CylinderMesh.new()
	t_mesh.top_radius = trunk_r
	t_mesh.bottom_radius = trunk_r
	t_mesh.height = trunk_h
	t_mesh.material = mat
	trunk.mesh = t_mesh

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = trunk_r
	shape.height = trunk_h
	col.shape = shape

	body.position.y = ground_h + trunk_h * 0.5
	body.add_child(col)
	body.add_child(trunk)


func _build_barrier(body: StaticBody3D, ground_h: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.68, 0.70)
	mat.roughness = 0.9

	var sz := Vector3(1.4, 0.75, 0.38)
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = sz
	mesh.material = mat
	mesh_inst.mesh = mesh

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape

	body.position.y = ground_h + sz.y * 0.5
	body.add_child(col)
	body.add_child(mesh_inst)


func _build_wreckage(body: StaticBody3D, kind: String, ground_h: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.6
	mat.metallic = 0.7
	if kind == "apollo_module":
		mat.albedo_color = Color(0.85, 0.75, 0.32)
	elif kind == "rover_wreckage":
		mat.albedo_color = Color(0.72, 0.75, 0.80)
	else:
		mat.albedo_color = Color(0.35, 0.18, 0.12) # Rusty truck wreck

	var sz := Vector3(1.6, 0.65, 1.8)
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = sz
	mesh.material = mat
	mesh_inst.mesh = mesh

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape

	body.position.y = ground_h + sz.y * 0.5
	body.add_child(col)
	body.add_child(mesh_inst)


func _build_spire(body: StaticBody3D, kind: String, ground_h: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.75
	match kind:
		"ice_spire":
			mat.albedo_color = Color(0.65, 0.88, 1.0)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.85
		"alien_spire":
			mat.albedo_color = Color(0.28, 0.08, 0.08)
		"space_monolith":
			mat.albedo_color = Color(0.08, 0.09, 0.10)
			mat.metallic = 0.8
		_:
			mat.albedo_color = Color(0.65, 0.38, 0.20)

	var h := 1.8
	var r := 0.28
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.04
	mesh.bottom_radius = r
	mesh.height = h
	mesh.material = mat
	mesh_inst.mesh = mesh

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r
	shape.height = h
	col.shape = shape

	body.position.y = ground_h + h * 0.5
	body.add_child(col)
	body.add_child(mesh_inst)


func _build_ground_hazard(body: StaticBody3D, kind: String, ground_h: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.95
	mat.albedo_color = Color(0.20, 0.14, 0.08) if kind == "mud_pit" else Color(0.92, 0.96, 1.0)

	var sz := Vector3(3.6, 0.12, 2.4)
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = sz
	mesh.material = mat
	mesh_inst.mesh = mesh

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape

	body.position.y = ground_h + 0.04
	body.add_child(col)
	body.add_child(mesh_inst)


func _build_boulder(body: StaticBody3D, kind: String, stage_theme: String, rng: RandomNumberGenerator, ground_h: float) -> void:
	var radius := 0.28 if kind == "small_rock" else 0.48
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.92

	match stage_theme:
		"Desert":
			mat.albedo_color = Color(0.55, 0.32, 0.16)
		"Highway":
			mat.albedo_color = Color(0.35, 0.36, 0.38)
		"Snow":
			mat.albedo_color = Color(0.45, 0.52, 0.58)
		"Mars":
			mat.albedo_color = Color(0.48, 0.15, 0.08)
		"Moon":
			mat.albedo_color = Color(0.28, 0.30, 0.34)
		_:
			mat.albedo_color = Color(0.36, 0.38, 0.35)

	var mesh_inst := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.5
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = mat
	mesh_inst.mesh = mesh

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	col.shape = shape

	body.position.y = ground_h + radius * 0.62
	body.add_child(col)
	body.add_child(mesh_inst)


func _create_rope_bridge(rng: RandomNumberGenerator, ground_height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CollisionObstacle_rope_bridge"

	var bridge_mat := StandardMaterial3D.new()
	bridge_mat.albedo_color = Color(0.42, 0.24, 0.12)
	bridge_mat.roughness = 0.95

	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.18, 0.12, 0.06)
	rope_mat.roughness = 1.0

	var plank_count := 8
	var plank_spacing := 0.72
	for i in range(plank_count):
		var plank_z := (float(i) - 3.5) * plank_spacing
		var sag := 0.18 * sin(float(i) / float(plank_count - 1) * PI)

		var plank_inst := MeshInstance3D.new()
		var p_mesh := BoxMesh.new()
		p_mesh.size = Vector3(6.8, 0.18, 0.54)
		p_mesh.material = bridge_mat
		plank_inst.mesh = p_mesh
		plank_inst.position = Vector3(0.0, sag, plank_z)
		plank_inst.rotation.x = sin(float(i) * 0.8) * 0.035
		body.add_child(plank_inst)

		var p_col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = p_mesh.size
		p_col.shape = shape
		p_col.position = plank_inst.position
		p_col.rotation = plank_inst.rotation
		body.add_child(p_col)

	body.position.y = ground_height + 0.06
	return body
