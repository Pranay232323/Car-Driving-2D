extends Node3D
class_name VehicleVisuals

const NEAR_X := 0.88
const FAR_X := -0.88

var _primary: StandardMaterial3D
var _secondary: StandardMaterial3D
var _dark: StandardMaterial3D
var _rubber: StandardMaterial3D
var _metal: StandardMaterial3D
var _chrome: StandardMaterial3D
var _glass: StandardMaterial3D
var _light: StandardMaterial3D
var _brake_light: StandardMaterial3D
var _spring: StandardMaterial3D
var _tread: StandardMaterial3D
var _suit: StandardMaterial3D
var _skin: StandardMaterial3D
var _harness: StandardMaterial3D

var _visual_root: Node3D
var _vehicle_root: Node3D
var _variant_name := "Buggy"
var _shock_roots: Array[Node3D] = []
var _wheel_names := ["RearWheelNear", "RearWheelFar", "FrontWheelNear", "FrontWheelFar"]
var _visual_time := 0.0
var _body_bounce := 0.0
var _body_pitch := 0.0
var _driver_head: Node3D = null
var _exhaust_flame: MeshInstance3D = null
var _nitro_mat: StandardMaterial3D
var _dust_emitters: Array[GPUParticles3D] = []


func _ready() -> void:
	_create_materials()
	_hide_placeholder_visuals()
	_visual_root = Node3D.new()
	_visual_root.name = "VehicleVisualRoot"
	add_child(_visual_root)

	_vehicle_root = Node3D.new()
	_vehicle_root.name = "VehicleGeometryRoot"
	_visual_root.add_child(_vehicle_root)

	_build_wheels()
	_build_suspension()
	_build_dust_emitters()

	# Initial vehicle build
	set_vehicle_variant("Buggy", Color(1.0, 0.52, 0.08))


func set_vehicle_variant(variant_name: String, accent_color: Color) -> void:
	_variant_name = variant_name
	_primary.albedo_color = accent_color
	_light.emission = accent_color.lightened(0.2)
	_spring.albedo_color = accent_color

	# Clear previous custom vehicle parts
	for child in _vehicle_root.get_children():
		child.queue_free()

	# Build modern vehicle based on selected variant
	match variant_name:
		"Buggy":
			_build_buggy(accent_color)
		"Monster Truck":
			_build_monster_truck(accent_color)
		"Jeep":
			_build_jeep(accent_color)
		"Truck":
			_build_truck(accent_color)
		"Sport SUV":
			_build_sport_suv(accent_color)
		"Trail Bike":
			_build_trail_bike(accent_color)
		"Quad Runner":
			_build_quad_runner(accent_color)
		_:
			_build_buggy(accent_color)

	_set_wheel_style(variant_name)


func _set_wheel_style(variant_name: String) -> void:
	var wheel_scale := 1.0
	match variant_name:
		"Monster Truck":
			wheel_scale = 1.45
		"Trail Bike":
			wheel_scale = 0.92
		"Jeep", "Truck":
			wheel_scale = 1.08
		"Sport SUV":
			wheel_scale = 0.98

	for wheel_name in _wheel_names:
		var wheel := get_parent().get_node_or_null(wheel_name) as Node3D
		if wheel:
			wheel.scale = Vector3.ONE * wheel_scale
			# For 2-wheeled bike, show only near wheels in 2.5D side view
			wheel.visible = variant_name != "Trail Bike" or wheel_name.ends_with("Near")


# ==============================================================================
# 1. RACING BUGGY (Dune Buggy / Sand Rail) - Matches Reference 1 & 3
# ==============================================================================
func _build_buggy(accent: Color) -> void:
	# Tubular perimeter frame & lower chassis skid plate
	_box("ChassisPlate", Vector3(1.35, 0.16, 2.7), Vector3(0.0, 0.02, 0.0), _dark)
	_box("LowerSkid", Vector3(0.9, 0.12, 2.1), Vector3(0.0, -0.12, -0.2), _metal)

	# Aerodynamic Side Pods / Livery Panels
	_box("SidePodNear", Vector3(0.12, 0.42, 1.8), Vector3(NEAR_X - 0.04, 0.28, 0.05), _primary)
	_box("SidePodFar", Vector3(0.12, 0.42, 1.8), Vector3(FAR_X + 0.04, 0.28, 0.05), _primary)
	_box("NoseWedge", Vector3(1.15, 0.22, 0.9), Vector3(0.0, 0.36, -0.95), _primary)
	_box("NoseTip", Vector3(0.85, 0.14, 0.45), Vector3(0.0, 0.24, -1.45), _primary)

	# Front Tubular Pre-Runner Bumper
	_cylinder("BumperMain", Vector3(-0.65, 0.18, -1.65), Vector3(0.65, 0.18, -1.65), 0.065, _dark)
	_cylinder("BumperUpL", Vector3(-0.65, 0.18, -1.65), Vector3(-0.45, 0.45, -1.45), 0.05, _dark)
	_cylinder("BumperUpR", Vector3(0.65, 0.18, -1.65), Vector3(0.45, 0.45, -1.45), 0.05, _dark)
	_box("SkidPlate", Vector3(0.72, 0.06, 0.5), Vector3(0.0, 0.05, -1.35), _metal)

	# Twin Front Headlights (Warm glowing yellow fog lamps from Reference 3)
	_sphere("HeadlightL", Vector3(0.38, 0.46, -1.5), 0.13, _light)
	_sphere("HeadlightR", Vector3(-0.38, 0.46, -1.5), 0.13, _light)

	# Tubular Roll Cage (Full 3D Roll Cage)
	var cage_h := 1.35
	# A-pillars (front angled)
	_cylinder("CageAPillarNear", Vector3(0.55, 0.4, -0.65), Vector3(0.48, cage_h, -0.1), 0.055, _dark)
	_cylinder("CageAPillarFar", Vector3(-0.55, 0.4, -0.65), Vector3(-0.48, cage_h, -0.1), 0.055, _dark)
	# B-pillars & C-pillars (roof & rear angled down)
	_cylinder("CageRoofNear", Vector3(0.48, cage_h, -0.1), Vector3(0.52, cage_h, 0.8), 0.055, _dark)
	_cylinder("CageRoofFar", Vector3(-0.48, cage_h, -0.1), Vector3(-0.52, cage_h, 0.8), 0.055, _dark)
	_cylinder("CageRearNear", Vector3(0.52, cage_h, 0.8), Vector3(0.62, 0.25, 1.45), 0.055, _dark)
	_cylinder("CageRearFar", Vector3(-0.52, cage_h, 0.8), Vector3(-0.62, 0.25, 1.45), 0.055, _dark)
	# Crossbars
	_cylinder("CageFrontCross", Vector3(-0.48, cage_h, -0.1), Vector3(0.48, cage_h, -0.1), 0.05, _dark)
	_cylinder("CageMidCross", Vector3(-0.52, cage_h, 0.8), Vector3(0.52, cage_h, 0.8), 0.05, _dark)

	# Roof Light Bar with 4 Spotlights
	for i in range(4):
		var lamp_x := -0.36 + float(i) * 0.24
		_cylinder("RoofSpot_%d" % i, Vector3(lamp_x, cage_h + 0.12, -0.05), Vector3(lamp_x, cage_h + 0.12, -0.18), 0.08, _metal)
		_sphere("RoofLamp_%d" % i, Vector3(lamp_x, cage_h + 0.12, -0.2), 0.065, _light)

	# Rear Engine Bay & Exhaust
	_box("EngineBlock", Vector3(0.72, 0.44, 0.65), Vector3(0.0, 0.42, 1.05), _metal)
	_cylinder("AirIntake", Vector3(0.0, 0.65, 0.95), Vector3(0.0, 0.95, 0.85), 0.09, _chrome)
	_sphere("AirFilter", Vector3(0.0, 1.0, 0.85), 0.14, _primary)
	_cylinder("ExhaustL", Vector3(0.25, 0.35, 1.2), Vector3(0.28, 0.38, 1.62), 0.055, _chrome)
	_cylinder("ExhaustR", Vector3(-0.25, 0.35, 1.2), Vector3(-0.28, 0.38, 1.62), 0.055, _chrome)

	# Racing Bucket Seats & Human Driver
	_build_bucket_seat(Vector3(0.32, 0.32, 0.22), _primary)
	_build_bucket_seat(Vector3(-0.32, 0.32, 0.22), _primary)
	_build_human_driver(Vector3(0.32, 0.32, 0.22), false, accent)


# ==============================================================================
# 2. MONSTER TRUCK - Matches Reference 1
# ==============================================================================
func _build_monster_truck(accent: Color) -> void:
	# Heavy Lifted Chassis Cradle & Monster Axles
	_box("MonsterSubframe", Vector3(1.3, 0.35, 2.8), Vector3(0.0, 0.55, 0.0), _dark)
	_box("MonsterTransmission", Vector3(0.65, 0.45, 0.85), Vector3(0.0, 0.4, 0.0), _metal)
	_cylinder("DriveShaftFront", Vector3(0.0, 0.4, 0.0), Vector3(0.0, 0.15, -1.05), 0.07, _chrome)
	_cylinder("DriveShaftRear", Vector3(0.0, 0.4, 0.0), Vector3(0.0, 0.15, 1.05), 0.07, _chrome)
	# Massive Monster Shock Towers (dual shocks on each corner)
	for x in [-0.75, 0.75]:
		for z in [-1.05, 1.05]:
			_cylinder("MonsterShock_%d_%d" % [int(x*10), int(z*10)], Vector3(x, 0.0, z), Vector3(x * 0.8, 0.75, z * 0.7), 0.08, _primary)

	# Truck Cab Body
	_box("CabMain", Vector3(1.45, 0.72, 1.3), Vector3(0.0, 1.15, -0.05), _primary)
	_box("TruckHood", Vector3(1.42, 0.38, 0.95), Vector3(0.0, 0.95, -1.1), _primary)
	_box("TruckBed", Vector3(1.45, 0.48, 1.05), Vector3(0.0, 1.0, 1.0), _primary)
	_box("BedFloor", Vector3(1.25, 0.12, 0.95), Vector3(0.0, 0.85, 1.0), _dark)

	# Chrome Grille & Heavy Winch Bumper
	_box("FrontGrille", Vector3(1.32, 0.32, 0.12), Vector3(0.0, 0.98, -1.6), _chrome)
	_box("MonsterBumper", Vector3(1.65, 0.28, 0.22), Vector3(0.0, 0.65, -1.72), _metal)
	_sphere("HeadlightL", Vector3(0.52, 1.02, -1.6), 0.14, _light)
	_sphere("HeadlightR", Vector3(-0.52, 1.02, -1.6), 0.14, _light)

	# Tinted Glass Windows
	_box("Windshield", Vector3(1.32, 0.46, 0.08), Vector3(0.0, 1.32, -0.68), _glass)
	_box("SideWindowNear", Vector3(0.06, 0.38, 0.75), Vector3(0.72, 1.32, -0.05), _glass)
	_box("SideWindowFar", Vector3(0.06, 0.38, 0.75), Vector3(-0.72, 1.32, -0.05), _glass)

	# Roof Roll Bar with 5 Spotlights
	_cylinder("RoofBarL", Vector3(0.68, 1.5, 0.55), Vector3(0.68, 1.85, 0.55), 0.06, _chrome)
	_cylinder("RoofBarR", Vector3(-0.68, 1.5, 0.55), Vector3(-0.68, 1.85, 0.55), 0.06, _chrome)
	_cylinder("RoofCrossBar", Vector3(-0.68, 1.85, 0.55), Vector3(0.68, 1.85, 0.55), 0.06, _chrome)
	for i in range(5):
		var lamp_x := -0.5 + float(i) * 0.25
		_sphere("Spot_%d" % i, Vector3(lamp_x, 1.95, 0.52), 0.09, _light)

	# High Elevated Human Driver Inside Cab
	_build_human_driver(Vector3(0.35, 0.95, -0.05), false, accent)


# ==============================================================================
# 3. JEEP 4x4 OFFROADER - Matches Reference 1
# ==============================================================================
func _build_jeep(accent: Color) -> void:
	# Boxy 4x4 Rugged Frame
	_box("JeepChassis", Vector3(1.35, 0.2, 2.7), Vector3(0.0, 0.25, 0.0), _dark)
	_box("JeepBodyMain", Vector3(1.4, 0.65, 1.6), Vector3(0.0, 0.72, 0.25), _primary)
	_box("JeepHood", Vector3(1.25, 0.38, 0.95), Vector3(0.0, 0.7, -0.95), _primary)

	# Iconic 7-Slot Grille & Round Headlights
	_box("JeepGrille", Vector3(1.15, 0.35, 0.08), Vector3(0.0, 0.68, -1.45), _dark)
	for i in range(7):
		var slot_x := -0.36 + float(i) * 0.12
		_box("GrilleSlot_%d" % i, Vector3(0.04, 0.24, 0.09), Vector3(slot_x, 0.68, -1.45), _primary)
	_sphere("JeepHeadlightL", Vector3(0.48, 0.68, -1.46), 0.13, _light)
	_sphere("JeepHeadlightR", Vector3(-0.48, 0.68, -1.46), 0.13, _light)
	_box("JeepBumper", Vector3(1.55, 0.18, 0.18), Vector3(0.0, 0.38, -1.55), _dark)

	# Square Cab, Windshield & Roof Rack
	_box("JeepCab", Vector3(1.32, 0.62, 1.3), Vector3(0.0, 1.25, 0.28), _primary)
	_box("JeepWindshield", Vector3(1.22, 0.44, 0.06), Vector3(0.0, 1.26, -0.38), _glass)
	_box("JeepSideGlassNear", Vector3(0.05, 0.36, 1.05), Vector3(0.66, 1.26, 0.32), _glass)
	_box("JeepSideGlassFar", Vector3(0.05, 0.36, 1.05), Vector3(-0.66, 1.26, 0.32), _glass)

	# Tubular Roof Rack with 4 Spotlights
	_box("RoofRackFrame", Vector3(1.25, 0.08, 1.35), Vector3(0.0, 1.62, 0.28), _dark)
	for i in range(4):
		var lamp_x := -0.36 + float(i) * 0.24
		_sphere("RoofSpot_%d" % i, Vector3(lamp_x, 1.72, -0.35), 0.08, _light)

	# Rear-Mounted Spare Tire
	_cylinder("SpareTire", Vector3(0.0, 0.75, 1.2), Vector3(0.0, 0.75, 1.48), 0.42, _rubber)
	_cylinder("SpareRim", Vector3(0.0, 0.75, 1.3), Vector3(0.0, 0.75, 1.52), 0.24, _metal)

	# Human Driver Inside
	_build_human_driver(Vector3(0.32, 0.68, 0.05), false, accent)


# ==============================================================================
# 4. OFFROAD TRUCK (Heavy Duty Pickup) - Matches Reference 1
# ==============================================================================
func _build_truck(accent: Color) -> void:
	# Heavy Long Crew Cab & Sturdy Bed
	_box("TruckFrame", Vector3(1.4, 0.22, 3.1), Vector3(0.0, 0.32, 0.0), _dark)
	_box("TruckCab", Vector3(1.5, 0.72, 1.55), Vector3(0.0, 0.88, -0.2), _primary)
	_box("TruckHood", Vector3(1.45, 0.4, 1.05), Vector3(0.0, 0.82, -1.25), _primary)
	_box("TruckBed", Vector3(1.5, 0.5, 1.4), Vector3(0.0, 0.78, 1.05), _primary)
	_box("BedInterior", Vector3(1.3, 0.35, 1.25), Vector3(0.0, 0.75, 1.05), _dark)

	# Muscular Grille & Horizontal LED Bar
	_box("FrontGrille", Vector3(1.35, 0.34, 0.12), Vector3(0.0, 0.82, -1.78), _dark)
	_box("LEDLightBar", Vector3(1.2, 0.06, 0.06), Vector3(0.0, 0.95, -1.82), _light)
	_box("TruckBumper", Vector3(1.65, 0.25, 0.2), Vector3(0.0, 0.48, -1.85), _metal)

	# Windshield & Tinted Windows
	_box("Windshield", Vector3(1.36, 0.46, 0.08), Vector3(0.0, 1.12, -0.92), _glass)
	_box("SideGlassNear", Vector3(0.06, 0.38, 1.2), Vector3(0.74, 1.12, -0.15), _glass)
	_box("SideGlassFar", Vector3(0.06, 0.38, 1.2), Vector3(-0.74, 1.12, -0.15), _glass)

	# Tubular Bed Chase Rack / Roll Bar
	_cylinder("ChaseRackNear", Vector3(0.68, 0.95, 0.55), Vector3(0.68, 1.45, 0.55), 0.06, _dark)
	_cylinder("ChaseRackFar", Vector3(-0.68, 0.95, 0.55), Vector3(-0.68, 1.45, 0.55), 0.06, _dark)
	_cylinder("ChaseRackTop", Vector3(-0.68, 1.45, 0.55), Vector3(0.68, 1.45, 0.55), 0.06, _dark)
	_cylinder("ChaseRackAngleNear", Vector3(0.68, 1.45, 0.55), Vector3(0.68, 0.95, 1.45), 0.05, _dark)
	_cylinder("ChaseRackAngleFar", Vector3(-0.68, 1.45, 0.55), Vector3(-0.68, 0.95, 1.45), 0.05, _dark)

	# Human Driver Inside Cab
	_build_human_driver(Vector3(0.35, 0.72, -0.18), false, accent)


# ==============================================================================
# 5. SPORT SUV (Performance Aerodynamic SUV) - Matches Reference 1
# ==============================================================================
func _build_sport_suv(accent: Color) -> void:
	# Sleek Aerodynamic Body
	_box("SUVBase", Vector3(1.4, 0.2, 2.9), Vector3(0.0, 0.3, 0.0), _dark)
	_box("SUVBodyLower", Vector3(1.5, 0.52, 2.8), Vector3(0.0, 0.65, 0.0), _primary)
	_box("SUVNose", Vector3(1.42, 0.35, 0.95), Vector3(0.0, 0.72, -1.15), _primary)

	# Aerodynamic Glass House (Cabin & Windshield)
	_box("SUVCabin", Vector3(1.35, 0.55, 1.7), Vector3(0.0, 1.12, 0.15), _primary)
	_box("SUVWindshield", Vector3(1.26, 0.44, 0.12), Vector3(0.0, 1.12, -0.65), _glass)
	_box("SUVSideNear", Vector3(0.06, 0.38, 1.45), Vector3(0.66, 1.12, 0.22), _glass)
	_box("SUVSideFar", Vector3(0.06, 0.38, 1.45), Vector3(-0.66, 1.12, 0.22), _glass)
	_box("SUVRearSpoiler", Vector3(1.25, 0.06, 0.32), Vector3(0.0, 1.44, 1.15), _dark)

	# Sport Grille & Angular LED Headlights
	_box("SUVGrille", Vector3(1.15, 0.28, 0.1), Vector3(0.0, 0.65, -1.65), _dark)
	_box("HeadlightL", Vector3(0.32, 0.08, 0.12), Vector3(0.48, 0.78, -1.62), _light)
	_box("HeadlightR", Vector3(0.32, 0.08, 0.12), Vector3(-0.48, 0.78, -1.62), _light)

	# Slim Low-Profile Roof Rack with Light Bar
	_box("RoofRailL", Vector3(0.05, 0.06, 1.25), Vector3(0.55, 1.44, 0.25), _dark)
	_box("RoofRailR", Vector3(0.05, 0.06, 1.25), Vector3(-0.55, 1.44, 0.25), _dark)
	_box("RoofSlimLight", Vector3(0.9, 0.04, 0.06), Vector3(0.0, 1.46, -0.42), _light)

	# Human Driver Inside
	_build_human_driver(Vector3(0.32, 0.62, -0.05), false, accent)


# ==============================================================================
# 6. TRAIL BIKE / DIRT BIKE (Motocross) - Matches Reference 1 & 2
# ==============================================================================
func _build_trail_bike(accent: Color) -> void:
	# Motocross Frame & Exposed 4-Stroke Engine
	_cylinder("BikeFrameDown", Vector3(0.0, 0.72, -0.35), Vector3(0.0, 0.22, -0.05), 0.048, _dark)
	_cylinder("BikeFrameBottom", Vector3(0.0, 0.22, -0.05), Vector3(0.0, 0.25, 0.65), 0.048, _dark)
	_cylinder("BikeSwingArm", Vector3(0.0, 0.25, 0.45), Vector3(0.0, -0.1, 1.05), 0.055, _metal)
	_box("BikeEngine", Vector3(0.32, 0.38, 0.44), Vector3(0.0, 0.35, 0.15), _metal)

	# Inverted Telescopic Front Forks connecting to front axle
	_cylinder("FrontForkL", Vector3(0.12, 0.88, -0.65), Vector3(0.12, -0.1, -1.05), 0.042, _metal)
	_cylinder("FrontForkR", Vector3(-0.12, 0.88, -0.65), Vector3(-0.12, -0.1, -1.05), 0.042, _metal)
	_cylinder("ForkTripleClamp", Vector3(-0.15, 0.88, -0.65), Vector3(0.15, 0.88, -0.65), 0.05, _dark)

	# Angular Motocross Tank, Slim Ribbed Seat & Fenders
	_box("BikeTank", Vector3(0.36, 0.32, 0.65), Vector3(0.0, 0.72, -0.18), _primary)
	_box("BikeSeat", Vector3(0.28, 0.14, 0.88), Vector3(0.0, 0.78, 0.42), _dark)
	_box("FrontFender", Vector3(0.26, 0.05, 0.62), Vector3(0.0, 0.74, -0.92), _primary)
	_box("RearFender", Vector3(0.28, 0.05, 0.58), Vector3(0.0, 0.78, 0.95), _primary)
	_box("FrontNumberPlate", Vector3(0.24, 0.22, 0.04), Vector3(0.0, 0.92, -0.72), _light)

	# Motocross Handlebars & Crossbar
	_cylinder("HandlebarStem", Vector3(0.0, 0.88, -0.65), Vector3(0.0, 1.05, -0.65), 0.04, _metal)
	_cylinder("HandlebarBar", Vector3(-0.45, 1.05, -0.65), Vector3(0.45, 1.05, -0.65), 0.038, _metal)
	_box("HandlebarPad", Vector3(0.2, 0.08, 0.08), Vector3(0.0, 1.05, -0.65), _primary)

	# Looping Exhaust Pipe to Side Aluminum Muffler
	_cylinder("ExhaustPipe", Vector3(0.16, 0.38, 0.35), Vector3(0.18, 0.58, 0.82), 0.048, _chrome)
	_cylinder("ExhaustMuffler", Vector3(0.18, 0.58, 0.82), Vector3(0.18, 0.64, 1.25), 0.075, _chrome)

	# Dynamic Motocross Human Rider Seated & Gripping Handlebars
	_build_human_driver(Vector3(0.0, 0.62, 0.25), true, accent)


# ==============================================================================
# 7. QUAD RUNNER (Sport ATV 4-Wheeler) - Matches Reference 2
# ==============================================================================
func _build_quad_runner(accent: Color) -> void:
	# Wide Low-Slung ATV Steel Frame
	_box("QuadChassis", Vector3(0.72, 0.25, 2.2), Vector3(0.0, 0.28, 0.0), _dark)
	_box("QuadEngine", Vector3(0.55, 0.38, 0.55), Vector3(0.0, 0.38, 0.15), _metal)

	# Wide Double A-Arm Front Suspension
	for x in [-0.55, 0.55]:
		_cylinder("FrontAArmTop_%d" % int(x*10), Vector3(0.0, 0.32, -0.95), Vector3(x, 0.15, -1.05), 0.045, _metal)
		_cylinder("FrontAArmBot_%d" % int(x*10), Vector3(0.0, 0.12, -0.95), Vector3(x, 0.02, -1.05), 0.045, _metal)
		_cylinder("FrontShock_%d" % int(x*10), Vector3(0.0, 0.52, -0.95), Vector3(x * 0.7, 0.08, -1.05), 0.055, _primary)

	# Front Pre-Runner Bumper / Brush Guard
	_cylinder("FrontGuardBar", Vector3(-0.45, 0.42, -1.45), Vector3(0.45, 0.42, -1.45), 0.05, _metal)
	_cylinder("FrontGuardL", Vector3(-0.45, 0.42, -1.45), Vector3(-0.25, 0.18, -1.35), 0.045, _metal)
	_cylinder("FrontGuardR", Vector3(0.45, 0.42, -1.45), Vector3(0.25, 0.18, -1.35), 0.045, _metal)

	# Sport Bodywork, Fenders & Tank
	_box("QuadNose", Vector3(0.85, 0.25, 0.65), Vector3(0.0, 0.62, -0.75), _primary)
	_box("QuadTank", Vector3(0.52, 0.28, 0.58), Vector3(0.0, 0.68, -0.15), _primary)
	_box("QuadSeat", Vector3(0.44, 0.16, 0.85), Vector3(0.0, 0.72, 0.38), _dark)

	# Wide Flared Sport Fenders (Front & Rear)
	for x in [-0.72, 0.72]:
		_box("FrontFender_%d" % int(x*10), Vector3(0.34, 0.08, 0.75), Vector3(x, 0.58, -0.95), _primary)
		_box("RearFender_%d" % int(x*10), Vector3(0.36, 0.08, 0.85), Vector3(x, 0.62, 0.85), _primary)

	# Dual Angular Headlights
	_sphere("QuadHeadlightL", Vector3(0.28, 0.66, -1.05), 0.11, _light)
	_sphere("QuadHeadlightR", Vector3(-0.28, 0.66, -1.05), 0.11, _light)

	# Raised Sport Handlebar
	_cylinder("QuadHandlebarStem", Vector3(0.0, 0.72, -0.55), Vector3(0.0, 1.02, -0.55), 0.045, _metal)
	_cylinder("QuadHandlebarBar", Vector3(-0.48, 1.02, -0.55), Vector3(0.48, 1.02, -0.55), 0.04, _metal)

	# Rear Sport Grab Bar
	_cylinder("RearGrabBar", Vector3(-0.35, 0.68, 1.25), Vector3(0.35, 0.68, 1.25), 0.045, _metal)

	# Active Human Rider Seated & Gripping Handlebars
	_build_human_driver(Vector3(0.0, 0.56, 0.22), true, accent)


# ==============================================================================
# HUMAN DRIVER BUILDER (Detailed Human Model with Racing Gear)
# ==============================================================================
func _build_human_driver(seat_pos: Vector3, is_biker: bool, accent: Color) -> void:
	var driver_node := Node3D.new()
	driver_node.name = "HumanDriver"
	driver_node.position = seat_pos
	_vehicle_root.add_child(driver_node)

	# 1. Torso & Racing Suit
	var torso_size := Vector3(0.42, 0.54, 0.32)
	var torso_pos := Vector3(0.0, 0.38, 0.0)
	if is_biker:
		# Biker leans aggressively forward in attack posture
		torso_pos = Vector3(0.0, 0.38, -0.08)
	_box_child(driver_node, "DriverTorso", torso_size, torso_pos, _suit)

	# Racing Harness Straps over Shoulders
	_box_child(driver_node, "HarnessL", Vector3(0.08, 0.48, 0.34), torso_pos + Vector3(0.11, 0.0, 0.0), _harness)
	_box_child(driver_node, "HarnessR", Vector3(0.08, 0.48, 0.34), torso_pos + Vector3(-0.11, 0.0, 0.0), _harness)

	# 2. Detailed Racing Helmet
	var head_pos := torso_pos + Vector3(0.0, 0.42, -0.06 if is_biker else -0.02)
	var head_node := Node3D.new()
	head_node.name = "DriverHead"
	head_node.position = head_pos
	driver_node.add_child(head_node)
	_driver_head = head_node

	_sphere_child(head_node, "HelmetShell", Vector3.ZERO, 0.22, _primary)
	_sphere_child(head_node, "HelmetVisor", Vector3(0.0, 0.01, -0.13), 0.16, _glass)
	_box_child(head_node, "HelmetChin", Vector3(0.24, 0.11, 0.14), Vector3(0.0, -0.1, -0.13), _dark)
	if is_biker:
		_box_child(head_node, "MotoPeak", Vector3(0.26, 0.04, 0.22), Vector3(0.0, 0.14, -0.16), _primary)

	# 3. Arms & Hands Gripping Wheel or Handlebars
	if is_biker:
		# Biker arms reaching forward-down to handlebars
		var hand_l := Vector3(0.38, 0.44, -0.65)
		var hand_r := Vector3(-0.38, 0.44, -0.65)
		var shoulder_l := torso_pos + Vector3(0.22, 0.18, -0.05)
		var shoulder_r := torso_pos + Vector3(-0.22, 0.18, -0.05)
		_cylinder_child(driver_node, "ArmL", shoulder_l, hand_l, 0.065, _suit)
		_cylinder_child(driver_node, "ArmR", shoulder_r, hand_r, 0.065, _suit)
		_sphere_child(driver_node, "GloveL", hand_l, 0.08, _harness)
		_sphere_child(driver_node, "GloveR", hand_r, 0.08, _harness)

		# Biker Legs & Boots
		_box_child(driver_node, "ThighL", Vector3(0.16, 0.18, 0.42), Vector3(0.22, 0.08, 0.05), _suit)
		_box_child(driver_node, "ThighR", Vector3(0.16, 0.18, 0.42), Vector3(-0.22, 0.08, 0.05), _suit)
		_box_child(driver_node, "BootL", Vector3(0.14, 0.24, 0.24), Vector3(0.24, -0.15, 0.22), _dark)
		_box_child(driver_node, "BootR", Vector3(0.14, 0.24, 0.24), Vector3(-0.24, -0.15, 0.22), _dark)
	else:
		# Car driver gripping steering wheel
		var wheel_center := torso_pos + Vector3(0.0, 0.05, -0.52)
		var hand_l := wheel_center + Vector3(0.14, 0.04, 0.0)
		var hand_r := wheel_center + Vector3(-0.14, 0.04, 0.0)
		var shoulder_l := torso_pos + Vector3(0.22, 0.18, 0.0)
		var shoulder_r := torso_pos + Vector3(-0.22, 0.18, 0.0)
		_cylinder_child(driver_node, "ArmL", shoulder_l, hand_l, 0.065, _suit)
		_cylinder_child(driver_node, "ArmR", shoulder_r, hand_r, 0.065, _suit)
		_sphere_child(driver_node, "GloveL", hand_l, 0.075, _harness)
		_sphere_child(driver_node, "GloveR", hand_r, 0.075, _harness)

		# 3-Spoke Sport Steering Wheel
		_torus_child(driver_node, "SteeringWheelRim", wheel_center, 0.19, _dark)
		_cylinder_child(driver_node, "SteeringCol", wheel_center, wheel_center + Vector3(0.0, -0.22, 0.25), 0.04, _metal)
		_sphere_child(driver_node, "SteeringHub", wheel_center, 0.055, _primary)


func _build_bucket_seat(pos: Vector3, accent: Material) -> void:
	# Contoured Racing Seat Back with Bolsters
	_box("SeatBack", Vector3(0.46, 0.72, 0.16), pos + Vector3(0.0, 0.42, 0.18), _dark)
	_box("SeatBolsterL", Vector3(0.1, 0.65, 0.24), pos + Vector3(0.24, 0.42, 0.12), _primary)
	_box("SeatBolsterR", Vector3(0.1, 0.65, 0.24), pos + Vector3(-0.24, 0.42, 0.12), _primary)
	_box("SeatBase", Vector3(0.48, 0.14, 0.52), pos + Vector3(0.0, 0.08, -0.06), _dark)
	_box("HeadRest", Vector3(0.36, 0.22, 0.14), pos + Vector3(0.0, 0.82, 0.22), _primary)


# ==============================================================================
# PROCEDURAL MESH BUILDERS & NON-DEGENERATE CYLINDER MATH
# ==============================================================================
func _box(node_name: String, mesh_size: Vector3, pos: Vector3, material: Material) -> void:
	_box_child(_vehicle_root, node_name, mesh_size, pos, material)


func _box_child(parent: Node3D, node_name: String, mesh_size: Vector3, pos: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = mesh_size
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = pos
	parent.add_child(visual)


func _sphere(node_name: String, pos: Vector3, radius: float, material: Material) -> void:
	_sphere_child(_vehicle_root, node_name, pos, radius, material)


func _sphere_child(parent: Node3D, node_name: String, pos: Vector3, radius: float, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = pos
	parent.add_child(visual)


func _torus_child(parent: Node3D, node_name: String, pos: Vector3, radius: float, material: Material) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.72
	mesh.outer_radius = radius
	mesh.rings = 14
	mesh.ring_segments = 8
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = pos
	visual.rotation.x = PI * 0.5
	parent.add_child(visual)


func _cylinder(node_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	_cylinder_child(_vehicle_root, node_name, start, end, radius, material)


func _cylinder_child(parent: Node3D, node_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var visual := Node3D.new()
	visual.name = node_name
	parent.add_child(visual)
	_set_segment(visual, start, end, radius, material)


func _set_segment(node: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var delta := end - start
	var length := delta.length()
	if length < 0.001:
		return

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
	else:
		mesh_visual.material_override = material

	# Stable, robust non-degenerate orientation pointing from start to end
	node.position = (start + end) * 0.5
	var dir := delta / length
	var up := Vector3.FORWARD if absf(dir.y) > 0.92 else Vector3.UP
	var right := dir.cross(up).normalized()
	var forward := right.cross(dir).normalized()
	node.basis = Basis(right * radius, dir * length, forward * radius)


# ==============================================================================
# WHEELS & VISUAL UPDATE
# ==============================================================================
func _build_wheels() -> void:
	for wheel_name in _wheel_names:
		var wheel := get_parent().get_node_or_null(wheel_name) as Node3D
		if wheel == null:
			continue
		var old_tire := wheel.get_node_or_null("TireMesh") as MeshInstance3D
		var old_rim := wheel.get_node_or_null("RimMesh") as MeshInstance3D
		if old_tire:
			old_tire.visible = false
		if old_rim:
			old_rim.visible = false

		# Modern Chunky Offroad Tire
		var tire := MeshInstance3D.new()
		tire.name = "ChunkyTire"
		var tire_mesh := CylinderMesh.new()
		tire_mesh.top_radius = 0.48
		tire_mesh.bottom_radius = 0.48
		tire_mesh.height = 0.36
		tire_mesh.radial_segments = 24
		tire.mesh = tire_mesh
		tire.material_override = _rubber
		tire.rotation_degrees.z = 90.0
		wheel.add_child(tire)

		# Metallic Beadlock Rim
		var rim := MeshInstance3D.new()
		rim.name = "AlloyRim"
		var rim_mesh := CylinderMesh.new()
		rim_mesh.top_radius = 0.28
		rim_mesh.bottom_radius = 0.28
		rim_mesh.height = 0.38
		rim_mesh.radial_segments = 16
		rim.mesh = rim_mesh
		rim.material_override = _metal
		rim.rotation_degrees.z = 90.0
		wheel.add_child(rim)

		# Disc Brake
		var brake_disc := MeshInstance3D.new()
		brake_disc.name = "BrakeDisc"
		var disc_mesh := CylinderMesh.new()
		disc_mesh.top_radius = 0.2
		disc_mesh.bottom_radius = 0.2
		disc_mesh.height = 0.04
		disc_mesh.radial_segments = 16
		brake_disc.mesh = disc_mesh
		brake_disc.material_override = _chrome
		brake_disc.rotation_degrees.z = 90.0
		brake_disc.position.x = -0.19 if wheel_name.contains("Far") else 0.19
		wheel.add_child(brake_disc)

		# 5-Spoke Sport Rim Face
		for i in range(5):
			var spoke := MeshInstance3D.new()
			var spoke_mesh := BoxMesh.new()
			spoke_mesh.size = Vector3(0.08, 0.065, 0.28)
			spoke.mesh = spoke_mesh
			spoke.material_override = _primary
			spoke.position.x = -0.205 if wheel_name.contains("Far") else 0.205
			spoke.rotation_degrees = Vector3(0.0, 0.0, float(i) * 72.0)
			wheel.add_child(spoke)

		# 14 Knobby Tread Lugs
		for t in range(14):
			var angle := TAU * float(t) / 14.0
			var lug := MeshInstance3D.new()
			lug.name = "TreadLug_%d" % t
			var lug_mesh := BoxMesh.new()
			lug_mesh.size = Vector3(0.38, 0.095, 0.16)
			lug.mesh = lug_mesh
			lug.material_override = _tread
			lug.position = Vector3(0.0, sin(angle) * 0.47, cos(angle) * 0.47)
			lug.rotation.x = angle
			wheel.add_child(lug)


func _build_suspension() -> void:
	for wheel_name in _wheel_names:
		var shock := Node3D.new()
		shock.name = "VisibleShock_" + wheel_name
		_visual_root.add_child(shock)
		_shock_roots.append(shock)


func _update_shocks() -> void:
	var anchors := [
		Vector3(NEAR_X, -0.1, 1.05), Vector3(FAR_X, -0.1, 1.05),
		Vector3(NEAR_X, -0.1, -1.05), Vector3(FAR_X, -0.1, -1.05)
	]
	for index in range(_shock_roots.size()):
		var wheel := get_parent().get_node_or_null(_wheel_names[index]) as Node3D
		if wheel == null or not wheel.visible:
			_shock_roots[index].visible = false
			continue
		_shock_roots[index].visible = true
		var target := wheel.position + Vector3(0.0, 0.1, 0.0)
		_set_segment(_shock_roots[index], anchors[index], target, 0.055, _spring)


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
		var vibration := sin(_visual_time * 42.0) * controller.throttle_input * 0.007
		var target_bounce := -average_compression * 0.045 + vibration
		_body_bounce = lerpf(_body_bounce, target_bounce, 1.0 - exp(-14.0 * delta))
		_visual_root.position.y = _body_bounce

		# Dynamic Chassis Pitch: Squat on acceleration, dive on braking, suspension tilt
		var rear_comp: float = float(controller._wheels[0]["compression"])
		var front_comp: float = float(controller._wheels[1]["compression"])
		var accel_pitch := -controller.throttle_input * 0.05
		var brake_pitch := controller.brake_input * 0.075
		var susp_pitch := (rear_comp - front_comp) * 0.09
		var target_pitch := accel_pitch + brake_pitch + susp_pitch
		_body_pitch = lerpf(_body_pitch, target_pitch, 1.0 - exp(-15.0 * delta))
		_visual_root.rotation.x = _body_pitch

		# Dynamic Driver Head bobbing & G-force reactions
		if is_instance_valid(_driver_head):
			var target_head_x := -controller.throttle_input * 0.16 + controller.brake_input * 0.22
			_driver_head.rotation.x = lerpf(_driver_head.rotation.x, target_head_x, 1.0 - exp(-18.0 * delta))
			_driver_head.position.y = sin(_visual_time * 26.0) * (controller.throttle_input * 0.012)

		# Dust particles
		var fwd_speed := controller.linear_velocity.dot(-controller.global_transform.basis.z)
		var emit_dust: bool = fwd_speed > 1.2 and controller._wheels[0]["in_contact"] and controller.throttle_input > 0.05
		for emitter in _dust_emitters:
			emitter.emitting = emit_dust
	_update_shocks()


func _build_dust_emitters() -> void:
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.55, 0.42, 0.28, 0.65)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var part_mat := ParticleProcessMaterial.new()
	part_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	part_mat.emission_box_extents = Vector3(0.25, 0.05, 0.15)
	part_mat.direction = Vector3(0.0, 0.5, 0.5)
	part_mat.spread = 35.0
	part_mat.initial_velocity_min = 0.8
	part_mat.initial_velocity_max = 1.8
	part_mat.gravity = Vector3(0.0, -0.6, 0.0)
	part_mat.scale_min = 0.08
	part_mat.scale_max = 0.22

	var emitter := GPUParticles3D.new()
	emitter.name = "DustKickEmitter"
	emitter.position = Vector3(0.0, -0.28, 1.05)
	emitter.amount = 24
	emitter.lifetime = 0.65
	emitter.randomness = 0.8
	emitter.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 3, 4))
	emitter.process_material = part_mat
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.2, 0.2)
	mesh.material = dust_mat
	emitter.draw_pass_1 = mesh
	_visual_root.add_child(emitter)
	_dust_emitters.append(emitter)


func _hide_placeholder_visuals() -> void:
	for node_name in [
		"ChassisVisual", "CabinVisual", "UnderbodyVisual", "RoofVisual",
		"FrontBumperVisual", "RearBumperVisual", "RearSuspensionNear",
		"RearSuspensionFar", "FrontSuspensionNear", "FrontSuspensionFar",
		"RearContactDebug", "FrontContactDebug",
	]:
		var visual := get_parent().get_node_or_null(node_name) as Node3D
		if visual:
			visual.visible = false


func _create_materials() -> void:
	_primary = _material(Color(1.0, 0.52, 0.08), 0.32, 0.25)
	_secondary = _material(Color(0.18, 0.22, 0.26), 0.5, 0.1)
	_dark = _material(Color(0.06, 0.07, 0.09), 0.7, 0.0)
	_rubber = _material(Color(0.03, 0.032, 0.035), 0.95, 0.0)
	_metal = _material(Color(0.35, 0.40, 0.45), 0.28, 0.75)
	_chrome = _material(Color(0.85, 0.88, 0.92), 0.15, 0.92)
	_glass = _material(Color(0.06, 0.20, 0.32), 0.1, 0.2)
	_light = _material(Color(1.0, 0.92, 0.55), 0.1, 0.0)
	_light.emission_enabled = true
	_light.emission = Color(1.0, 0.85, 0.45)
	_brake_light = _material(Color(0.9, 0.1, 0.08), 0.1, 0.0)
	_brake_light.emission_enabled = true
	_brake_light.emission = Color(0.95, 0.12, 0.08)
	_spring = _material(Color(1.0, 0.52, 0.08), 0.38, 0.2)
	_tread = _material(Color(0.02, 0.022, 0.025), 0.98, 0.0)
	_suit = _material(Color(0.08, 0.11, 0.15), 0.7, 0.0)
	_skin = _material(Color(0.55, 0.30, 0.18), 0.9, 0.0)
	_harness = _material(Color(0.92, 0.18, 0.08), 0.55, 0.0)
	_nitro_mat = StandardMaterial3D.new()
	_nitro_mat.albedo_color = Color(0.25, 0.85, 1.0)
	_nitro_mat.emission_enabled = true
	_nitro_mat.emission = Color(0.2, 0.9, 1.0)
	_nitro_mat.emission_energy_multiplier = 4.0


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat
