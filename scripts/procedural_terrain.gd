extends Node3D
class_name ProceduralTerrain

const CHUNK_LENGTH := 32.0
const TERRAIN_WIDTH := 8.0
const SAMPLE_COUNT := 17
const ACTIVE_AHEAD := 8
const ACTIVE_BEHIND := 2
const ROCK_COUNT_PER_CHUNK := 3

@export var seed_value := 73421
@export var chunk_length := CHUNK_LENGTH
@export var active_ahead := ACTIVE_AHEAD
@export var active_behind := ACTIVE_BEHIND
@export var terrain_width := TERRAIN_WIDTH

var _vehicle: VehicleController
var _chunks: Dictionary = {}
var _features: Array[Dictionary] = []
var _terrain_materials: Array[StandardMaterial3D] = []
var _rock_material: StandardMaterial3D
var _rock_mesh: SphereMesh
var _last_center_chunk := 999999


func _ready() -> void:
	_vehicle = get_parent().get_node("PlaceholderVehicle") as VehicleController
	_create_materials()
	_create_height_features()
	_update_chunks(true)


func _physics_process(_delta: float) -> void:
	_update_chunks(false)


func get_active_chunk_count() -> int:
	return _chunks.size()


func get_height(z: float) -> float:
	if z > -12.0:
		return 0.0
	var height := 0.22 * sin(z * 0.052 + 0.8) + 0.11 * sin(z * 0.127 - 0.4)
	for feature: Dictionary in _features:
		var distance := absf(z - float(feature["center"]))
		var width := float(feature["width"])
		if distance < width:
			var fade := 1.0 - distance / width
			fade = fade * fade * (3.0 - 2.0 * fade)
			height += float(feature["amplitude"]) * fade
	return height


func _update_chunks(force: bool) -> void:
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
	for index in range(-4, 48):
		var center := -float(index) * 24.0 - rng.randf_range(-6.0, 6.0)
		var amplitude := rng.randf_range(-0.65, 0.9)
		var width := rng.randf_range(5.0, 10.0)
		if index % 9 == 0:
			amplitude = rng.randf_range(0.7, 1.25)
			width = rng.randf_range(8.0, 13.0)
		_features.append({
			"center": center,
			"amplitude": amplitude,
			"width": width,
		})


func _create_chunk(chunk_index: int) -> Node3D:
	var z_end := -float(chunk_index) * chunk_length
	var z_start := z_end - chunk_length
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var top_near_x := terrain_width * 0.5
	var top_far_x := -terrain_width * 0.5
	var bottom_y := -6.0

	for sample_index in range(SAMPLE_COUNT):
		var z := lerpf(z_start, z_end, float(sample_index) / float(SAMPLE_COUNT - 1))
		var height := get_height(z)
		vertices.append(Vector3(top_near_x, height, z))
		vertices.append(Vector3(top_far_x, height, z))
		vertices.append(Vector3(top_near_x, bottom_y, z))
		vertices.append(Vector3(top_far_x, bottom_y, z))

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
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

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
	visual.material_override = _terrain_materials[posmod(chunk_index, _terrain_materials.size())]
	body.add_child(visual)

	_add_decorations(body, chunk_index, z_start, z_end)
	return body


func _add_decorations(parent: Node3D, chunk_index: int, z_start: float, z_end: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + chunk_index * 7919
	for index in range(ROCK_COUNT_PER_CHUNK):
		var z := rng.randf_range(z_start + 2.0, z_end - 2.0)
		var rock := MeshInstance3D.new()
		rock.name = "DecorationRock_%d" % index
		rock.mesh = _rock_mesh
		rock.material_override = _rock_material
		var scale := rng.randf_range(0.16, 0.34)
		rock.scale = Vector3(scale, scale * rng.randf_range(0.65, 1.25), scale)
		rock.position = Vector3(
			rng.randf_range(-terrain_width * 0.42, terrain_width * 0.42),
			get_height(z) + scale * 0.45,
			z
		)
		parent.add_child(rock)


func _create_materials() -> void:
	for color: Color in [
		Color(0.29, 0.23, 0.15),
		Color(0.34, 0.27, 0.17),
		Color(0.25, 0.29, 0.18),
	]:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.96
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_terrain_materials.append(material)

	_rock_material = StandardMaterial3D.new()
	_rock_material.albedo_color = Color(0.25, 0.27, 0.24)
	_rock_material.roughness = 1.0
	_rock_mesh = SphereMesh.new()
	_rock_mesh.radial_segments = 8
	_rock_mesh.rings = 4
	_rock_mesh.radius = 1.0
	_rock_mesh.height = 1.4
