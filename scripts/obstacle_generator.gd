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
	difficulty: RefCounted
) -> int:
	if chunk_index <= 0:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + chunk_index * 104729
	var profile: Dictionary = difficulty.get_profile(absf(z_start))
	var count := 0
	var placed_z: Array[float] = []
	var candidate_count := 2 + int(profile["obstacle_density"] * 4.0)
	for index in range(candidate_count):
		var z := rng.randf_range(z_start + 5.0, z_end - 5.0)
		if absf(z) < 18.0:
			continue
		var too_close := false
		for previous_z: float in placed_z:
			if absf(z - previous_z) < 5.5:
				too_close = true
				break
		if too_close:
			continue
		var chance := rng.randf()
		var spawn_chance: float = 0.32 + float(profile["obstacle_density"]) * 0.7
		if chance > spawn_chance:
			continue
		var kind := "small_rock"
		var distance := absf(z)
		if distance >= 1000.0 and rng.randf() < float(profile["rope_bridge_chance"]):
			kind = "rope_bridge"
		elif rng.randf() < float(profile["ramp_chance"]):
			kind = "ramp"
		elif rng.randf() < float(profile["large_obstacle_chance"]):
			kind = "large_rock"
		elif rng.randf() < 0.22:
			kind = "rock_cluster"
		elif rng.randf() < 0.25:
			kind = "log"
		elif rng.randf() < 0.18:
			kind = "barrier"
		var obstacle := _create_obstacle(kind, rng, terrain.get_height(z))
		var slope: float = (terrain.get_height(z - 0.1) - terrain.get_height(z + 0.1)) * 5.0
		obstacle.rotation.x = atan(slope)
		obstacle.position.x = 0.0
		obstacle.position.z = z
		parent.add_child(obstacle)
		placed_z.append(z)
		count += 1
	for bridge_distance in range(1024, 5000, 512):
		var bridge_z := -float(bridge_distance)
		if bridge_z >= z_start + 5.0 and bridge_z <= z_end - 5.0:
			var bridge := _create_obstacle("rope_bridge", rng, terrain.get_height(bridge_z))
			var bridge_slope: float = (terrain.get_height(bridge_z - 0.1) - terrain.get_height(bridge_z + 0.1)) * 5.0
			bridge.rotation.x = atan(bridge_slope)
			bridge.position.x = 0.0
			bridge.position.z = bridge_z
			parent.add_child(bridge)
			count += 1
	return count


func _create_obstacle(kind: String, rng: RandomNumberGenerator, ground_height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CollisionObstacle_%s" % kind
	var collision := CollisionShape3D.new()
	var visual := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.roughness = 0.9

	if kind == "log":
		var length := rng.randf_range(1.3, 2.0)
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.22
		mesh.bottom_radius = 0.22
		mesh.height = length
		mesh.radial_segments = 10
		mesh.material = material
		visual.mesh = mesh
		visual.rotation_degrees = Vector3(0.0, 90.0, 90.0)
		collision.rotation_degrees = visual.rotation_degrees
		var shape := CylinderShape3D.new()
		shape.radius = 0.22
		shape.height = length
		collision.shape = shape
		body.position.y = ground_height + 0.22
		material.albedo_color = Color(0.3, 0.16, 0.08)
	elif kind == "ramp":
		var mesh := BoxMesh.new()
		mesh.size = Vector3(3.0, 0.45, 2.8)
		mesh.material = material
		visual.mesh = mesh
		visual.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
		collision.rotation_degrees = visual.rotation_degrees
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		collision.shape = shape
		body.position.y = ground_height + mesh.size.y * 0.5
		material.albedo_color = Color(0.46, 0.28, 0.12)
	elif kind == "barrier":
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.2, 0.7, 0.32)
		mesh.material = material
		visual.mesh = mesh
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		collision.shape = shape
		body.position.y = ground_height + mesh.size.y * 0.5
		material.albedo_color = Color(0.68, 0.33, 0.08)
	elif kind == "rock_cluster":
		for rock_index in range(3):
			var radius := 0.22 + rng.randf_range(0.0, 0.16)
			var rock_mesh := SphereMesh.new()
			rock_mesh.radius = radius
			rock_mesh.height = radius * 1.5
			rock_mesh.radial_segments = 8
			rock_mesh.rings = 4
			rock_mesh.material = material
			var rock_visual := MeshInstance3D.new()
			rock_visual.mesh = rock_mesh
			rock_visual.position = Vector3((rock_index - 1) * 0.38, radius * 0.62, rng.randf_range(-0.18, 0.18))
			visual.add_child(rock_visual)
			var rock_shape := CollisionShape3D.new()
			var shape := SphereShape3D.new()
			shape.radius = radius
			rock_shape.shape = shape
			rock_shape.position = Vector3(
				rock_visual.position.x,
				ground_height + radius * 0.62,
				rock_visual.position.z
			)
			body.add_child(rock_shape)
		visual.position.y = ground_height
		body.position.y = 0.0
		material.albedo_color = Color(0.26, 0.28, 0.27)
	elif kind == "rope_bridge":
		var bridge_material := StandardMaterial3D.new()
		bridge_material.albedo_color = Color(0.42, 0.22, 0.09)
		bridge_material.roughness = 0.95
		var rope_material := StandardMaterial3D.new()
		rope_material.albedo_color = Color(0.16, 0.10, 0.055)
		rope_material.roughness = 1.0
		var plank_count := 8
		var plank_spacing := 0.68
		for plank_index in range(plank_count):
			var plank_z := (float(plank_index) - 3.5) * plank_spacing
			var sag := 0.16 * sin(float(plank_index) / float(plank_count - 1) * PI)
			var plank_mesh := BoxMesh.new()
			plank_mesh.size = Vector3(6.6, 0.18, 0.52)
			plank_mesh.material = bridge_material
			var plank_visual := MeshInstance3D.new()
			plank_visual.mesh = plank_mesh
			plank_visual.position = Vector3(0.0, sag, plank_z)
			plank_visual.rotation.x = sin(float(plank_index) * 0.8) * 0.035
			visual.add_child(plank_visual)
			var plank_collision := CollisionShape3D.new()
			var plank_shape := BoxShape3D.new()
			plank_shape.size = plank_mesh.size
			plank_collision.shape = plank_shape
			plank_collision.position = plank_visual.position
			plank_collision.rotation = plank_visual.rotation
			body.add_child(plank_collision)
		for side_x in [-2.95, 2.95]:
			for rope_index in range(plank_count - 1):
				var start_z := (float(rope_index) - 3.5) * plank_spacing
				var end_z := (float(rope_index + 1) - 3.5) * plank_spacing
				var start := Vector3(side_x, 0.42 + 0.16 * sin(float(rope_index) / 7.0 * PI), start_z)
				var end := Vector3(side_x, 0.42 + 0.16 * sin(float(rope_index + 1) / 7.0 * PI), end_z)
				_add_segment(visual, start, end, 0.045, rope_material)
		material.albedo_color = Color(0.3, 0.16, 0.07)
		body.position.y = ground_height + 0.06
	else:
		var radius := 0.32 if kind == "small_rock" else 0.58
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 1.5
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh.material = material
		visual.mesh = mesh
		var shape := SphereShape3D.new()
		shape.radius = radius
		collision.shape = shape
		body.position.y = ground_height + radius * 0.62
		material.albedo_color = Color(0.24, 0.25, 0.22) if kind == "small_rock" else Color(0.18, 0.2, 0.19)

	body.add_child(collision)
	body.add_child(visual)
	return body


func _add_segment(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var segment := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 8
	segment.mesh = mesh
	segment.material_override = material
	var delta := end - start
	segment.position = (start + end) * 0.5
	segment.basis = Basis(Quaternion(Vector3.UP, delta.normalized()))
	segment.scale = Vector3(radius, delta.length() * 0.5, radius)
	parent.add_child(segment)
