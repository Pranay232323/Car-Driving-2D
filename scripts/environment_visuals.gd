extends Node3D
class_name EnvironmentVisuals

const RIDGE_LENGTH := 360.0
const RIDGE_SAMPLES := 73
const DISTANT_PARALLAX := 0.06
const MIDDLE_PARALLAX := 0.18
const NEAR_PARALLAX := 0.42

@export var seed_value := 73421

var _camera: Camera3D
var _vehicle: VehicleController
var _terrain: Node3D
var _distant_layer: Node3D
var _middle_layer: Node3D
var _near_layer: Node3D
var _star_layer: Node3D
var _earth_model: Node3D
var _tree_material: StandardMaterial3D
var _trunk_material: StandardMaterial3D
var _bush_material: StandardMaterial3D
var _rock_material: StandardMaterial3D
var _prop_accent_material: StandardMaterial3D
var _last_camera_z := 0.0
var _stage_theme := "Highlands"


func _ready() -> void:
	_camera = get_parent().get_node_or_null("SideCamera") as Camera3D
	_vehicle = get_parent().get_node_or_null("PlaceholderVehicle") as VehicleController
	_terrain = get_parent().get_node_or_null("ProceduralTerrain")
	_create_materials()
	_distant_layer = Node3D.new()
	_distant_layer.name = "DistantLayer"
	add_child(_distant_layer)

	_middle_layer = Node3D.new()
	_middle_layer.name = "MiddleLayer"
	add_child(_middle_layer)

	_near_layer = Node3D.new()
	_near_layer.name = "NearPropsLayer"
	add_child(_near_layer)

	_create_space_elements()
	_rebuild_ridges(_stage_theme)
	_rebuild_near_props(_stage_theme)
	_update_layers(true)


func _process(_delta: float) -> void:
	_update_layers(false)


func set_stage_theme(stage_name: String) -> void:
	_stage_theme = stage_name
	_rebuild_ridges(stage_name)
	_rebuild_near_props(stage_name)
	if _star_layer:
		_star_layer.visible = (stage_name == "Moon" or stage_name == "Mars")
	if _earth_model:
		_earth_model.visible = (stage_name == "Moon")
	_update_layers(true)


func _update_layers(force: bool) -> void:
	if _camera == null:
		return
	var camera_z := _camera.global_position.z
	if not force and absf(camera_z - _last_camera_z) < 0.01:
		return
	_last_camera_z = camera_z
	_position_layer(_distant_layer, camera_z, DISTANT_PARALLAX)
	_position_layer(_middle_layer, camera_z, MIDDLE_PARALLAX)
	_position_layer(_near_layer, camera_z, NEAR_PARALLAX)
	if _star_layer and _star_layer.visible:
		_star_layer.position.z = camera_z * 0.98


func _position_layer(layer: Node3D, camera_z: float, parallax: float) -> void:
	var base_position := camera_z * (1.0 - parallax)
	var wrap_count := roundi(camera_z * parallax / RIDGE_LENGTH)
	layer.position.z = base_position + float(wrap_count) * RIDGE_LENGTH


func _rebuild_ridges(stage_name: String) -> void:
	for child in _distant_layer.get_children():
		child.queue_free()
	for child in _middle_layer.get_children():
		child.queue_free()

	var colors := _stage_colors(stage_name)

	# Distant Mountain Ridges
	var distant_mesh := _create_ridge_mesh(stage_name, 0, 8.5, -1.8, seed_value + 101)
	var distant_vis := MeshInstance3D.new()
	distant_vis.mesh = distant_mesh
	distant_vis.position.x = -14.0
	distant_vis.material_override = _material(colors[0], 0.95)
	_distant_layer.add_child(distant_vis)

	# Distant Secondary Ridge
	var distant_sub_mesh := _create_ridge_mesh(stage_name, 1, 6.8, -1.2, seed_value + 203)
	var distant_sub_vis := MeshInstance3D.new()
	distant_sub_vis.mesh = distant_sub_mesh
	distant_sub_vis.position.x = -11.5
	distant_sub_vis.material_override = _material(colors[1], 0.95)
	_distant_layer.add_child(distant_sub_vis)

	# Middle Hills / Formations
	var middle_mesh := _create_ridge_mesh(stage_name, 2, 5.0, -0.6, seed_value + 405)
	var middle_vis := MeshInstance3D.new()
	middle_vis.mesh = middle_mesh
	middle_vis.position.x = -7.5
	middle_vis.material_override = _material(colors[2], 0.92)
	_middle_layer.add_child(middle_vis)


func _create_ridge_mesh(stage_name: String, band: int, peak_height: float, baseline: float, rng_seed: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	for index in range(RIDGE_SAMPLES):
		var t := float(index) / float(RIDGE_SAMPLES - 1)
		var z := lerpf(-RIDGE_LENGTH * 0.5, RIDGE_LENGTH * 0.5, t)
		var h := baseline + peak_height

		match stage_name:
			"Desert":
				# Flat-topped mesas and sandstone buttes
				var raw_wave := sin(z * 0.055) * 2.2 + sin(z * 0.12) * 1.1
				var mesa := clampf(raw_wave, -0.6, 1.4) # Flat mesa tops!
				if raw_wave > 1.2:
					mesa += sin(z * 0.35) * 0.15 # weathered rim
				h += mesa

			"Snow":
				# Sharp, jagged alpine horns and glacial crags
				var sharp1 := absf(sin(z * 0.065)) * 3.2
				var sharp2 := absf(sin(z * 0.14 + 1.2)) * 1.4
				var needles := sin(z * 0.28) * 0.6
				h += sharp1 + sharp2 + needles - 1.5

			"Highway":
				# Sweeping mountain pass silhouettes with stepped highway cuts
				var sweep := sin(z * 0.045) * 2.8 + sin(z * 0.09) * 1.2
				var cut := roundf(sweep * 1.8) / 1.8 # terraced road cuttings
				h += lerpf(sweep, cut, 0.4)

			"Mars":
				# Volcanic calderas and impact rims
				var rim := sin(z * 0.05) * 2.4 - absf(sin(z * 0.11)) * 1.8
				var cone := sin(z * 0.08 + 2.1) * 1.6
				h += rim + cone

			"Moon":
				# Broad crater basins and stark razor-sharp impact peaks
				var basin := sin(z * 0.04) * 2.5
				var crater_rim := pow(absf(sin(z * 0.075)), 2.2) * 2.8
				h += basin + crater_rim - 1.2

			_: # Highlands
				# Rolling lush mountain ridges
				var wave1 := sin(z * 0.052) * 2.4
				var wave2 := sin(z * 0.11 + 0.8) * 1.1
				var wave3 := sin(z * 0.22 + 2.0) * 0.45
				h += wave1 + wave2 + wave3

		vertices.append(Vector3(0.0, h, z))
		vertices.append(Vector3(0.0, baseline - 4.0, z))
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


func _rebuild_near_props(stage_name: String) -> void:
	for child in _near_layer.get_children():
		child.queue_free()

	match stage_name:
		"Desert":
			_create_desert_props()
		"Highway":
			_create_highway_props()
		"Snow":
			_create_snow_props()
		"Mars":
			_create_mars_props()
		"Moon":
			_create_moon_props()
		_:
			_create_highlands_props()


func _create_highlands_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1204
	for index in range(54):
		var z := lerpf(-RIDGE_LENGTH * 0.48, RIDGE_LENGTH * 0.48, float(index) / 53.0)
		var h := -0.55 + sin(z * 0.04) * 0.25
		if index % 3 == 0:
			_add_pine_tree(_near_layer, rng, Vector3(-3.2, h, z), rng.randf_range(0.85, 1.35))
		elif index % 3 == 1:
			_add_bush(_near_layer, rng, Vector3(-2.8, h, z), rng.randf_range(0.65, 1.1))
		else:
			_add_granite_rock(_near_layer, rng, Vector3(-2.7, h, z), rng.randf_range(0.5, 0.95))


func _create_desert_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 2204
	var cactus_mat := _material(Color(0.24, 0.48, 0.18), 0.88)
	var scrub_mat := _material(Color(0.46, 0.42, 0.22), 0.95)
	for index in range(48):
		var z := lerpf(-RIDGE_LENGTH * 0.48, RIDGE_LENGTH * 0.48, float(index) / 47.0)
		var h := -0.65 + sin(z * 0.035) * 0.2
		if index % 2 == 0:
			_add_saguaro_cactus(_near_layer, Vector3(-3.0, h, z), rng.randf_range(0.8, 1.4), cactus_mat)
		elif index % 3 == 1:
			_add_sandstone_rock(_near_layer, rng, Vector3(-2.8, h, z), rng.randf_range(0.6, 1.2))
		else:
			_add_desert_scrub(_near_layer, Vector3(-2.6, h, z), rng.randf_range(0.5, 0.9), scrub_mat)


func _create_highway_props() -> void:
	var lamp_mat := _material(Color(0.22, 0.24, 0.28), 0.5)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1.0, 0.9, 0.6)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.85, 0.5)
	glow_mat.emission_energy_multiplier = 2.5

	var sign_mat := _material(Color(0.08, 0.45, 0.25), 0.6)
	var post_mat := _material(Color(0.35, 0.38, 0.42), 0.7)

	for index in range(36):
		var z := -float(index) * 10.0 + 30.0
		# Streetlight
		_add_streetlight(_near_layer, Vector3(-3.4, -0.2, z), lamp_mat, glow_mat)
		# Roadside Barrier post
		_add_barrier_post(_near_layer, Vector3(-2.6, -0.45, z), post_mat)
		if index % 6 == 2:
			_add_highway_sign(_near_layer, Vector3(-3.2, 0.0, z - 4.0), sign_mat, post_mat)


func _create_snow_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 3304
	for index in range(46):
		var z := lerpf(-RIDGE_LENGTH * 0.48, RIDGE_LENGTH * 0.48, float(index) / 45.0)
		var h := -0.6 + sin(z * 0.04) * 0.2
		if index % 2 == 0:
			_add_snow_pine_tree(_near_layer, rng, Vector3(-3.2, h, z), rng.randf_range(0.8, 1.3))
		elif index % 3 == 1:
			_add_ice_pillar(_near_layer, Vector3(-2.8, h, z), rng.randf_range(0.7, 1.2))
		else:
			_add_snow_boulder(_near_layer, Vector3(-2.6, h, z), rng.randf_range(0.5, 1.0))


func _create_mars_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 4404
	var mars_mat := _material(Color(0.68, 0.22, 0.12), 0.94)
	var basalt_mat := _material(Color(0.25, 0.12, 0.10), 0.92)
	for index in range(45):
		var z := lerpf(-RIDGE_LENGTH * 0.48, RIDGE_LENGTH * 0.48, float(index) / 44.0)
		var h := -0.65 + sin(z * 0.045) * 0.25
		if index % 3 == 0:
			_add_mars_spire(_near_layer, Vector3(-3.1, h, z), rng.randf_range(0.8, 1.5), basalt_mat)
		elif index % 3 == 1:
			_add_mars_boulder(_near_layer, Vector3(-2.8, h, z), rng.randf_range(0.6, 1.2), mars_mat)
		else:
			_add_crater_mound(_near_layer, Vector3(-3.0, h, z), rng.randf_range(0.7, 1.3), mars_mat)


func _create_moon_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 5504
	var moon_mat := _material(Color(0.42, 0.44, 0.48), 0.96)
	var lander_mat := _material(Color(0.85, 0.75, 0.45), 0.4)
	for index in range(40):
		var z := lerpf(-RIDGE_LENGTH * 0.48, RIDGE_LENGTH * 0.48, float(index) / 39.0)
		var h := -0.65 + sin(z * 0.04) * 0.22
		if index % 3 == 0:
			_add_crater_ring(_near_layer, Vector3(-3.0, h, z), rng.randf_range(0.8, 1.6), moon_mat)
		elif index % 3 == 1:
			_add_lunar_rock_cluster(_near_layer, Vector3(-2.8, h, z), rng.randf_range(0.5, 1.1), moon_mat)
		elif index == 14:
			_add_apollo_equipment(_near_layer, Vector3(-3.2, h + 0.2, z), lander_mat)


# --- Procedural Prop Builders ---

func _add_pine_tree(parent: Node3D, _rng: RandomNumberGenerator, pos: Vector3, sc: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * sc
	parent.add_child(root)

	var trunk := MeshInstance3D.new()
	var tmesh := CylinderMesh.new()
	tmesh.top_radius = 0.08
	tmesh.bottom_radius = 0.13
	tmesh.height = 1.7
	trunk.mesh = tmesh
	trunk.material_override = _trunk_material
	trunk.position.y = 0.85
	root.add_child(trunk)

	for layer in range(3):
		var foliage := MeshInstance3D.new()
		var fmesh := CylinderMesh.new()
		fmesh.top_radius = 0.02
		fmesh.bottom_radius = 0.68 - layer * 0.15
		fmesh.height = 0.65
		foliage.mesh = fmesh
		foliage.material_override = _tree_material
		foliage.position.y = 0.7 + layer * 0.42
		root.add_child(foliage)


func _add_snow_pine_tree(parent: Node3D, _rng: RandomNumberGenerator, pos: Vector3, sc: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * sc
	parent.add_child(root)

	var trunk := MeshInstance3D.new()
	var tmesh := CylinderMesh.new()
	tmesh.top_radius = 0.07
	tmesh.bottom_radius = 0.12
	tmesh.height = 1.6
	trunk.mesh = tmesh
	trunk.material_override = _trunk_material
	trunk.position.y = 0.8
	root.add_child(trunk)

	var snow_pine_mat := _material(Color(0.18, 0.32, 0.35), 0.95)
	var frost_cap_mat := _material(Color(0.92, 0.96, 1.0), 0.85)

	for layer in range(3):
		var foliage := MeshInstance3D.new()
		var fmesh := CylinderMesh.new()
		fmesh.top_radius = 0.02
		fmesh.bottom_radius = 0.65 - layer * 0.14
		fmesh.height = 0.62
		foliage.mesh = fmesh
		foliage.material_override = snow_pine_mat
		foliage.position.y = 0.65 + layer * 0.4
		root.add_child(foliage)

		var cap := MeshInstance3D.new()
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = 0.02
		cmesh.bottom_radius = fmesh.bottom_radius * 0.85
		cmesh.height = 0.22
		cap.mesh = cmesh
		cap.material_override = frost_cap_mat
		cap.position.y = foliage.position.y + 0.2
		root.add_child(cap)


func _add_saguaro_cactus(parent: Node3D, pos: Vector3, sc: float, mat: Material) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * sc
	parent.add_child(root)

	# Main stem
	var stem := MeshInstance3D.new()
	var smesh := CylinderMesh.new()
	smesh.top_radius = 0.12
	smesh.bottom_radius = 0.14
	smesh.height = 1.9
	stem.mesh = smesh
	stem.material_override = mat
	stem.position.y = 0.95
	root.add_child(stem)

	# Left arm
	var arm_l_h := MeshInstance3D.new()
	var hmesh := CylinderMesh.new()
	hmesh.top_radius = 0.07
	hmesh.bottom_radius = 0.07
	hmesh.height = 0.38
	arm_l_h.mesh = hmesh
	arm_l_h.material_override = mat
	arm_l_h.rotation.x = PI * 0.5
	arm_l_h.position = Vector3(0.0, 1.0, 0.2)
	root.add_child(arm_l_h)

	var arm_l_v := MeshInstance3D.new()
	var vmesh := CylinderMesh.new()
	vmesh.top_radius = 0.07
	vmesh.bottom_radius = 0.07
	vmesh.height = 0.55
	arm_l_v.mesh = vmesh
	arm_l_v.material_override = mat
	arm_l_v.position = Vector3(0.0, 1.25, 0.38)
	root.add_child(arm_l_v)

	# Right arm
	var arm_r_h := MeshInstance3D.new()
	arm_r_h.mesh = hmesh
	arm_r_h.material_override = mat
	arm_r_h.rotation.x = PI * 0.5
	arm_r_h.position = Vector3(0.0, 0.75, -0.2)
	root.add_child(arm_r_h)

	var arm_r_v := MeshInstance3D.new()
	arm_r_v.mesh = vmesh
	arm_r_v.material_override = mat
	arm_r_v.position = Vector3(0.0, 1.0, -0.38)
	root.add_child(arm_r_v)


func _add_bush(parent: Node3D, _rng: RandomNumberGenerator, pos: Vector3, sc: float) -> void:
	var bush := MeshInstance3D.new()
	var bmesh := SphereMesh.new()
	bmesh.radius = 0.45 * sc
	bmesh.height = 0.65 * sc
	bush.mesh = bmesh
	bush.material_override = _bush_material
	bush.position = pos + Vector3(0.0, 0.25 * sc, 0.0)
	parent.add_child(bush)


func _add_granite_rock(parent: Node3D, _rng: RandomNumberGenerator, pos: Vector3, sc: float) -> void:
	var rock := MeshInstance3D.new()
	var rmesh := BoxMesh.new()
	rmesh.size = Vector3(0.8 * sc, 0.55 * sc, 1.1 * sc)
	rock.mesh = rmesh
	rock.material_override = _rock_material
	rock.position = pos + Vector3(0.0, 0.25 * sc, 0.0)
	rock.rotation.y = 0.4
	parent.add_child(rock)


func _add_sandstone_rock(parent: Node3D, _rng: RandomNumberGenerator, pos: Vector3, sc: float) -> void:
	var rock := MeshInstance3D.new()
	var rmesh := BoxMesh.new()
	rmesh.size = Vector3(1.2 * sc, 0.7 * sc, 1.5 * sc)
	rock.mesh = rmesh
	rock.material_override = _material(Color(0.72, 0.46, 0.24), 0.94)
	rock.position = pos + Vector3(0.0, 0.3 * sc, 0.0)
	rock.rotation.y = 0.3
	parent.add_child(rock)


func _add_desert_scrub(parent: Node3D, pos: Vector3, sc: float, mat: Material) -> void:
	var scrub := MeshInstance3D.new()
	var smesh := SphereMesh.new()
	smesh.radius = 0.35 * sc
	smesh.height = 0.45 * sc
	scrub.mesh = smesh
	scrub.material_override = mat
	scrub.position = pos + Vector3(0.0, 0.2 * sc, 0.0)
	parent.add_child(scrub)


func _add_streetlight(parent: Node3D, pos: Vector3, pole_mat: Material, bulb_mat: Material) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)

	var pole := MeshInstance3D.new()
	var pmesh := CylinderMesh.new()
	pmesh.top_radius = 0.04
	pmesh.bottom_radius = 0.06
	pmesh.height = 3.6
	pole.mesh = pmesh
	pole.material_override = pole_mat
	pole.position.y = 1.8
	root.add_child(pole)

	var arm := MeshInstance3D.new()
	var amesh := BoxMesh.new()
	amesh.size = Vector3(0.06, 0.06, 0.8)
	arm.mesh = amesh
	arm.material_override = pole_mat
	arm.position = Vector3(0.0, 3.55, 0.35)
	root.add_child(arm)

	var bulb := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(0.12, 0.05, 0.22)
	bulb.mesh = bmesh
	bulb.material_override = bulb_mat
	bulb.position = Vector3(0.0, 3.48, 0.65)
	root.add_child(bulb)


func _add_barrier_post(parent: Node3D, pos: Vector3, mat: Material) -> void:
	var post := MeshInstance3D.new()
	var pmesh := BoxMesh.new()
	pmesh.size = Vector3(0.08, 0.65, 0.1)
	post.mesh = pmesh
	post.material_override = mat
	post.position = pos + Vector3(0.0, 0.32, 0.0)
	parent.add_child(post)


func _add_highway_sign(parent: Node3D, pos: Vector3, sign_mat: Material, post_mat: Material) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)

	var post := MeshInstance3D.new()
	var pmesh := CylinderMesh.new()
	pmesh.top_radius = 0.05
	pmesh.bottom_radius = 0.05
	pmesh.height = 2.4
	post.mesh = pmesh
	post.material_override = post_mat
	post.position.y = 1.2
	root.add_child(post)

	var sign := MeshInstance3D.new()
	var smesh := BoxMesh.new()
	smesh.size = Vector3(0.08, 0.8, 1.4)
	sign.mesh = smesh
	sign.material_override = sign_mat
	sign.position = Vector3(0.0, 2.2, 0.0)
	root.add_child(sign)


func _add_ice_pillar(parent: Node3D, pos: Vector3, sc: float) -> void:
	var pillar := MeshInstance3D.new()
	var pmesh := CylinderMesh.new()
	pmesh.top_radius = 0.05 * sc
	pmesh.bottom_radius = 0.25 * sc
	pmesh.height = 1.4 * sc
	pillar.mesh = pmesh
	var ice_mat := _material(Color(0.72, 0.88, 0.98), 0.15)
	ice_mat.metallic = 0.2
	pillar.material_override = ice_mat
	pillar.position = pos + Vector3(0.0, 0.7 * sc, 0.0)
	parent.add_child(pillar)


func _add_snow_boulder(parent: Node3D, pos: Vector3, sc: float) -> void:
	var rock := MeshInstance3D.new()
	var rmesh := SphereMesh.new()
	rmesh.radius = 0.5 * sc
	rmesh.height = 0.65 * sc
	rock.mesh = rmesh
	rock.material_override = _material(Color(0.85, 0.92, 0.98), 0.9)
	rock.position = pos + Vector3(0.0, 0.3 * sc, 0.0)
	parent.add_child(rock)


func _add_mars_spire(parent: Node3D, pos: Vector3, sc: float, mat: Material) -> void:
	var spire := MeshInstance3D.new()
	var smesh := CylinderMesh.new()
	smesh.top_radius = 0.08 * sc
	smesh.bottom_radius = 0.32 * sc
	smesh.height = 2.2 * sc
	spire.mesh = smesh
	spire.material_override = mat
	spire.position = pos + Vector3(0.0, 1.1 * sc, 0.0)
	spire.rotation.z = 0.08
	parent.add_child(spire)


func _add_mars_boulder(parent: Node3D, pos: Vector3, sc: float, mat: Material) -> void:
	var rock := MeshInstance3D.new()
	var rmesh := BoxMesh.new()
	rmesh.size = Vector3(1.1 * sc, 0.8 * sc, 1.4 * sc)
	rock.mesh = rmesh
	rock.material_override = mat
	rock.position = pos + Vector3(0.0, 0.4 * sc, 0.0)
	parent.add_child(rock)


func _add_crater_mound(parent: Node3D, pos: Vector3, sc: float, mat: Material) -> void:
	var mound := MeshInstance3D.new()
	var mmesh := SphereMesh.new()
	mmesh.radius = 0.9 * sc
	mmesh.height = 0.5 * sc
	mound.mesh = mmesh
	mound.material_override = mat
	mound.position = pos + Vector3(0.0, 0.15 * sc, 0.0)
	parent.add_child(mound)


func _add_crater_ring(parent: Node3D, pos: Vector3, sc: float, mat: Material) -> void:
	var crater := MeshInstance3D.new()
	var cmesh := TorusMesh.new()
	cmesh.inner_radius = 0.35 * sc
	cmesh.outer_radius = 0.55 * sc
	crater.mesh = cmesh
	crater.material_override = mat
	crater.position = pos + Vector3(0.0, 0.1, 0.0)
	crater.rotation.x = PI * 0.5
	crater.scale.y = 0.3
	parent.add_child(crater)


func _add_lunar_rock_cluster(parent: Node3D, pos: Vector3, sc: float, mat: Material) -> void:
	var rock := MeshInstance3D.new()
	var rmesh := BoxMesh.new()
	rmesh.size = Vector3(0.7 * sc, 0.45 * sc, 0.9 * sc)
	rock.mesh = rmesh
	rock.material_override = mat
	rock.position = pos + Vector3(0.0, 0.22 * sc, 0.0)
	parent.add_child(rock)


func _add_apollo_equipment(parent: Node3D, pos: Vector3, mat: Material) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)

	var base := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 0.45
	bmesh.bottom_radius = 0.55
	bmesh.height = 0.5
	base.mesh = bmesh
	base.material_override = mat
	base.position.y = 0.25
	root.add_child(base)

	var mast := MeshInstance3D.new()
	var mmesh := CylinderMesh.new()
	mmesh.top_radius = 0.03
	mmesh.bottom_radius = 0.03
	mmesh.height = 1.1
	mast.mesh = mmesh
	mast.material_override = _material(Color(0.8, 0.8, 0.8), 0.3)
	mast.position.y = 0.8
	root.add_child(mast)

	var dish := MeshInstance3D.new()
	var dmesh := CylinderMesh.new()
	dmesh.top_radius = 0.3
	dmesh.bottom_radius = 0.02
	dmesh.height = 0.15
	dish.mesh = dmesh
	dish.material_override = _material(Color(0.9, 0.9, 0.9), 0.4)
	dish.position = Vector3(0.0, 1.35, 0.0)
	dish.rotation.x = 0.6
	root.add_child(dish)


# --- Space Elements (Moon Stars & 3D Earth) ---

func _create_space_elements() -> void:
	_star_layer = Node3D.new()
	_star_layer.name = "SpaceBackdrop"
	add_child(_star_layer)

	var star_mat := StandardMaterial3D.new()
	star_mat.albedo_color = Color(1.0, 1.0, 1.0)
	star_mat.emission_enabled = true
	star_mat.emission = Color(0.9, 0.95, 1.0)
	star_mat.emission_energy_multiplier = 2.0

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 8812

	# 110 Twinkling stars distributed across the backdrop
	for index in range(110):
		var star := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		var r := rng.randf_range(0.035, 0.08)
		mesh.radius = r
		mesh.height = r * 2.0
		mesh.radial_segments = 5
		mesh.rings = 3
		star.mesh = mesh
		star.material_override = star_mat
		star.position = Vector3(
			rng.randf_range(-22.0, -18.0),
			rng.randf_range(3.0, 22.0),
			rng.randf_range(-180.0, 180.0)
		)
		_star_layer.add_child(star)

	# 3D Earth in the Lunar Sky!
	_earth_model = Node3D.new()
	_earth_model.name = "EarthInLunarSky"
	_earth_model.position = Vector3(-20.0, 14.5, -35.0)
	_star_layer.add_child(_earth_model)

	var earth_mesh := MeshInstance3D.new()
	var emesh := SphereMesh.new()
	emesh.radius = 3.6
	emesh.height = 7.2
	emesh.radial_segments = 24
	emesh.rings = 16
	earth_mesh.mesh = emesh

	# Blue ocean with cloud white & continent green/brown
	var earth_mat := StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.12, 0.38, 0.85) # Vivid deep blue ocean
	earth_mat.emission_enabled = true
	earth_mat.emission = Color(0.06, 0.22, 0.55)
	earth_mat.emission_energy_multiplier = 0.5
	earth_mesh.material_override = earth_mat
	_earth_model.add_child(earth_mesh)

	# Cloud swirls layer
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(0.95, 0.98, 1.0, 0.75)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.emission_enabled = true
	cloud_mat.emission = Color(0.8, 0.9, 1.0)
	cloud_mat.emission_energy_multiplier = 0.3

	var clouds := MeshInstance3D.new()
	var cmesh := SphereMesh.new()
	cmesh.radius = 3.68
	cmesh.height = 7.36
	cmesh.radial_segments = 20
	cmesh.rings = 14
	clouds.mesh = cmesh
	clouds.material_override = cloud_mat
	_earth_model.add_child(clouds)

	_star_layer.visible = false
	_earth_model.visible = false


func _stage_colors(stage_name: String) -> Array[Color]:
	match stage_name:
		"Highway":
			return [
				Color(0.12, 0.18, 0.28), # Distant blue-grey pass
				Color(0.18, 0.26, 0.38), # Mid viaduct ridge
				Color(0.22, 0.30, 0.42), # Near embankment
			]
		"Desert":
			return [
				Color(0.72, 0.38, 0.18), # Distant warm sandstone mesas
				Color(0.82, 0.48, 0.22), # Mid desert buttes
				Color(0.88, 0.56, 0.26), # Near dunes
			]
		"Snow":
			return [
				Color(0.38, 0.52, 0.68), # Distant glacial blue peaks
				Color(0.55, 0.70, 0.84), # Mid icy horns
				Color(0.75, 0.88, 0.96), # Near snowfields
			]
		"Mars":
			return [
				Color(0.38, 0.10, 0.06), # Distant dark rust calderas
				Color(0.58, 0.16, 0.08), # Mid volcanic cones
				Color(0.76, 0.24, 0.12), # Near red crater rims
			]
		"Moon":
			return [
				Color(0.12, 0.14, 0.18), # Deep dark lunar horizon
				Color(0.24, 0.26, 0.32), # Mid impact massifs
				Color(0.38, 0.40, 0.46), # Near crater rim ridges
			]
		_: # Highlands
			return [
				Color(0.36, 0.54, 0.68), # Distant alpine blue ranges
				Color(0.22, 0.48, 0.25), # Mid green pine hills
				Color(0.28, 0.56, 0.22), # Near lush slopes
			]


func _create_materials() -> void:
	_tree_material = _material(Color(0.18, 0.46, 0.18), 0.96)
	_trunk_material = _material(Color(0.32, 0.20, 0.10), 1.0)
	_bush_material = _material(Color(0.38, 0.64, 0.16), 0.98)
	_rock_material = _material(Color(0.40, 0.42, 0.38), 0.98)
	_prop_accent_material = _material(Color(0.95, 0.72, 0.16), 0.5)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
