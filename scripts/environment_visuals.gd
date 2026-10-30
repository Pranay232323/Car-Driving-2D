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
var _tree_material: StandardMaterial3D
var _trunk_material: StandardMaterial3D
var _bush_material: StandardMaterial3D
var _rock_material: StandardMaterial3D
var _last_camera_z := 0.0


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
	_update_layers(true)


func _process(_delta: float) -> void:
	_update_layers(false)


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
