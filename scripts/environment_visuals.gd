extends Node3D
class_name EnvironmentVisuals

const RIDGE_LENGTH := 320.0
const RIDGE_SAMPLES := 65
const DISTANT_PARALLAX := 0.08
const MIDDLE_PARALLAX := 0.22
const NEAR_PARALLAX := 0.45

@export var seed_value := 73421

var _camera: Camera3D
var _vehicle: VehicleController
var _terrain: Node3D
var _distant_layer: Node3D
var _middle_layer: Node3D
var _near_layer: Node3D
var _star_layer: Node3D
var _tree_material: StandardMaterial3D
var _trunk_material: StandardMaterial3D
var _bush_material: StandardMaterial3D
var _rock_material: StandardMaterial3D
var _last_camera_z := 0.0
var _stage_theme := "Highlands"


func _ready() -> void:
	_camera = get_parent().get_node("SideCamera") as Camera3D
	_vehicle = get_parent().get_node("PlaceholderVehicle") as VehicleController
	_terrain = get_parent().get_node("ProceduralTerrain")
	_create_materials()
	_distant_layer = _create_ridge_layer("DistantMountains", -10.0, 0.08, [
		Color(0.58, 0.70, 0.68),
		Color(0.48, 0.63, 0.63),
		Color(0.39, 0.55, 0.57),
	])
	_middle_layer = _create_ridge_layer("MiddleHills", -6.0, 0.22, [
		Color(0.55, 0.68, 0.47),
		Color(0.44, 0.59, 0.39),
		Color(0.35, 0.51, 0.33),
	])
	_near_layer = Node3D.new()
	_near_layer.name = "NearBackgroundVegetation"
	add_child(_near_layer)
	_create_near_vegetation()
	_create_stars()
	_update_layers(true)


func _process(_delta: float) -> void:
	_update_layers(false)


func set_stage_theme(stage_name: String) -> void:
	_stage_theme = stage_name
	var colors := _stage_colors(stage_name)
	for index in range(_distant_layer.get_child_count()):
		var distant := _distant_layer.get_child(index) as MeshInstance3D
		distant.material_override.albedo_color = colors[0]
	for index in range(_middle_layer.get_child_count()):
		var middle := _middle_layer.get_child(index) as MeshInstance3D
		middle.material_override.albedo_color = colors[1]
	_tree_material.albedo_color = colors[2]
	_bush_material.albedo_color = colors[3]
	_rock_material.albedo_color = colors[4]
	for child in _near_layer.get_children():
		child.free()
	_near_layer.visible = true
	_star_layer.visible = stage_name == "Moon"
	if stage_name == "Highway":
		_create_highway_props()
	elif stage_name == "Desert":
		_create_desert_props()
	elif stage_name == "Snow":
		_create_snow_props()
	elif stage_name == "Mars":
		_create_mars_props()
	elif stage_name == "Moon":
		_create_moon_props()
	else:
		_create_near_vegetation()


func _create_stars() -> void:
	_star_layer = Node3D.new()
	_star_layer.name = "MoonStars"
	add_child(_star_layer)
	var star_material := StandardMaterial3D.new()
	star_material.albedo_color = Color(0.78, 0.88, 1.0)
	star_material.emission_enabled = true
	star_material.emission = Color(0.55, 0.7, 1.0)
	star_material.emission_energy_multiplier = 1.8
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 99117
	for index in range(90):
		var star := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = rng.randf_range(0.012, 0.035)
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 5
		mesh.rings = 3
		star.mesh = mesh
		star.material_override = star_material
		star.position = Vector3(-5.0, rng.randf_range(1.0, 9.0), rng.randf_range(-150.0, 25.0))
		_star_layer.add_child(star)


func _create_highway_props() -> void:
	_near_layer.visible = true
	var road_material := _material(Color(0.06, 0.07, 0.08), 0.82)
	var line_material := _material(Color(0.95, 0.72, 0.16), 0.5)
	for index in range(32):
		var z := -float(index) * 10.0 + 20.0
		_add_box_prop(_near_layer, Vector3(0.04, 0.04, 4.0), Vector3(-2.2, -0.5, z), line_material)
		_add_box_prop(_near_layer, Vector3(0.12, 0.55, 0.12), Vector3(-3.1, -0.1, z), road_material)
		_add_box_prop(_near_layer, Vector3(0.12, 0.55, 0.12), Vector3(-3.1, -0.1, z - 3.6), road_material)


func _create_desert_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 442
	for index in range(30):
		var z := rng.randf_range(-150.0, 20.0)
		_add_cactus(_near_layer, Vector3(-3.1, -0.6, z), rng.randf_range(0.7, 1.4))


func _create_snow_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 778
	for index in range(28):
		var z := rng.randf_range(-150.0, 20.0)
		_add_snow_pine(_near_layer, Vector3(-3.15, -0.65, z), rng.randf_range(0.7, 1.3))


func _create_mars_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 992
	for index in range(34):
		var z := rng.randf_range(-150.0, 20.0)
		_add_mars_rock(_near_layer, Vector3(-3.05, -0.65, z), rng.randf_range(0.35, 0.95))


func _create_moon_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 118
	for index in range(22):
		var crater := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = rng.randf_range(0.25, 0.6)
		mesh.outer_radius = mesh.inner_radius + 0.08
		mesh.ring_segments = 10
		mesh.rings = 6
		crater.mesh = mesh
		crater.material_override = _rock_material
		crater.position = Vector3(-3.0, -0.62, rng.randf_range(-150.0, 20.0))
		crater.rotation.x = PI * 0.5
		crater.scale.y = 0.35
		_near_layer.add_child(crater)


func _add_box_prop(parent: Node3D, size: Vector3, position: Vector3, material: Material) -> void:
	var prop := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	prop.mesh = mesh
	prop.material_override = material
	prop.position = position
	parent.add_child(prop)


func _add_cactus(parent: Node3D, position: Vector3, scale_value: float) -> void:
	var material := _material(Color(0.16, 0.38, 0.14), 0.9)
	var root := Node3D.new()
	root.position = position
	root.scale = Vector3.ONE * scale_value
	parent.add_child(root)
	_add_cylinder_prop(root, Vector3.ZERO, Vector3(0.0, 1.0, 0.0), 0.11, material)
	_add_cylinder_prop(root, Vector3(0.0, 0.45, 0.0), Vector3(0.32, 0.75, 0.0), 0.07, material)
	_add_cylinder_prop(root, Vector3(0.32, 0.7, 0.0), Vector3(0.32, 0.95, 0.0), 0.07, material)


func _add_snow_pine(parent: Node3D, position: Vector3, scale_value: float) -> void:
	var material := _material(Color(0.15, 0.28, 0.32), 0.96)
	var snow := _material(Color(0.9, 0.96, 1.0), 0.92)
	var root := Node3D.new()
	root.position = position
	root.scale = Vector3.ONE * scale_value
	parent.add_child(root)
	_add_cylinder_prop(root, Vector3.ZERO, Vector3(0.0, 1.5, 0.0), 0.08, material)
	for index in range(3):
		_add_cone_prop(root, Vector3(0.0, 0.55 + index * 0.4, 0.0), 0.7 - index * 0.15, material)
		_add_cone_prop(root, Vector3(0.0, 0.62 + index * 0.4, -0.02), 0.57 - index * 0.12, snow)


func _add_mars_rock(parent: Node3D, position: Vector3, scale_value: float) -> void:
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 0.9
	mesh.radial_segments = 7
	mesh.rings = 4
	rock.mesh = mesh
	rock.material_override = _rock_material
	rock.position = position
	rock.scale = Vector3(scale_value, scale_value * 0.7, scale_value * 1.3)
	parent.add_child(rock)


func _add_cylinder_prop(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var prop := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 8
	prop.mesh = mesh
	prop.material_override = material
	prop.position = (start + end) * 0.5
	parent.add_child(prop)


func _add_cone_prop(parent: Node3D, position: Vector3, radius: float, material: Material) -> void:
	var prop := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = radius
	mesh.height = 0.55
	mesh.radial_segments = 8
	prop.mesh = mesh
	prop.material_override = material
	prop.position = position
	parent.add_child(prop)


func _stage_colors(stage_name: String) -> Array[Color]:
	if stage_name == "Highway":
		return [Color(0.08, 0.16, 0.28), Color(0.12, 0.24, 0.34), Color(0.08, 0.22, 0.3), Color(0.12, 0.3, 0.34), Color(0.16, 0.18, 0.2)]
	if stage_name == "Desert":
		return [Color(0.52, 0.3, 0.14), Color(0.7, 0.4, 0.16), Color(0.48, 0.25, 0.08), Color(0.55, 0.3, 0.08), Color(0.34, 0.2, 0.12)]
	if stage_name == "Snow":
		return [Color(0.38, 0.52, 0.65), Color(0.56, 0.7, 0.78), Color(0.72, 0.86, 0.94), Color(0.78, 0.9, 0.96), Color(0.32, 0.4, 0.46)]
	if stage_name == "Mars":
		return [Color(0.3, 0.08, 0.04), Color(0.5, 0.14, 0.06), Color(0.52, 0.15, 0.07), Color(0.46, 0.12, 0.04), Color(0.25, 0.08, 0.05)]
	if stage_name == "Moon":
		return [Color(0.015, 0.02, 0.08), Color(0.03, 0.05, 0.16), Color(0.12, 0.14, 0.2), Color(0.16, 0.18, 0.24), Color(0.2, 0.21, 0.25)]
	return [Color(0.58, 0.70, 0.68), Color(0.44, 0.59, 0.39), Color(0.22, 0.4, 0.16), Color(0.34, 0.53, 0.2), Color(0.38, 0.39, 0.34)]


func _update_layers(force: bool) -> void:
	var camera_z := _camera.global_position.z
	if not force and absf(camera_z - _last_camera_z) < 0.01:
		return
	_last_camera_z = camera_z
	_position_layer(_distant_layer, camera_z, DISTANT_PARALLAX)
	_position_layer(_middle_layer, camera_z, MIDDLE_PARALLAX)
	_position_layer(_near_layer, camera_z, NEAR_PARALLAX)


func _position_layer(layer: Node3D, camera_z: float, parallax: float) -> void:
	# Recenter finite procedural bands before they leave the camera frustum.
	# The large-band wrap is invisible, while the fractional offset preserves
	# the intended parallax relationship.
	var base_position := camera_z * (1.0 - parallax)
	var wrap_count := roundi(camera_z * parallax / RIDGE_LENGTH)
	layer.position.z = base_position + float(wrap_count) * RIDGE_LENGTH


func _create_ridge_layer(
	layer_name: String,
	layer_x: float,
	parallax: float,
	colors: Array[Color]
) -> Node3D:
	var layer := Node3D.new()
	layer.name = layer_name
	layer.position.x = layer_x
	add_child(layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + layer_name.hash()
	for band in range(colors.size()):
		var mesh := _create_ridge_mesh(rng, band, colors.size(), band)
		var visual := MeshInstance3D.new()
		visual.name = "ConnectedRidge_%d" % band
		visual.mesh = mesh
		visual.position.x = layer_x + float(band) * 0.32
		visual.material_override = _material(colors[band], 1.0)
		layer.add_child(visual)
	return layer


func _create_ridge_mesh(
	rng: RandomNumberGenerator,
	band: int,
	band_count: int,
	offset: int
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var baseline := -1.2 + float(band) * 0.28
	var peak_height := 4.8 - float(band) * 0.45
	for index in range(RIDGE_SAMPLES):
		var t := float(index) / float(RIDGE_SAMPLES - 1)
		var z := lerpf(-RIDGE_LENGTH * 0.5, RIDGE_LENGTH * 0.5, t)
		var wave := sin(z * 0.075 + float(offset) * 1.7) * (1.45 + band * 0.18)
		wave += sin(z * 0.16 + float(offset) * 0.8) * 0.65
		wave += sin(z * 0.31 + float(offset) * 2.4) * 0.22
		var peak := baseline + peak_height + wave
		if index % 11 == 3:
			peak += 0.35
		vertices.append(Vector3(0.0, peak, z))
		vertices.append(Vector3(0.0, baseline, z))
		normals.append(Vector3(-1.0, 0.0, 0.0))
		normals.append(Vector3(-1.0, 0.0, 0.0))
	for index in range(RIDGE_SAMPLES - 1):
		var current := index * 2
		var next := current + 2
		indices.append_array(PackedInt32Array([
			current, next, current + 1,
			current + 1, next, next + 1,
		]))
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _create_near_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 991
	for index in range(96):
		var z := lerpf(-RIDGE_LENGTH * 0.5, RIDGE_LENGTH * 0.5, float(index) / 95.0)
		var height := -0.65 + sin(z * 0.04) * 0.08
		if index % 4 == 0 or index % 7 == 0:
			_add_tree(_near_layer, rng, z, height)
		elif index % 3 == 1:
			_add_bush(_near_layer, rng, z, height)
		else:
			_add_rock(_near_layer, rng, z, height)


func _add_tree(parent: Node3D, rng: RandomNumberGenerator, z: float, height: float) -> void:
	var tree := Node3D.new()
	tree.name = "BackgroundPine"
	tree.position = Vector3(-3.2, height, z)
	tree.scale = Vector3.ONE * rng.randf_range(0.75, 1.35)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.08
	trunk_mesh.bottom_radius = 0.12
	trunk_mesh.height = 1.8
	trunk_mesh.radial_segments = 6
	trunk.mesh = trunk_mesh
	trunk.material_override = _trunk_material
	trunk.position.y = 0.9
	tree.add_child(trunk)
	for layer in range(4):
		var foliage := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.03
		mesh.bottom_radius = 0.72 - layer * 0.16
		mesh.height = 0.72
		mesh.radial_segments = 6
		foliage.mesh = mesh
		foliage.material_override = _tree_material
		foliage.position.y = 0.72 + layer * 0.4
		tree.add_child(foliage)
	parent.add_child(tree)


func _add_bush(parent: Node3D, rng: RandomNumberGenerator, z: float, height: float) -> void:
	var bush := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.radius = 0.5
	mesh.height = 0.7
	bush.mesh = mesh
	bush.material_override = _bush_material
	bush.position = Vector3(-3.0, height, z)
	bush.scale = Vector3(1.0, 0.6, 0.8)
	parent.add_child(bush)


func _add_rock(parent: Node3D, rng: RandomNumberGenerator, z: float, height: float) -> void:
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 3
	mesh.radius = 0.45
	mesh.height = 0.6
	rock.mesh = mesh
	rock.material_override = _rock_material
	rock.position = Vector3(-2.8, height, z)
	rock.scale = Vector3(1.0, 0.7, 1.2)
	parent.add_child(rock)


func _create_materials() -> void:
	_tree_material = _material(Color(0.22, 0.40, 0.16), 0.98)
	_trunk_material = _material(Color(0.30, 0.20, 0.11), 1.0)
	_bush_material = _material(Color(0.34, 0.53, 0.20), 0.98)
	_rock_material = _material(Color(0.38, 0.39, 0.34), 1.0)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
