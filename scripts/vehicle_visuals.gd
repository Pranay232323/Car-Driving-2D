extends Node3D
class_name VehicleVisuals

const NEAR_X := 0.94
const FAR_X := -0.94

var _orange: StandardMaterial3D
var _dark: StandardMaterial3D
var _rubber: StandardMaterial3D
var _metal: StandardMaterial3D
var _glass: StandardMaterial3D
var _light: StandardMaterial3D
var _spring: StandardMaterial3D
var _brake: StandardMaterial3D
var _tread: StandardMaterial3D
var _skin: StandardMaterial3D
var _suit: StandardMaterial3D
var _harness: StandardMaterial3D
var _visual_root: Node3D
var _variant_root: Node3D
var _variant_name := "Buggy"
var _shock_roots: Array[Node3D] = []
var _wheel_names := ["RearWheelNear", "RearWheelFar", "FrontWheelNear", "FrontWheelFar"]
var _visual_time := 0.0
var _body_bounce := 0.0


func _ready() -> void:
	_create_materials()
	_hide_placeholder_visuals()
	_visual_root = Node3D.new()
	_visual_root.name = "BuggyVisualModel"
	add_child(_visual_root)
	_variant_root = Node3D.new()
	_variant_root.name = "VehicleVariantModel"
	_visual_root.add_child(_variant_root)
	_build_body()
	_build_cage()
	_build_lights_and_details()
	_build_wheels()
	_build_suspension()


func set_vehicle_variant(variant_name: String, accent_color: Color) -> void:
	if not _orange:
		return
	_variant_name = variant_name
	_orange.albedo_color = accent_color
	_light.emission = accent_color
	_spring.albedo_color = accent_color.lightened(0.18)
	for child in _variant_root.get_children():
		child.free()
	for child in _visual_root.get_children():
		child.visible = variant_name == "Buggy" or child == _variant_root or child.name.begins_with("VisibleShock")
	_build_variant(variant_name, accent_color)
	_set_wheel_style(variant_name)


func _build_variant(variant_name: String, accent_color: Color) -> void:
	if variant_name == "Trail Bike":
		_build_dirt_bike(accent_color)
	elif variant_name == "Quad Runner":
		_build_quad(accent_color)
	elif variant_name == "Monster Truck":
		_build_monster_truck(accent_color)


func _set_wheel_style(variant_name: String) -> void:
	var wheel_scale := 1.0
	if variant_name == "Trail Bike":
		wheel_scale = 0.82
	elif variant_name == "Monster Truck":
		wheel_scale = 1.4
	for wheel_name in _wheel_names:
		var wheel := get_parent().get_node(wheel_name) as Node3D
		wheel.scale = Vector3.ONE * wheel_scale
		wheel.visible = variant_name != "Trail Bike" or wheel_name.ends_with("Near")


func _build_dirt_bike(accent: Color) -> void:
	_box_variant("BikeTank", Vector3(0.42, 0.34, 0.78), Vector3(0.0, 0.64, -0.15), _orange)
	_box_variant("BikeSeat", Vector3(0.38, 0.12, 0.95), Vector3(0.0, 0.78, 0.56), _dark)
	_cylinder_variant("BikeFrame", Vector3(0.0, 0.22, -0.35), Vector3(0.0, 0.7, 0.25), 0.045, _orange)
	_cylinder_variant("BikeFrameRear", Vector3(0.0, 0.22, 0.9), Vector3(0.0, 0.7, 0.25), 0.045, _orange)
	_cylinder_variant("BikeFork", Vector3(0.0, 0.65, -0.58), Vector3(0.0, -0.18, -1.02), 0.04, _metal)
	_cylinder_variant("BikeHandlebar", Vector3(-0.25, 0.94, -0.62), Vector3(0.25, 0.94, -0.62), 0.035, _metal)
	_box_variant("BikeFrontFender", Vector3(0.3, 0.06, 0.58), Vector3(0.0, 0.18, -1.02), _orange)
	_box_variant("BikeRearFender", Vector3(0.35, 0.06, 0.62), Vector3(0.0, 0.73, 0.92), _orange)
	_sphere_variant("BikeHelmet", Vector3(0.0, 1.18, 0.25), 0.17, _orange)
	_cylinder_variant("BikeExhaust", Vector3(0.2, 0.48, 0.6), Vector3(0.2, 0.48, 1.12), 0.045, _metal)
	_box_variant("BikeEngine", Vector3(0.32, 0.35, 0.42), Vector3(0.0, 0.38, 0.18), _metal)
	_cylinder_variant("BikeChain", Vector3(0.18, 0.22, 0.35), Vector3(0.18, 0.22, 0.92), 0.025, _dark)
	_cylinder_variant("BikeFootPeg", Vector3(-0.2, 0.38, 0.28), Vector3(0.2, 0.38, 0.28), 0.025, _metal)
	_build_rider(Vector3(0.0, 0.0, 0.0), _orange, 0.92)


func _build_quad(accent: Color) -> void:
	_box_variant("QuadBody", Vector3(1.05, 0.35, 1.65), Vector3(0.0, 0.3, 0.1), _orange)
	_box_variant("QuadSeat", Vector3(0.62, 0.2, 0.72), Vector3(0.0, 0.68, 0.34), _dark)
	_box_variant("QuadNose", Vector3(0.92, 0.2, 0.58), Vector3(0.0, 0.58, -0.76), _orange)
	_cylinder_variant("QuadHandlebar", Vector3(-0.38, 0.98, -0.75), Vector3(0.38, 0.98, -0.75), 0.05, _metal)
	_box_variant("QuadFrontRack", Vector3(1.0, 0.08, 0.35), Vector3(0.0, 0.82, -1.02), _dark)
	_box_variant("QuadEngine", Vector3(0.62, 0.35, 0.55), Vector3(0.0, 0.42, 0.32), _metal)
	_cylinder_variant("QuadRearAxle", Vector3(-0.9, 0.18, 0.75), Vector3(0.9, 0.18, 0.75), 0.045, _metal)
	for x in [-0.74, 0.74]:
		_cylinder_variant("QuadFender", Vector3(x, 0.56, -0.78), Vector3(x, 0.56, -1.18), 0.055, _orange)
		_cylinder_variant("QuadRearFender", Vector3(x, 0.56, 0.62), Vector3(x, 0.56, 1.1), 0.055, _orange)
	_sphere_variant("QuadHelmet", Vector3(0.0, 1.2, 0.26), 0.19, _orange)
	_build_rider(Vector3(0.0, 0.0, 0.18), _orange, 0.9)


func _build_monster_truck(accent: Color) -> void:
	_box_variant("MonsterChassis", Vector3(1.55, 0.4, 2.7), Vector3(0.0, 0.52, 0.1), _dark)
	_box_variant("MonsterCab", Vector3(1.2, 1.0, 1.35), Vector3(0.0, 1.18, -0.18), _orange)
	_box_variant("MonsterWindow", Vector3(1.22, 0.42, 0.06), Vector3(0.0, 1.4, -0.88), _glass)
	_box_variant("MonsterHood", Vector3(1.3, 0.3, 0.72), Vector3(0.0, 1.0, -1.18), _orange)
	_cylinder_variant("MonsterFrontBar", Vector3(-0.9, 0.58, -1.72), Vector3(0.9, 0.58, -1.72), 0.09, _metal)
	_cylinder_variant("MonsterRoofBar", Vector3(-0.72, 1.75, 0.45), Vector3(0.72, 1.75, 0.45), 0.075, _orange)
	_box_variant("MonsterRearBed", Vector3(1.3, 0.28, 0.82), Vector3(0.0, 0.9, 1.08), _dark)
	_box_variant("MonsterEngine", Vector3(0.8, 0.42, 0.72), Vector3(0.0, 1.18, 0.92), _metal)
	_cylinder_variant("MonsterExhaust", Vector3(0.72, 0.75, 0.82), Vector3(0.72, 1.55, 0.82), 0.07, _metal)
	for x in [-0.88, 0.88]:
		_cylinder_variant("MonsterShock", Vector3(x, -0.05, -1.0), Vector3(x, 0.75, -1.0), 0.075, _orange)
		_cylinder_variant("MonsterShockRear", Vector3(x, -0.05, 1.0), Vector3(x, 0.75, 1.0), 0.075, _orange)
	_sphere_variant("MonsterHeadlight", Vector3(-0.58, 1.08, -1.56), 0.13, _light)
	_sphere_variant("MonsterHeadlight", Vector3(0.58, 1.08, -1.56), 0.13, _light)
	_build_rider(Vector3(0.0, 0.0, 0.05), _orange, 0.82)


func _build_rider(offset: Vector3, accent: Material, scale_factor: float) -> void:
	var head_position := offset + Vector3(0.0, 1.25 * scale_factor, -0.02)
	_sphere_variant("VariantHelmet", head_position, 0.22 * scale_factor, accent)
	_sphere_variant("VariantVisor", head_position + Vector3(0.0, 0.0, -0.17 * scale_factor), 0.14 * scale_factor, _glass)
	_box_variant("VariantTorso", Vector3(0.38, 0.48, 0.28) * scale_factor, offset + Vector3(0.0, 0.84 * scale_factor, 0.12), _suit)
	_cylinder_variant("VariantArmNear", offset + Vector3(-0.16, 1.0 * scale_factor, -0.02), offset + Vector3(-0.28, 0.82 * scale_factor, -0.42), 0.055 * scale_factor, _suit)
	_cylinder_variant("VariantArmFar", offset + Vector3(0.16, 1.0 * scale_factor, -0.02), offset + Vector3(0.28, 0.82 * scale_factor, -0.42), 0.055 * scale_factor, _suit)


func _box_variant(node_name: String, mesh_size: Vector3, position: Vector3, material: Material) -> void:
	_box(node_name, mesh_size, position, material, _variant_root)


func _sphere_variant(node_name: String, position: Vector3, radius: float, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position
	_variant_root.add_child(visual)


func _cylinder_variant(node_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var visual := Node3D.new()
	visual.name = node_name
	_variant_root.add_child(visual)
	_set_segment(visual, start, end, radius, material)


func _hide_placeholder_visuals() -> void:
	for node_name in [
		"ChassisVisual",
		"CabinVisual",
		"UnderbodyVisual",
		"RoofVisual",
		"FrontBumperVisual",
		"RearBumperVisual",
		"RearSuspensionNear",
		"RearSuspensionFar",
		"FrontSuspensionNear",
		"FrontSuspensionFar",
		"RearContactDebug",
		"FrontContactDebug",
	]:
		var visual := get_parent().get_node_or_null(node_name) as Node3D
		if visual:
			visual.visible = false


func _process(delta: float) -> void:
	_visual_time += delta
	var controller := get_parent() as VehicleController
	if controller and _visual_root:
		var compression_total := 0.0
		var contact_count := 0
		for wheel: Dictionary in controller._wheels:
			if wheel["in_contact"]:
				compression_total += float(wheel["compression"])
				contact_count += 1
		var average_compression := compression_total / float(maxi(contact_count, 1))
		var vibration := sin(_visual_time * 38.0) * controller.throttle_input * 0.006
		var target_bounce := -average_compression * 0.045 + vibration
		_body_bounce = lerpf(_body_bounce, target_bounce, 1.0 - exp(-12.0 * delta))
		_visual_root.position.y = _body_bounce
	_update_shocks()


func _create_materials() -> void:
	_orange = _material(Color(1.0, 0.18, 0.015), 0.38, 0.2)
	_dark = _material(Color(0.045, 0.055, 0.065), 0.7, 0.0)
	_rubber = _material(Color(0.025, 0.028, 0.03), 0.96, 0.0)
	_metal = _material(Color(0.32, 0.37, 0.4), 0.3, 0.75)
	_glass = _material(Color(0.08, 0.22, 0.3), 0.12, 0.15)
	_light = _material(Color(1.0, 0.78, 0.32), 0.16, 0.0)
	_light.emission_enabled = true
	_light.emission = Color(1.0, 0.34, 0.06)
	_spring = _material(Color(1.0, 0.42, 0.06), 0.42, 0.2)
	_brake = _material(Color(0.16, 0.18, 0.2), 0.35, 0.85)
	_tread = _material(Color(0.012, 0.014, 0.016), 0.98, 0.0)
	_skin = _material(Color(0.48, 0.21, 0.11), 0.9, 0.0)
	_suit = _material(Color(0.06, 0.08, 0.11), 0.75, 0.0)
	_harness = _material(Color(0.78, 0.12, 0.035), 0.62, 0.0)


func _build_body() -> void:
	_box("LowerChassisVisual", Vector3(1.5, 0.3, 2.85), Vector3(0.0, -0.02, 0.0), _dark)
	_box("SidePanelNear", Vector3(0.08, 0.62, 2.05), Vector3(NEAR_X, 0.32, 0.2), _orange)
	_box("SidePanelFar", Vector3(0.08, 0.62, 2.05), Vector3(FAR_X, 0.32, 0.2), _orange)
	_box("NosePanel", Vector3(1.5, 0.22, 1.05), Vector3(0.0, 0.55, -1.02), _orange)
	_box("NoseGuard", Vector3(1.7, 0.16, 0.18), Vector3(0.0, 0.18, -1.65), _dark)
	_box("EngineCover", Vector3(1.25, 0.24, 0.85), Vector3(0.0, 0.67, 0.82), _dark)
	_box("Dashboard", Vector3(1.25, 0.12, 0.7), Vector3(0.0, 0.82, -0.28), _dark)
	_box("Windshield", Vector3(1.18, 0.05, 0.72), Vector3(0.0, 1.02, -0.38), _glass)
	_box("SeatNear", Vector3(0.45, 0.65, 0.58), Vector3(0.55, 0.75, 0.28), _dark)
	_box("SeatFar", Vector3(0.45, 0.65, 0.58), Vector3(-0.55, 0.75, 0.28), _dark)
	for x in [NEAR_X, FAR_X]:
		_box("FrontFender", Vector3(0.14, 0.16, 1.15), Vector3(x, 0.32, -1.02), _dark)
		_box("RearFender", Vector3(0.14, 0.16, 1.15), Vector3(x, 0.32, 1.02), _dark)
	_box("FrontLightBar", Vector3(0.82, 0.08, 0.08), Vector3(0.0, 0.78, -1.56), _light)
	_box("SkidPlate", Vector3(1.0, 0.08, 0.82), Vector3(0.0, -0.22, -0.82), _metal)
	_box("RearDeckPanel", Vector3(1.1, 0.12, 0.72), Vector3(0.0, 0.52, 1.15), _orange)
	_cylinder_between("FrontBumperLower", Vector3(-0.74, 0.18, -1.68), Vector3(0.74, 0.18, -1.68), 0.075, _dark)
	_cylinder_between("FrontBumperLeft", Vector3(-0.74, 0.18, -1.68), Vector3(-0.82, 0.42, -1.28), 0.06, _dark)
	_cylinder_between("FrontBumperRight", Vector3(0.74, 0.18, -1.68), Vector3(0.82, 0.42, -1.28), 0.06, _dark)
	_cylinder_between("RearBumper", Vector3(-0.68, 0.28, 1.55), Vector3(0.68, 0.28, 1.55), 0.07, _dark)
	_build_driver()


func _build_driver() -> void:
	var driver_x := 0.72
	_box("DriverSeatBack", Vector3(0.42, 0.78, 0.16), Vector3(driver_x, 0.78, 0.42), _suit)
	_box("DriverTorso", Vector3(0.42, 0.52, 0.34), Vector3(driver_x, 0.74, 0.12), _suit)
	_sphere("DriverNeck", Vector3(driver_x, 1.02, 0.08), 0.10, _skin)
	_sphere("DriverHelmet", Vector3(driver_x, 1.25, 0.08), 0.27, _orange)
	_sphere("DriverVisor", Vector3(driver_x, 1.27, -0.15), 0.18, _glass)
	_box("HelmetChinGuard", Vector3(0.28, 0.14, 0.15), Vector3(driver_x, 1.11, -0.14), _dark)
	_cylinder_between("HarnessNear", Vector3(0.54, 0.94, -0.08), Vector3(driver_x, 0.55, -0.08), 0.04, _harness)
	_cylinder_between("HarnessFar", Vector3(0.9, 0.94, -0.08), Vector3(driver_x, 0.55, -0.08), 0.04, _harness)
	_cylinder_between("DriverArmNear", Vector3(0.56, 0.84, -0.02), Vector3(0.68, 0.69, -0.42), 0.075, _suit)
	_cylinder_between("DriverArmFar", Vector3(0.88, 0.84, -0.02), Vector3(0.78, 0.69, -0.42), 0.075, _suit)
	_sphere("DriverGloveNear", Vector3(0.68, 0.69, -0.44), 0.12, _harness)
	_sphere("DriverGloveFar", Vector3(0.78, 0.69, -0.44), 0.12, _harness)
	_torus("SteeringWheel", Vector3(0.73, 0.70, -0.45), 0.22, _dark, Vector3(PI * 0.5, 0.0, 0.0))
	_cylinder_between("SteeringColumn", Vector3(0.73, 0.72, -0.28), Vector3(0.73, 0.70, -0.45), 0.045, _metal)
	_sphere("SteeringHub", Vector3(0.73, 0.70, -0.45), 0.055, _orange)
	_box("DashboardCluster", Vector3(0.16, 0.18, 0.34), Vector3(0.91, 0.84, -0.36), _dark)
	_sphere("DashboardGauge", Vector3(0.925, 0.87, -0.46), 0.07, _light)


func _build_cage() -> void:
	var points := [
		[Vector3(NEAR_X, 0.35, -1.15), Vector3(NEAR_X, 1.75, -0.65)],
		[Vector3(NEAR_X, 1.75, -0.65), Vector3(NEAR_X, 1.72, 0.95)],
		[Vector3(NEAR_X, 1.72, 0.95), Vector3(NEAR_X, 0.42, 1.35)],
		[Vector3(FAR_X, 0.35, -1.15), Vector3(FAR_X, 1.75, -0.65)],
		[Vector3(FAR_X, 1.75, -0.65), Vector3(FAR_X, 1.72, 0.95)],
		[Vector3(FAR_X, 1.72, 0.95), Vector3(FAR_X, 0.42, 1.35)],
		[Vector3(NEAR_X, 1.75, -0.65), Vector3(FAR_X, 1.75, -0.65)],
		[Vector3(NEAR_X, 1.72, 0.95), Vector3(FAR_X, 1.72, 0.95)],
	]
	for index in range(points.size()):
		_cylinder_between("RollCage_%d" % index, points[index][0], points[index][1], 0.075, _orange)
		_cylinder_between("CageBrace_%d" % index, points[index][0].lerp(points[index][1], 0.35), points[index][1], 0.045, _dark)


func _build_lights_and_details() -> void:
	for x in [NEAR_X, FAR_X]:
		_sphere("Headlight", Vector3(x, 0.7, -1.62), 0.16, _light)
		_cylinder_between("FrontAArm", Vector3(x, -0.05, -1.15), Vector3(x, 0.38, -1.0), 0.045, _metal)
		_cylinder_between("RearAArm", Vector3(x, -0.05, 1.12), Vector3(x, 0.38, 0.98), 0.045, _metal)
	_sphere("EngineIntake", Vector3(0.0, 0.92, 0.93), 0.18, _metal)
	_cylinder_between("Exhaust", Vector3(0.0, 0.22, 1.15), Vector3(0.0, 0.22, 1.7), 0.07, _metal)
	_box("RearLightBar", Vector3(0.8, 0.12, 0.08), Vector3(0.0, 0.68, 1.48), _light)
	var left_lamp := OmniLight3D.new()
	left_lamp.name = "HeadlightNearGlow"
	left_lamp.position = Vector3(NEAR_X, 0.7, -1.72)
	left_lamp.light_color = Color(1.0, 0.78, 0.48)
	left_lamp.light_energy = 0.45
	left_lamp.omni_range = 4.0
	left_lamp.shadow_enabled = false
	_visual_root.add_child(left_lamp)


func _build_wheels() -> void:
	for wheel_name in _wheel_names:
		var wheel := get_parent().get_node(wheel_name) as Node3D
		var old_tire := wheel.get_node_or_null("TireMesh") as MeshInstance3D
		var old_rim := wheel.get_node_or_null("RimMesh") as MeshInstance3D
		if old_tire:
			old_tire.visible = false
		if old_rim:
			old_rim.visible = false
		var tire := MeshInstance3D.new()
		tire.name = "ChunkyTire"
		var tire_mesh := CylinderMesh.new()
		tire_mesh.top_radius = 0.48
		tire_mesh.bottom_radius = 0.48
		tire_mesh.height = 0.34
		tire_mesh.radial_segments = 24
		tire.mesh = tire_mesh
		tire.material_override = _rubber
		tire.rotation_degrees.z = 90.0
		wheel.add_child(tire)
		var rim := MeshInstance3D.new()
		rim.name = "AlloyRim"
		var rim_mesh := CylinderMesh.new()
		rim_mesh.top_radius = 0.27
		rim_mesh.bottom_radius = 0.27
		rim_mesh.height = 0.37
		rim_mesh.radial_segments = 16
		rim.mesh = rim_mesh
		rim.material_override = _metal
		rim.rotation_degrees.z = 90.0
		wheel.add_child(rim)
		var brake_disc := MeshInstance3D.new()
		brake_disc.name = "BrakeDisc"
		var disc_mesh := CylinderMesh.new()
		disc_mesh.top_radius = 0.2
		disc_mesh.bottom_radius = 0.2
		disc_mesh.height = 0.035
		disc_mesh.radial_segments = 20
		brake_disc.mesh = disc_mesh
		brake_disc.material_override = _brake
		brake_disc.rotation_degrees.z = 90.0
		brake_disc.position.x = -0.19 if wheel_name.contains("Far") else 0.19
		wheel.add_child(brake_disc)
		for spoke_index in range(6):
			var spoke := MeshInstance3D.new()
			var spoke_mesh := BoxMesh.new()
			spoke_mesh.size = Vector3(0.08, 0.075, 0.29)
			spoke.mesh = spoke_mesh
			spoke.material_override = _orange
			spoke.position.x = -0.205 if wheel_name.contains("Far") else 0.205
			spoke.rotation_degrees = Vector3(0.0, 0.0, float(spoke_index) * 60.0)
			wheel.add_child(spoke)
		var hub := MeshInstance3D.new()
		hub.name = "WheelHub"
		var hub_mesh := CylinderMesh.new()
		hub_mesh.top_radius = 0.09
		hub_mesh.bottom_radius = 0.09
		hub_mesh.height = 0.4
		hub_mesh.radial_segments = 12
		hub.mesh = hub_mesh
		hub.material_override = _metal
		hub.rotation_degrees.z = 90.0
		wheel.add_child(hub)
		_build_tread_blocks(wheel)


func _build_tread_blocks(wheel: Node3D) -> void:
	for tread_index in range(14):
		var angle := TAU * float(tread_index) / 14.0
		var block := MeshInstance3D.new()
		block.name = "TreadBlock_%02d" % tread_index
		var block_mesh := BoxMesh.new()
		block_mesh.size = Vector3(0.38, 0.105, 0.18)
		block.mesh = block_mesh
		block.material_override = _tread
		block.position = Vector3(0.0, sin(angle) * 0.47, cos(angle) * 0.47)
		block.rotation.x = angle
		wheel.add_child(block)


func _build_suspension() -> void:
	for wheel_name in ["RearWheelNear", "FrontWheelNear", "RearWheelFar", "FrontWheelFar"]:
		var shock := Node3D.new()
		shock.name = "VisibleShock_" + wheel_name
		_visual_root.add_child(shock)
		_shock_roots.append(shock)


func _update_shocks() -> void:
	var anchors := [
		Vector3(NEAR_X, -0.1, 1.05), Vector3(NEAR_X, -0.1, -1.05),
		Vector3(FAR_X, -0.1, 1.05), Vector3(FAR_X, -0.1, -1.05)
	]
	for index in range(_shock_roots.size()):
		var wheel := get_parent().get_node(_wheel_names[index]) as Node3D
		var shock := _shock_roots[index]
		var target := wheel.position + Vector3(0.0, 0.1, 0.0)
		_set_segment(shock, anchors[index], target, 0.055, _spring)


func _box(
	node_name: String,
	size: Vector3,
	position: Vector3,
	material: Material,
	parent: Node3D = null
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position
	var target := _visual_root if parent == null else parent
	target.add_child(visual)


func _sphere(node_name: String, position: Vector3, radius: float, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position
	_visual_root.add_child(visual)


func _torus(
	node_name: String,
	position: Vector3,
	radius: float,
	material: Material,
	rotation: Vector3 = Vector3.ZERO
) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.72
	mesh.outer_radius = radius
	mesh.rings = 12
	mesh.ring_segments = 8
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = position
	visual.rotation = rotation
	_visual_root.add_child(visual)


func _cylinder_between(node_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var visual := Node3D.new()
	visual.name = node_name
	_visual_root.add_child(visual)
	_set_segment(visual, start, end, radius, material)


func _set_segment(node: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var mesh_visual := node.get_node_or_null("Segment") as MeshInstance3D
	if mesh_visual == null:
		mesh_visual = MeshInstance3D.new()
		mesh_visual.name = "Segment"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1.0
		mesh.bottom_radius = 1.0
		mesh.height = 1.0
		mesh.radial_segments = 8
		mesh_visual.mesh = mesh
		mesh_visual.material_override = material
		node.add_child(mesh_visual)
	var delta := end - start
	node.position = (start + end) * 0.5
	node.basis = Basis(Quaternion(Vector3.UP, delta.normalized()))
	node.scale = Vector3(radius, delta.length() * 0.5, radius)


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material
