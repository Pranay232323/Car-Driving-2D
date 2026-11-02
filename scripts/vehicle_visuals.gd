extends Node3D
class_name VehicleVisuals

const NEAR_X := 0.88
const FAR_X := -0.88

var _primary: StandardMaterial3D
var _primary_dark: StandardMaterial3D
var _secondary: StandardMaterial3D
var _dark: StandardMaterial3D
var _carbon: StandardMaterial3D
var _rubber: StandardMaterial3D
var _metal: StandardMaterial3D
var _chrome: StandardMaterial3D
var _gold_metal: StandardMaterial3D
var _glass: StandardMaterial3D
var _light: StandardMaterial3D
var _amber_light: StandardMaterial3D
var _brake_light: StandardMaterial3D
var _spring: StandardMaterial3D
var _tread: StandardMaterial3D
var _suit: StandardMaterial3D
var _skin: StandardMaterial3D
var _harness: StandardMaterial3D
var _white_decal: StandardMaterial3D
var _nitro_mat: StandardMaterial3D

var _visual_root: Node3D
var _vehicle_root: Node3D
var _variant_name := "Buggy"
var _shock_roots: Array[Node3D] = []
var _wheel_names := ["RearWheelNear", "RearWheelFar", "FrontWheelNear", "FrontWheelFar"]
var _visual_time := 0.0
var _body_bounce := 0.0
var _body_pitch := 0.0
var _driver_head: Node3D = null
var _driver_head_base_pos := Vector3.ZERO
var _exhaust_flame: MeshInstance3D = null
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
	set_vehicle_variant("Buggy", Color(1.0, 0.65, 0.05))


func set_vehicle_variant(variant_name: String, accent_color: Color) -> void:
	_variant_name = variant_name
	_primary.albedo_color = accent_color
	_primary_dark.albedo_color = accent_color.darkened(0.38)
	_spring.albedo_color = accent_color.lightened(0.1)
	_driver_head = null

	# Clear previous custom vehicle parts
	for child in _vehicle_root.get_children():
		child.queue_free()

	# Build modern sculpted 3D vehicle based on selected variant
	match variant_name:
		"Buggy", "Racing Buggy":
			_build_buggy(accent_color)
		"Monster Truck":
			_build_monster_truck(accent_color)
		"Jeep":
			_build_jeep(accent_color)
		"Truck":
			_build_truck(accent_color)
		"Sport SUV":
			_build_sport_suv(accent_color)
		"Trail Bike", "Dirt Bike":
			_build_trail_bike(accent_color)
		"Quad Runner", "Quad":
			_build_quad_runner(accent_color)
		_:
			_build_buggy(accent_color)

	_set_wheel_style(variant_name)


func _set_wheel_style(variant_name: String) -> void:
	var wheel_scale := Vector3.ONE
	var is_bike := variant_name in ["Trail Bike", "Dirt Bike"]
	match variant_name:
		"Monster Truck":
			wheel_scale = Vector3(1.55, 1.44, 1.44)
		"Trail Bike", "Dirt Bike":
			wheel_scale = Vector3(0.42, 0.96, 0.96)
		"Quad Runner", "Quad":
			wheel_scale = Vector3(0.95, 0.88, 0.88)
		"Jeep", "Truck":
			wheel_scale = Vector3(1.12, 1.08, 1.08)
		"Sport SUV":
			wheel_scale = Vector3(1.05, 1.0, 1.0)
		_:
			wheel_scale = Vector3(1.05, 1.02, 1.02)

	for wheel_name: String in _wheel_names:
		var wheel := get_parent().get_node_or_null(wheel_name) as Node3D
		if wheel:
			wheel.scale = wheel_scale
			wheel.visible = not is_bike or wheel_name.ends_with("Near")


# ==============================================================================
# 1. BUGGY (Can-Am Maverick X3 / Desert Sand Rail - Reference 1 Top-Left)
# ==============================================================================
func _build_buggy(accent: Color) -> void:
	# Sculpted boat-tail lower belly pan & rock sliders
	_box("ChassisBelly", Vector3(1.12, 0.12, 2.25), Vector3(0.0, -0.04, 0.0), _dark)
	_box("FrontSkidPlate", Vector3(0.76, 0.08, 0.68), Vector3(0.0, 0.04, -1.28), _metal, Vector3(18.0, 0.0, 0.0))
	_box("RearDiffSkid", Vector3(0.82, 0.1, 0.55), Vector3(0.0, 0.02, 1.18), _metal, Vector3(-14.0, 0.0, 0.0))

	# Exposed Front & Rear Double A-Arms + Shock Towers
	for side: float in [-1.0, 1.0]:
		var sx := side * 0.34
		var wx := side * 0.78
		# Front A-arms
		_cylinder("FrontUpperArm_%d" % int(side), Vector3(sx, 0.22, -1.18), Vector3(wx, 0.06, -1.08), 0.032, _dark)
		_cylinder("FrontLowerArm_%d" % int(side), Vector3(sx, 0.04, -1.18), Vector3(wx, -0.10, -1.08), 0.036, _dark)
		# Rear Trailing Arms
		_cylinder("RearTrailingArm_%d" % int(side), Vector3(sx * 1.1, 0.06, 0.35), Vector3(wx, -0.06, 1.05), 0.045, _primary)
		_cylinder("RearUpperLink_%d" % int(side), Vector3(sx, 0.28, 0.92), Vector3(wx * 0.9, 0.05, 1.05), 0.032, _metal)
		# Heavy Rock Slider Tubes
		_cylinder("RockSlider_%d" % int(side), Vector3(side * 0.72, 0.0, -0.68), Vector3(side * 0.72, 0.0, 0.68), 0.042, _dark)

	# Front Shock Tower Hoop
	_cylinder("ShockTowerL", Vector3(-0.34, 0.18, -1.12), Vector3(-0.26, 0.64, -1.02), 0.04, _dark)
	_cylinder("ShockTowerR", Vector3(0.34, 0.18, -1.12), Vector3(0.26, 0.64, -1.02), 0.04, _dark)
	_cylinder("ShockTowerCross", Vector3(-0.26, 0.64, -1.02), Vector3(0.26, 0.64, -1.02), 0.04, _primary)

	# Aggressive Sloped Shark-Nose Hood & Front Fascia
	_box("HoodMain", Vector3(0.92, 0.12, 0.78), Vector3(0.0, 0.48, -0.82), _primary, Vector3(14.0, 0.0, 0.0))
	_box("HoodScoop", Vector3(0.42, 0.09, 0.48), Vector3(0.0, 0.55, -0.76), _carbon, Vector3(12.0, 0.0, 0.0))
	_box("NoseCone", Vector3(0.76, 0.14, 0.45), Vector3(0.0, 0.34, -1.32), _primary, Vector3(24.0, 0.0, 0.0))
	_box("FrontGrille", Vector3(0.68, 0.18, 0.12), Vector3(0.0, 0.28, -1.52), _carbon, Vector3(10.0, 0.0, 0.0))

	# Recessed Angry-Eye LED Headlights (Flush in fascia, NOT bug-eye spheres)
	for side: float in [-1.0, 1.0]:
		_box("HeadlightHousing_%d" % int(side), Vector3(0.24, 0.10, 0.12), Vector3(side * 0.28, 0.36, -1.48), _dark, Vector3(12.0, side * -12.0, side * -8.0))
		_box("HeadlightLED_%d" % int(side), Vector3(0.20, 0.045, 0.04), Vector3(side * 0.28, 0.37, -1.54), _light, Vector3(12.0, side * -12.0, side * -8.0))

	# Pre-Runner Tubular Stinger Bumper
	_cylinder("BumperBase", Vector3(-0.46, 0.14, -1.58), Vector3(0.46, 0.14, -1.58), 0.042, _dark)
	_cylinder("StingerL", Vector3(-0.32, 0.14, -1.58), Vector3(-0.18, 0.44, -1.68), 0.038, _dark)
	_cylinder("StingerR", Vector3(0.32, 0.14, -1.58), Vector3(0.18, 0.44, -1.68), 0.038, _dark)
	_cylinder("StingerTop", Vector3(-0.18, 0.44, -1.68), Vector3(0.18, 0.44, -1.68), 0.038, _dark)

	# Sculpted Side Doors, Livery Panels & High Front/Rear Fender Wings
	for side: float in [-1.0, 1.0]:
		var dx := side * 0.68
		# Main sculpted door panel (angled beltline)
		_box("DoorUpper_%d" % int(side), Vector3(0.08, 0.30, 1.18), Vector3(dx, 0.34, -0.05), _primary, Vector3(4.0, 0.0, side * -6.0))
		_box("DoorLower_%d" % int(side), Vector3(0.09, 0.18, 1.08), Vector3(dx, 0.12, -0.02), _carbon)
		# Black & White Number Plate Graphic ("#01" style panel from Reference 1)
		_box("DoorGraphicDark_%d" % int(side), Vector3(0.095, 0.20, 0.56), Vector3(dx + side * 0.005, 0.32, -0.10), _dark, Vector3(8.0, 0.0, 0.0))
		_box("DoorStripe_%d" % int(side), Vector3(0.10, 0.05, 0.62), Vector3(dx + side * 0.008, 0.42, -0.08), _white_decal, Vector3(8.0, 0.0, 0.0))
		# Rear Quarter Side Pod & Side Air Scoop
		_box("RearQuarter_%d" % int(side), Vector3(0.12, 0.28, 0.68), Vector3(side * 0.62, 0.44, 0.72), _primary, Vector3(-10.0, side * 6.0, 0.0))
		_box("SideAirIntake_%d" % int(side), Vector3(0.14, 0.22, 0.22), Vector3(side * 0.63, 0.45, 0.48), _carbon, Vector3(-14.0, 0.0, 0.0))
		# High Open-Wheel Fender Wings
		_box("FrontFenderWing_%d" % int(side), Vector3(0.24, 0.05, 0.52), Vector3(side * 0.56, 0.50, -0.88), _carbon, Vector3(16.0, side * -8.0, 0.0))
		_box("RearFenderWing_%d" % int(side), Vector3(0.26, 0.05, 0.58), Vector3(side * 0.58, 0.54, 0.92), _carbon, Vector3(-14.0, side * 6.0, 0.0))

	# Full Triangulated Fastback Roll Cage (Matches Reference 1 & 2)
	var roof_h := 1.18
	for side: float in [-1.0, 1.0]:
		var cx := side * 0.52
		var rx := side * 0.45
		# Raked A-Pillar
		_cylinder("CageAPillar_%d" % int(side), Vector3(cx, 0.50, -0.58), Vector3(rx, roof_h, -0.08), 0.042, _primary)
		# Curved Roof Rail
		_cylinder("CageRoof_%d" % int(side), Vector3(rx, roof_h, -0.08), Vector3(rx, roof_h - 0.04, 0.55), 0.042, _primary)
		# B-Pillar (behind seats)
		_cylinder("CageBPillar_%d" % int(side), Vector3(cx, 0.42, 0.42), Vector3(rx, roof_h - 0.04, 0.55), 0.042, _dark)
		# Fastback C-Pillar (sweeping to rear bumper)
		_cylinder("CageCPillar_%d" % int(side), Vector3(rx, roof_h - 0.04, 0.55), Vector3(cx * 0.95, 0.36, 1.38), 0.042, _primary)
		# Side Door Shoulder Bar & Diagonal Gusset
		_cylinder("CageDoorBar_%d" % int(side), Vector3(cx, 0.50, -0.58), Vector3(cx, 0.46, 0.42), 0.036, _dark)
		_cylinder("CageDiag_%d" % int(side), Vector3(cx, 0.46, 0.42), Vector3(cx * 0.95, 0.36, 1.38), 0.034, _dark)

	# Roll Cage Crossbars & Aluminum Roof Panel
	_cylinder("CageCrossFront", Vector3(-0.45, roof_h, -0.08), Vector3(0.45, roof_h, -0.08), 0.04, _dark)
	_cylinder("CageCrossMid", Vector3(-0.45, roof_h - 0.04, 0.55), Vector3(0.45, roof_h - 0.04, 0.55), 0.04, _dark)
	_cylinder("CageCrossRear", Vector3(-0.48, 0.36, 1.38), Vector3(0.48, 0.36, 1.38), 0.04, _dark)
	_box("RoofVisorPanel", Vector3(0.88, 0.035, 0.65), Vector3(0.0, roof_h + 0.01, 0.23), _carbon, Vector3(-3.5, 0.0, 0.0))

	# Roof-Mounted 4-Pod Off-Road Spotlight Bar
	_build_spotlight_bar(Vector3(0.0, roof_h + 0.09, -0.08), 0.78, 4)

	# Rear Twin-Turbo Engine, Intercooler & Dual Exhausts
	_box("EngineBlock", Vector3(0.64, 0.36, 0.54), Vector3(0.0, 0.30, 0.88), _metal)
	_box("Intercooler", Vector3(0.58, 0.28, 0.14), Vector3(0.0, 0.64, 0.76), _chrome, Vector3(-28.0, 0.0, 0.0))
	_cylinder("IntakePipeL", Vector3(-0.22, 0.42, 0.88), Vector3(-0.18, 0.64, 0.76), 0.045, _primary)
	_cylinder("IntakePipeR", Vector3(0.22, 0.42, 0.88), Vector3(0.18, 0.64, 0.76), 0.045, _primary)
	_tapered_cylinder("MufflerL", Vector3(-0.18, 0.36, 1.05), Vector3(-0.20, 0.40, 1.48), 0.065, 0.055, _chrome)
	_tapered_cylinder("MufflerR", Vector3(0.18, 0.36, 1.05), Vector3(0.20, 0.40, 1.48), 0.065, 0.055, _chrome)
	_box("RearTaillightL", Vector3(0.18, 0.05, 0.05), Vector3(-0.34, 0.42, 1.40), _brake_light)
	_box("RearTaillightR", Vector3(0.18, 0.05, 0.05), Vector3(0.34, 0.42, 1.40), _brake_light)

	# Cockpit, Seats & Driver
	_build_bucket_seat(Vector3(0.26, 0.08, 0.05))
	_build_bucket_seat(Vector3(-0.26, 0.08, 0.05))
	_build_human_driver(Vector3(0.26, 0.10, 0.05), false, accent)


# ==============================================================================
# 2. MONSTER TRUCK (Lifted Trophy Pickup - Reference 1 Top-Center)
# ==============================================================================
func _build_monster_truck(accent: Color) -> void:
	# Tubular Monster Cradle Chassis & Heavy Axles (Replaces the flat Lego slab!)
	_box("TransferCase", Vector3(0.54, 0.34, 0.62), Vector3(0.0, 0.28, 0.0), _metal)
	for side: float in [-1.0, 1.0]:
		var fx := side * 0.46
		# Main Upper & Lower Tubular Cradle Rails
		_cylinder("CradleUpper_%d" % int(side), Vector3(fx, 0.62, -1.25), Vector3(fx, 0.62, 1.25), 0.055, _dark)
		_cylinder("CradleLower_%d" % int(side), Vector3(fx * 0.85, 0.32, -0.82), Vector3(fx * 0.85, 0.32, 0.82), 0.05, _dark)
		_cylinder("CradleFrontUp_%d" % int(side), Vector3(fx * 0.85, 0.32, -0.82), Vector3(fx, 0.62, -1.25), 0.048, _dark)
		_cylinder("CradleRearUp_%d" % int(side), Vector3(fx * 0.85, 0.32, 0.82), Vector3(fx, 0.62, 1.25), 0.048, _dark)
		# Truss Diagonal Braces
		_cylinder("TrussBraceF_%d" % int(side), Vector3(fx * 0.85, 0.32, 0.0), Vector3(fx, 0.62, -0.75), 0.04, _primary)
		_cylinder("TrussBraceR_%d" % int(side), Vector3(fx * 0.85, 0.32, 0.0), Vector3(fx, 0.62, 0.75), 0.04, _primary)

		# 4-Link Suspension Bars extending to Front & Rear Axles
		_cylinder("FourLinkFL_%d" % int(side), Vector3(fx * 0.8, 0.28, -0.25), Vector3(fx * 1.1, -0.12, -1.05), 0.042, _chrome)
		_cylinder("FourLinkFU_%d" % int(side), Vector3(fx * 0.8, 0.42, -0.30), Vector3(fx * 0.95, 0.02, -1.05), 0.036, _primary)
		_cylinder("FourLinkRL_%d" % int(side), Vector3(fx * 0.8, 0.28, 0.25), Vector3(fx * 1.1, -0.12, 1.05), 0.042, _chrome)
		_cylinder("FourLinkRU_%d" % int(side), Vector3(fx * 0.8, 0.42, 0.30), Vector3(fx * 0.95, 0.02, 1.05), 0.036, _primary)

	# Heavy Solid Axles, Differential Pumpkins & Driveshafts
	_cylinder("FrontAxleTube", Vector3(-0.78, -0.15, -1.05), Vector3(0.78, -0.15, -1.05), 0.075, _dark)
	_cylinder("RearAxleTube", Vector3(-0.78, -0.15, 1.05), Vector3(0.78, -0.15, 1.05), 0.075, _dark)
	_sphere("FrontDiffPumpkin", Vector3(0.0, -0.15, -1.05), 0.16, _metal)
	_sphere("RearDiffPumpkin", Vector3(0.0, -0.15, 1.05), 0.16, _metal)
	_cylinder("DriveShaftF", Vector3(0.0, 0.24, -0.20), Vector3(0.0, -0.12, -1.02), 0.048, _chrome)
	_cylinder("DriveShaftR", Vector3(0.0, 0.24, 0.20), Vector3(0.0, -0.12, 1.02), 0.048, _chrome)

	# Sculpted Lifted Trophy Truck Body (Elevated at y = 0.72+)
	# 1. Sloped Muscular Hood & Power Dome
	_box("HoodMain", Vector3(1.38, 0.34, 0.92), Vector3(0.0, 0.92, -1.08), _primary, Vector3(5.0, 0.0, 0.0))
	_box("HoodPowerDome", Vector3(0.74, 0.10, 0.76), Vector3(0.0, 1.10, -1.02), _carbon, Vector3(6.5, 0.0, 0.0))

	# 2. Aggressive Chrome Grille, Rectangular Headlights & Bullbar Bumper
	_box("GrilleShell", Vector3(1.34, 0.32, 0.12), Vector3(0.0, 0.90, -1.54), _chrome, Vector3(4.0, 0.0, 0.0))
	_box("GrilleMesh", Vector3(0.86, 0.22, 0.13), Vector3(0.0, 0.90, -1.55), _dark, Vector3(4.0, 0.0, 0.0))
	_box("GrilleBar1", Vector3(0.84, 0.035, 0.14), Vector3(0.0, 0.94, -1.56), _chrome)
	_box("GrilleBar2", Vector3(0.84, 0.035, 0.14), Vector3(0.0, 0.86, -1.56), _chrome)
	for side: float in [-1.0, 1.0]:
		_box("HeadlightRect_%d" % int(side), Vector3(0.22, 0.14, 0.10), Vector3(side * 0.54, 0.94, -1.54), _light, Vector3(4.0, side * -6.0, 0.0))
		_box("AmberCorner_%d" % int(side), Vector3(0.08, 0.12, 0.12), Vector3(side * 0.66, 0.92, -1.50), _amber_light)

	_box("FrontBumper", Vector3(1.48, 0.18, 0.22), Vector3(0.0, 0.68, -1.60), _dark)
	_box("FrontSkid", Vector3(0.92, 0.12, 0.36), Vector3(0.0, 0.56, -1.50), _chrome, Vector3(22.0, 0.0, 0.0))
	_cylinder("BullBarL", Vector3(-0.38, 0.72, -1.66), Vector3(-0.32, 1.04, -1.62), 0.042, _dark)
	_cylinder("BullBarR", Vector3(0.38, 0.72, -1.66), Vector3(0.32, 1.04, -1.62), 0.042, _dark)
	_cylinder("BullBarTop", Vector3(-0.32, 1.04, -1.62), Vector3(0.32, 1.04, -1.62), 0.042, _dark)

	# 3. Sculpted Cab with Raked Windshield & Side Graphics
	_box("CabLower", Vector3(1.44, 0.42, 1.24), Vector3(0.0, 0.92, -0.05), _primary)
	_box("CabRoof", Vector3(1.26, 0.10, 0.96), Vector3(0.0, 1.54, 0.06), _primary, Vector3(-1.5, 0.0, 0.0))
	_box("Windshield", Vector3(1.22, 0.48, 0.06), Vector3(0.0, 1.32, -0.52), _glass, Vector3(-28.0, 0.0, 0.0))
	_box("RearCabGlass", Vector3(1.18, 0.38, 0.06), Vector3(0.0, 1.34, 0.54), _glass, Vector3(8.0, 0.0, 0.0))

	for side: float in [-1.0, 1.0]:
		var sx := side * 0.66
		# Raked A-Pillar & C-Pillar
		_cylinder("CabAPillar_%d" % int(side), Vector3(sx, 1.10, -0.64), Vector3(sx * 0.94, 1.54, -0.38), 0.045, _primary)
		_box("CabCPillar_%d" % int(side), Vector3(0.08, 0.44, 0.22), Vector3(sx * 0.96, 1.32, 0.44), _primary, Vector3(8.0, 0.0, side * 6.0))
		_box("CabBPillar_%d" % int(side), Vector3(0.06, 0.42, 0.10), Vector3(sx * 0.98, 1.32, 0.04), _dark)
		# Tinted Side Windows
		_box("SideGlassF_%d" % int(side), Vector3(0.05, 0.36, 0.46), Vector3(sx * 0.97, 1.32, -0.22), _glass, Vector3(0.0, 0.0, side * 5.0))
		_box("SideGlassR_%d" % int(side), Vector3(0.05, 0.36, 0.30), Vector3(sx * 0.97, 1.32, 0.22), _glass, Vector3(0.0, 0.0, side * 5.0))
		# Black & Graphic Side Cladding (Matches Reference 1 Monster Truck)
		_box("RockerCladding_%d" % int(side), Vector3(0.06, 0.14, 2.2), Vector3(side * 0.72, 0.74, 0.05), _dark)
		_box("GraphicStripe_%d" % int(side), Vector3(0.07, 0.08, 1.65), Vector3(side * 0.725, 0.94, -0.05), _carbon, Vector3(-3.0, 0.0, 0.0))
		# Polygonal Off-Road Fender Flares
		_wheel_arch("FrontArch_%d" % int(side), Vector3(side * 0.72, 0.68, -1.05), 0.48, 0.16, 0.09, _dark)
		_wheel_arch("RearArch_%d" % int(side), Vector3(side * 0.72, 0.68, 1.05), 0.48, 0.16, 0.09, _dark)

	# 4. Sculpted Pickup Bed, Chase Bar & 5 Roof Spotlights
	_box("TruckBedSides", Vector3(1.42, 0.38, 1.02), Vector3(0.0, 0.92, 1.06), _primary)
	_box("BedInterior", Vector3(1.24, 0.22, 0.92), Vector3(0.0, 0.96, 1.06), _dark)
	_box("Tailgate", Vector3(1.38, 0.36, 0.08), Vector3(0.0, 0.92, 1.54), _primary)
	_box("TaillightL", Vector3(0.10, 0.24, 0.06), Vector3(-0.66, 0.94, 1.56), _brake_light)
	_box("TaillightR", Vector3(0.10, 0.24, 0.06), Vector3(0.66, 0.94, 1.56), _brake_light)

	# Chrome Bed Roll Bar & 5-Pod Roof Spotlight Bar
	_cylinder("BedRollL", Vector3(-0.56, 1.05, 0.68), Vector3(-0.52, 1.52, 0.64), 0.048, _chrome)
	_cylinder("BedRollR", Vector3(0.56, 1.05, 0.68), Vector3(0.52, 1.52, 0.64), 0.048, _chrome)
	_cylinder("BedRollKickerL", Vector3(-0.52, 1.52, 0.64), Vector3(-0.56, 1.05, 1.32), 0.042, _chrome)
	_cylinder("BedRollKickerR", Vector3(0.52, 1.52, 0.64), Vector3(0.56, 1.05, 1.32), 0.042, _chrome)
	_build_spotlight_bar(Vector3(0.0, 1.62, -0.34), 0.96, 5)

	# Elevated Driver in Cab
	_build_human_driver(Vector3(0.32, 0.86, -0.05), false, accent)


# ==============================================================================
# 3. JEEP 4x4 OFFROADER (Wrangler Rubicon Unlimited - Reference 1 Top-Right)
# ==============================================================================
func _build_jeep(accent: Color) -> void:
	# Ladder Frame, Rock Sliders & Skid Plate
	_box("JeepFrame", Vector3(1.18, 0.18, 2.75), Vector3(0.0, 0.18, 0.0), _dark)
	_box("FrontSkid", Vector3(0.88, 0.12, 0.42), Vector3(0.0, 0.18, -1.44), _metal, Vector3(24.0, 0.0, 0.0))

	# Main Body Tub & Tapered Rubicon Hood
	_box("BodyTub", Vector3(1.38, 0.52, 1.78), Vector3(0.0, 0.56, 0.26), _primary)
	_box("JeepHood", Vector3(1.24, 0.36, 0.92), Vector3(0.0, 0.62, -1.02), _primary, Vector3(3.0, 0.0, 0.0))
	_box("HoodPowerBulge", Vector3(0.68, 0.06, 0.68), Vector3(0.0, 0.81, -0.96), _primary, Vector3(3.0, 0.0, 0.0))
	_box("HoodVent", Vector3(0.44, 0.04, 0.22), Vector3(0.0, 0.83, -0.82), _dark)

	# Iconic 7-Slot Jeep Grille & Flush Round Halo Headlights
	_box("GrilleFace", Vector3(1.18, 0.38, 0.10), Vector3(0.0, 0.60, -1.46), _primary)
	_box("GrilleBacking", Vector3(1.08, 0.32, 0.08), Vector3(0.0, 0.60, -1.45), _dark)
	for i in range(7):
		var sx := -0.30 + float(i) * 0.10
		_box("GrilleSlot_%d" % i, Vector3(0.045, 0.24, 0.11), Vector3(sx, 0.60, -1.46), _dark)

	for side: float in [-1.0, 1.0]:
		# Round recessed headlights with chrome/halo ring
		_cylinder("JeepHeadlight_%d" % int(side), Vector3(side * 0.44, 0.62, -1.44), Vector3(side * 0.44, 0.62, -1.52), 0.105, _light)
		_torus("JeepHalo_%d" % int(side), Vector3(side * 0.44, 0.62, -1.51), 0.11, _chrome)

	# Heavy Steel Rubicon Bumper with Winch & Bull Hoop
	_box("FrontBumper", Vector3(1.52, 0.18, 0.22), Vector3(0.0, 0.32, -1.58), _dark)
	_box("WinchBox", Vector3(0.42, 0.14, 0.18), Vector3(0.0, 0.42, -1.56), _metal)
	_cylinder("WinchHoopL", Vector3(-0.34, 0.40, -1.62), Vector3(-0.26, 0.68, -1.58), 0.036, _dark)
	_cylinder("WinchHoopR", Vector3(0.34, 0.40, -1.62), Vector3(0.26, 0.68, -1.58), 0.036, _dark)
	_cylinder("WinchHoopTop", Vector3(-0.26, 0.68, -1.58), Vector3(0.26, 0.68, -1.58), 0.036, _dark)
	_box("RearBumper", Vector3(1.48, 0.18, 0.20), Vector3(0.0, 0.32, 1.22), _dark)

	# Trapezoidal Flat-Top Black Fender Flares & Rock Rails (Signature Jeep Look)
	for side: float in [-1.0, 1.0]:
		_wheel_arch("JeepFrontFlare_%d" % int(side), Vector3(side * 0.70, 0.34, -1.04), 0.46, 0.22, 0.08, _dark)
		_wheel_arch("JeepRearFlare_%d" % int(side), Vector3(side * 0.70, 0.34, 0.94), 0.46, 0.20, 0.08, _dark)
		_box("FlareTurnSignal_%d" % int(side), Vector3(0.14, 0.04, 0.06), Vector3(side * 0.74, 0.62, -1.36), _amber_light)
		_box("RockRail_%d" % int(side), Vector3(0.12, 0.08, 1.15), Vector3(side * 0.72, 0.24, -0.05), _dark)
		# Door Handles & Hinges
		_box("DoorHandleF_%d" % int(side), Vector3(0.05, 0.04, 0.12), Vector3(side * 0.70, 0.72, -0.02), _dark)
		_box("DoorHandleR_%d" % int(side), Vector3(0.05, 0.04, 0.12), Vector3(side * 0.70, 0.72, 0.56), _dark)
		_box("SideMirror_%d" % int(side), Vector3(0.16, 0.12, 0.08), Vector3(side * 0.76, 0.88, -0.44), _dark)

	# 4-Door Hardtop Cabin with Raked Windshield & Divided Side Windows
	_box("RoofHardtop", Vector3(1.32, 0.08, 1.56), Vector3(0.0, 1.32, 0.34), _primary)
	_box("WindshieldFrame", Vector3(1.30, 0.50, 0.07), Vector3(0.0, 1.06, -0.48), _primary, Vector3(-16.0, 0.0, 0.0))
	_box("WindshieldGlass", Vector3(1.18, 0.40, 0.08), Vector3(0.0, 1.07, -0.49), _glass, Vector3(-16.0, 0.0, 0.0))
	_box("RearWindow", Vector3(1.16, 0.38, 0.06), Vector3(0.0, 1.06, 1.12), _glass)

	for side: float in [-1.0, 1.0]:
		var wx := side * 0.65
		# B, C, D Pillars & 3 Side Windows
		_box("PillarB_%d" % int(side), Vector3(0.06, 0.48, 0.10), Vector3(wx, 1.06, 0.06), _primary)
		_box("PillarC_%d" % int(side), Vector3(0.06, 0.48, 0.10), Vector3(wx, 1.06, 0.60), _primary)
		_box("PillarD_%d" % int(side), Vector3(0.07, 0.48, 0.14), Vector3(wx, 1.06, 1.06), _primary)
		_box("WinFront_%d" % int(side), Vector3(0.04, 0.38, 0.44), Vector3(wx, 1.06, -0.20), _glass)
		_box("WinMid_%d" % int(side), Vector3(0.04, 0.38, 0.42), Vector3(wx, 1.06, 0.33), _glass)
		_box("WinRear_%d" % int(side), Vector3(0.04, 0.38, 0.34), Vector3(wx, 1.06, 0.83), _glass)

	# Expedition Tubular Roof Rack & 4 Front Spotlights
	for side: float in [-1.0, 1.0]:
		_cylinder("RackRail_%d" % int(side), Vector3(side * 0.58, 1.40, -0.36), Vector3(side * 0.58, 1.40, 1.06), 0.032, _dark)
	_cylinder("RackFrontBar", Vector3(-0.58, 1.40, -0.36), Vector3(0.58, 1.40, -0.36), 0.032, _dark)
	_cylinder("RackRearBar", Vector3(-0.58, 1.40, 1.06), Vector3(0.58, 1.40, 1.06), 0.032, _dark)
	_build_spotlight_bar(Vector3(0.0, 1.48, -0.36), 0.88, 4)

	# Rear Tailgate, Taillights & Detailed Full-Size Spare Wheel
	_box("TailLightL", Vector3(0.12, 0.18, 0.08), Vector3(-0.62, 0.66, 1.16), _brake_light)
	_box("TailLightR", Vector3(0.12, 0.18, 0.08), Vector3(0.62, 0.66, 1.16), _brake_light)
	_cylinder("SpareTire", Vector3(0.0, 0.68, 1.18), Vector3(0.0, 0.68, 1.46), 0.40, _rubber)
	_cylinder("SpareRim", Vector3(0.0, 0.68, 1.24), Vector3(0.0, 0.68, 1.48), 0.23, _metal)
	_torus("SpareBeadlock", Vector3(0.0, 0.68, 1.47), 0.24, _primary, Vector3(90.0, 0.0, 0.0))

	# Driver in Cabin
	_build_human_driver(Vector3(0.30, 0.52, -0.08), false, accent)


# ==============================================================================
# 4. OFFROAD TRUCK (Ford F-150 Raptor Crew Cab - Reference 1 Bottom-Left)
# ==============================================================================
func _build_truck(accent: Color) -> void:
	# Heavy Chassis & High-Clearance Silver Front Skid Plate
	_box("TruckFrame", Vector3(1.26, 0.20, 3.05), Vector3(0.0, 0.22, 0.0), _dark)
	_box("RaptorSkidPlate", Vector3(0.96, 0.12, 0.56), Vector3(0.0, 0.24, -1.56), _chrome, Vector3(26.0, 0.0, 0.0))

	# Muscular Hood with Black Heat-Extractor Scoop
	_box("TruckHood", Vector3(1.44, 0.36, 0.98), Vector3(0.0, 0.68, -1.16), _primary, Vector3(4.5, 0.0, 0.0))
	_box("HoodExtractor", Vector3(0.66, 0.08, 0.54), Vector3(0.0, 0.87, -1.12), _carbon, Vector3(5.0, 0.0, 0.0))

	# Wide Raptor Black Grille & C-Clamp LED Headlights
	_box("RaptorGrille", Vector3(1.16, 0.32, 0.12), Vector3(0.0, 0.66, -1.66), _dark)
	_box("RaptorCrossBar", Vector3(1.12, 0.08, 0.14), Vector3(0.0, 0.66, -1.67), _carbon)
	for i in range(3):
		_box("MarkerLED_%d" % i, Vector3(0.06, 0.03, 0.14), Vector3(-0.22 + float(i) * 0.22, 0.78, -1.67), _amber_light)

	for side: float in [-1.0, 1.0]:
		# C-Clamp Amber/White Headlights
		_box("HeadlightHousing_%d" % int(side), Vector3(0.18, 0.26, 0.12), Vector3(side * 0.62, 0.68, -1.64), _dark)
		_box("HeadlightTopBar_%d" % int(side), Vector3(0.16, 0.045, 0.14), Vector3(side * 0.62, 0.78, -1.65), _light)
		_box("HeadlightBotBar_%d" % int(side), Vector3(0.16, 0.045, 0.14), Vector3(side * 0.62, 0.58, -1.65), _light)
		_box("HeadlightSideBar_%d" % int(side), Vector3(0.045, 0.24, 0.14), Vector3(side * 0.69, 0.68, -1.65), _amber_light)

	_box("FrontBumper", Vector3(1.56, 0.20, 0.24), Vector3(0.0, 0.42, -1.72), _dark)
	_box("RearBumper", Vector3(1.54, 0.20, 0.22), Vector3(0.0, 0.40, 1.62), _dark)

	# Crew Cab with Raked Windshield & Sculpted Roofline
	_box("CabLower", Vector3(1.48, 0.52, 1.38), Vector3(0.0, 0.62, -0.10), _primary)
	_box("CabRoof", Vector3(1.34, 0.09, 1.12), Vector3(0.0, 1.32, -0.02), _primary)
	_box("Windshield", Vector3(1.30, 0.50, 0.06), Vector3(0.0, 1.08, -0.66), _glass, Vector3(-28.0, 0.0, 0.0))
	_box("RearCabWindow", Vector3(1.26, 0.38, 0.06), Vector3(0.0, 1.10, 0.54), _glass)

	for side: float in [-1.0, 1.0]:
		var sx := side * 0.68
		_cylinder("CabAPillar_%d" % int(side), Vector3(sx, 0.86, -0.78), Vector3(sx * 0.95, 1.32, -0.52), 0.048, _primary)
		_box("CabBPillar_%d" % int(side), Vector3(0.06, 0.44, 0.12), Vector3(sx * 0.98, 1.08, -0.02), _dark)
		_box("CabCPillar_%d" % int(side), Vector3(0.08, 0.44, 0.20), Vector3(sx * 0.96, 1.08, 0.46), _primary, Vector3(6.0, 0.0, side * 5.0))
		_box("SideGlassF_%d" % int(side), Vector3(0.05, 0.38, 0.50), Vector3(sx * 0.97, 1.08, -0.30), _glass, Vector3(0.0, 0.0, side * 4.0))
		_box("SideGlassR_%d" % int(side), Vector3(0.05, 0.38, 0.42), Vector3(sx * 0.97, 1.08, 0.22), _glass, Vector3(0.0, 0.0, side * 4.0))
		_box("SideMirror_%d" % int(side), Vector3(0.18, 0.12, 0.10), Vector3(side * 0.78, 0.92, -0.52), _dark)
		# Widebody Black Fender Arches & Running Boards
		_wheel_arch("TruckFrontArch_%d" % int(side), Vector3(side * 0.74, 0.36, -1.06), 0.48, 0.18, 0.09, _dark)
		_wheel_arch("TruckRearArch_%d" % int(side), Vector3(side * 0.74, 0.36, 1.06), 0.48, 0.18, 0.09, _dark)
		_box("RunningBoard_%d" % int(side), Vector3(0.14, 0.07, 1.24), Vector3(side * 0.74, 0.28, -0.05), _dark)
		_box("SideDecal_%d" % int(side), Vector3(0.06, 0.10, 0.48), Vector3(side * 0.745, 0.68, 1.22), _white_decal)

	# Pickup Bed, Tailgate & Tubular Chase Rack
	_box("TruckBed", Vector3(1.48, 0.48, 1.04), Vector3(0.0, 0.64, 1.08), _primary)
	_box("BedLiner", Vector3(1.30, 0.28, 0.94), Vector3(0.0, 0.70, 1.08), _dark)
	_box("TailgateApplique", Vector3(1.22, 0.24, 0.06), Vector3(0.0, 0.66, 1.61), _dark)
	_box("TaillightL", Vector3(0.10, 0.28, 0.08), Vector3(-0.68, 0.68, 1.58), _brake_light)
	_box("TaillightR", Vector3(0.10, 0.28, 0.08), Vector3(0.68, 0.68, 1.58), _brake_light)

	for side: float in [-1.0, 1.0]:
		_cylinder("ChaseUpright_%d" % int(side), Vector3(side * 0.60, 0.88, 0.64), Vector3(side * 0.56, 1.32, 0.58), 0.042, _dark)
		_cylinder("ChaseSlope_%d" % int(side), Vector3(side * 0.56, 1.32, 0.58), Vector3(side * 0.60, 0.88, 1.42), 0.038, _dark)
	_cylinder("ChaseTopBar", Vector3(-0.56, 1.32, 0.58), Vector3(0.56, 1.32, 0.58), 0.042, _dark)
	_build_spotlight_bar(Vector3(0.0, 1.40, -0.44), 0.90, 4)

	# Driver in Cab
	_build_human_driver(Vector3(0.32, 0.56, -0.12), false, accent)


# ==============================================================================
# 5. SPORT SUV (Rally-Raid Coupe SUV - Reference 1 Bottom-Center)
# ==============================================================================
func _build_sport_suv(accent: Color) -> void:
	# Aerodynamic Underbody & Front/Rear Silver Skid Diffusers
	_box("SUVUnderbody", Vector3(1.36, 0.16, 2.80), Vector3(0.0, 0.24, 0.0), _dark)
	_box("FrontSplitter", Vector3(1.06, 0.10, 0.38), Vector3(0.0, 0.28, -1.52), _metal, Vector3(20.0, 0.0, 0.0))
	_box("RearDiffuser", Vector3(1.12, 0.14, 0.36), Vector3(0.0, 0.30, 1.42), _metal, Vector3(-18.0, 0.0, 0.0))

	# Sculpted Lower Body & Sloping Shark-Nose Hood
	_box("SUVBodyMain", Vector3(1.48, 0.46, 2.05), Vector3(0.0, 0.58, 0.12), _primary)
	_box("SUVHood", Vector3(1.40, 0.26, 0.96), Vector3(0.0, 0.64, -1.08), _primary, Vector3(10.0, 0.0, 0.0))
	_box("HoodCreaseL", Vector3(0.18, 0.06, 0.76), Vector3(-0.32, 0.74, -1.04), _primary, Vector3(11.0, -4.0, 0.0))
	_box("HoodCreaseR", Vector3(0.18, 0.06, 0.76), Vector3(0.32, 0.74, -1.04), _primary, Vector3(11.0, 4.0, 0.0))

	# Aggressive Hexagonal Front Grille & Razor-Sharp Angled LED Headlights
	_box("FrontFascia", Vector3(1.42, 0.36, 0.24), Vector3(0.0, 0.50, -1.50), _dark, Vector3(6.0, 0.0, 0.0))
	_box("GrilleSplitter", Vector3(1.36, 0.05, 0.26), Vector3(0.0, 0.56, -1.52), _primary)
	for side: float in [-1.0, 1.0]:
		_box("SUVHeadlight_%d" % int(side), Vector3(0.28, 0.065, 0.16), Vector3(side * 0.50, 0.68, -1.50), _light, Vector3(10.0, side * -16.0, side * -8.0))
		_box("SideIntake_%d" % int(side), Vector3(0.24, 0.18, 0.12), Vector3(side * 0.54, 0.46, -1.56), _carbon)

	# Fastback Coupe-SUV Greenhouse (Steep Windshield + Sloping Roof + Rear Wing)
	_box("SUVWindshield", Vector3(1.24, 0.52, 0.06), Vector3(0.0, 1.00, -0.58), _glass, Vector3(-35.0, 0.0, 0.0))
	_box("SUVRoof", Vector3(1.22, 0.08, 1.18), Vector3(0.0, 1.20, 0.16), _primary, Vector3(-4.5, 0.0, 0.0))
	_box("FastbackGlass", Vector3(1.18, 0.48, 0.06), Vector3(0.0, 0.98, 0.98), _glass, Vector3(34.0, 0.0, 0.0))
	_box("RoofWingSpoiler", Vector3(1.22, 0.05, 0.24), Vector3(0.0, 1.18, 0.82), _carbon, Vector3(12.0, 0.0, 0.0))
	_box("TailgateLipSpoiler", Vector3(1.32, 0.06, 0.14), Vector3(0.0, 0.80, 1.24), _dark)

	for side: float in [-1.0, 1.0]:
		var sx := side * 0.65
		# Sleek Raked Pillars & Frameless Side Glass
		_cylinder("SUVAPillar_%d" % int(side), Vector3(sx, 0.78, -0.78), Vector3(sx * 0.94, 1.22, -0.36), 0.042, _primary)
		_box("SUVCPillar_%d" % int(side), Vector3(0.08, 0.44, 0.28), Vector3(sx * 0.95, 0.98, 0.88), _primary, Vector3(32.0, 0.0, side * 6.0))
		_box("SUVBPillar_%d" % int(side), Vector3(0.05, 0.36, 0.08), Vector3(sx * 0.97, 1.00, 0.12), _dark)
		_box("SUVSideGlassF_%d" % int(side), Vector3(0.05, 0.34, 0.56), Vector3(sx * 0.96, 1.00, -0.18), _glass, Vector3(-3.0, 0.0, side * 6.0))
		_box("SUVSideGlassR_%d" % int(side), Vector3(0.05, 0.32, 0.52), Vector3(sx * 0.96, 0.98, 0.42), _glass, Vector3(-5.0, 0.0, side * 6.0))
		# Black Off-Road Cladding & Wheel Arches
		_wheel_arch("SUVFrontArch_%d" % int(side), Vector3(side * 0.73, 0.34, -1.04), 0.46, 0.14, 0.08, _dark)
		_wheel_arch("SUVRearArch_%d" % int(side), Vector3(side * 0.73, 0.34, 1.04), 0.46, 0.14, 0.08, _dark)
		_box("SideSkirt_%d" % int(side), Vector3(0.08, 0.14, 1.32), Vector3(side * 0.74, 0.32, 0.0), _dark)
		_box("SideBlade_%d" % int(side), Vector3(0.09, 0.06, 1.12), Vector3(side * 0.745, 0.44, 0.02), _carbon, Vector3(-2.5, 0.0, 0.0))

	# Full-Width LED Taillight Bar & Quad Exhausts
	_box("TaillightBar", Vector3(1.36, 0.07, 0.08), Vector3(0.0, 0.72, 1.24), _brake_light)
	for ex: float in [-0.46, -0.34, 0.34, 0.46]:
		_cylinder("ExhaustTip_%d" % int(ex * 100), Vector3(ex, 0.30, 1.36), Vector3(ex, 0.30, 1.54), 0.042, _chrome)

	# Low-Profile Roof Rack & 4-Pod Rally Light Bar
	_cylinder("RoofRailL", Vector3(-0.50, 1.26, -0.28), Vector3(-0.50, 1.22, 0.62), 0.028, _dark)
	_cylinder("RoofRailR", Vector3(0.50, 1.26, -0.28), Vector3(0.50, 1.22, 0.62), 0.028, _dark)
	_build_spotlight_bar(Vector3(0.0, 1.32, -0.26), 0.82, 4)

	# Driver in Cabin
	_build_human_driver(Vector3(0.30, 0.48, -0.06), false, accent)


# ==============================================================================
# 6. TRAIL BIKE / DIRT BIKE (KTM 450 SX-F Motocross - Reference 1 Bottom-Right)
# ==============================================================================
func _build_trail_bike(accent: Color) -> void:
	# Note: Near wheels are at x = NEAR_X (0.88) in 2.5D side view!
	# We center the bike on x = NEAR_X if only Near wheels are visible, or 0.0 with wide forks.
	var bx := NEAR_X
	var front_hub := Vector3(bx, -0.28, -1.05)
	var rear_hub := Vector3(bx, -0.28, 1.05)
	var head_tube_top := Vector3(bx, 0.84, -0.56)
	var head_tube_bot := Vector3(bx, 0.62, -0.64)
	var pivot := Vector3(bx, 0.14, 0.24)
	var cradle_bot := Vector3(bx, 0.02, -0.22)

	# 1. Twin-Spar Perimeter Steel Frame & Aluminum Subframe (All parts connected!)
	_cylinder("SteeringHeadTube", head_tube_bot, head_tube_top, 0.046, _dark)
	_cylinder("FrameDownTube", head_tube_bot, cradle_bot, 0.038, _dark)
	_cylinder("FrameBottomCradle", cradle_bot, pivot, 0.038, _dark)
	for side: float in [-1.0, 1.0]:
		var sx := bx + side * 0.11
		_cylinder("FrameSpar_%d" % int(side), head_tube_top + Vector3(0.0, -0.06, 0.04), Vector3(sx, 0.42, 0.18), 0.034, _dark)
		_cylinder("FramePivotDrop_%d" % int(side), Vector3(sx, 0.42, 0.18), Vector3(sx, 0.14, 0.24), 0.036, _metal)
		# Rear Aluminum Subframe Triangle
		_cylinder("SubframeTop_%d" % int(side), Vector3(sx, 0.56, 0.18), Vector3(bx + side * 0.08, 0.68, 0.88), 0.026, _metal)
		_cylinder("SubframeBot_%d" % int(side), Vector3(sx, 0.22, 0.24), Vector3(bx + side * 0.08, 0.68, 0.88), 0.024, _metal)

	# 2. Inverted Gold/Chrome Telescopic Front Forks (Connected directly to Front Hub!)
	for side: float in [-1.0, 1.0]:
		var fx := bx + side * 0.13
		var fork_top := Vector3(fx, 0.90, -0.54)
		var fork_mid := Vector3(fx, 0.26, -0.82)
		var fork_bot := Vector3(fx, front_hub.y, front_hub.z)
		# Upper Gold Anodized Outer Tube
		_cylinder("ForkUpper_%d" % int(side), fork_mid, fork_top, 0.038, _gold_metal)
		# Lower Chrome Inner Slider Tube
		_cylinder("ForkLower_%d" % int(side), fork_bot, fork_mid, 0.030, _chrome)
		# Lower Fork Protector Guard
		_box("ForkGuard_%d" % int(side), Vector3(0.03, 0.36, 0.06), Vector3(fx, 0.02, -0.94), _primary, Vector3(-24.0, 0.0, 0.0))

	_box("TripleClampTop", Vector3(0.32, 0.04, 0.12), head_tube_top, _dark, Vector3(-24.0, 0.0, 0.0))
	_box("TripleClampBot", Vector3(0.32, 0.04, 0.12), head_tube_bot, _dark, Vector3(-24.0, 0.0, 0.0))

	# 3. Rear Boxed Aluminum Swingarm, Chain & Central Monoshock (Connected to Rear Hub!)
	for side: float in [-1.0, 1.0]:
		var sw_start := Vector3(bx + side * 0.13, pivot.y, pivot.z)
		var sw_end := Vector3(bx + side * 0.13, rear_hub.y, rear_hub.z)
		_cylinder("Swingarm_%d" % int(side), sw_start, sw_end, 0.042, _metal)
	# Central Rear Coilover Monoshock
	_cylinder("RearMonoShock", Vector3(bx, 0.58, 0.20), Vector3(bx, 0.04, 0.44), 0.055, _spring)
	_cylinder("RearShockShaft", Vector3(bx, 0.34, 0.30), Vector3(bx, -0.02, 0.46), 0.028, _chrome)

	# 4. Detailed 4-Stroke Single-Cylinder Engine, Radiator & Exhaust Header/Muffler
	_box("EngineCrankcase", Vector3(0.24, 0.26, 0.34), Vector3(bx, 0.18, -0.02), _metal)
	_cylinder("EngineCylinder", Vector3(bx, 0.24, -0.06), Vector3(bx, 0.48, -0.14), 0.11, _metal)
	_box("ValveCover", Vector3(0.20, 0.08, 0.20), Vector3(bx, 0.50, -0.15), _primary, Vector3(16.0, 0.0, 0.0))
	_cylinder("ClutchCover", Vector3(bx + 0.11, 0.16, 0.04), Vector3(bx + 0.14, 0.16, 0.04), 0.11, _dark)
	_box("Radiator", Vector3(0.26, 0.28, 0.08), Vector3(bx, 0.48, -0.34), _metal, Vector3(18.0, 0.0, 0.0))

	# Sweeping Chrome Exhaust Header Pipe -> Aluminum/Carbon Tail Muffler
	_cylinder("ExhaustHeader1", Vector3(bx + 0.08, 0.38, -0.22), Vector3(bx + 0.15, 0.30, -0.34), 0.032, _chrome)
	_cylinder("ExhaustHeader2", Vector3(bx + 0.15, 0.30, -0.34), Vector3(bx + 0.15, 0.32, 0.32), 0.034, _chrome)
	_cylinder("ExhaustMidPipe", Vector3(bx + 0.15, 0.32, 0.32), Vector3(bx + 0.14, 0.58, 0.62), 0.036, _chrome)
	_tapered_cylinder("ExhaustSilencer", Vector3(bx + 0.14, 0.58, 0.62), Vector3(bx + 0.14, 0.72, 1.02), 0.055, 0.068, _metal)
	_cylinder("ExhaustCarbonTip", Vector3(bx + 0.14, 0.72, 1.02), Vector3(bx + 0.14, 0.75, 1.10), 0.052, _carbon)

	# 5. Sharp KTM-Style Angular Plastics, Tank, Saddle & High Fenders
	_box("FuelTank", Vector3(0.26, 0.26, 0.46), Vector3(bx, 0.62, -0.22), _dark, Vector3(10.0, 0.0, 0.0))
	for side: float in [-1.0, 1.0]:
		# Forward-swept pointed radiator shrouds (Orange/Accent + Black Graphic)
		_prism("RadShroud_%d" % int(side), Vector3(0.06, 0.34, 0.58), Vector3(bx + side * 0.14, 0.56, -0.34), _primary, Vector3(22.0, side * -8.0, 0.0), 0.2)
		_box("ShroudGraphic_%d" % int(side), Vector3(0.065, 0.10, 0.36), Vector3(bx + side * 0.145, 0.58, -0.30), _dark, Vector3(22.0, side * -8.0, 0.0))
		# White Rear Side Number Plates ("#77" panel)
		_box("SideNumberPlate_%d" % int(side), Vector3(0.05, 0.20, 0.44), Vector3(bx + side * 0.11, 0.62, 0.64), _white_decal, Vector3(-16.0, side * 5.0, 0.0))

	# Contoured Motocross Saddle & Upswept Tail Fender
	_box("MotoSeatFront", Vector3(0.22, 0.11, 0.44), Vector3(bx, 0.66, 0.16), _dark, Vector3(-6.0, 0.0, 0.0))
	_box("MotoSeatRear", Vector3(0.20, 0.10, 0.42), Vector3(bx, 0.70, 0.52), _dark, Vector3(-12.0, 0.0, 0.0))
	_box("RearTailFender", Vector3(0.18, 0.05, 0.52), Vector3(bx, 0.76, 0.94), _primary, Vector3(-16.0, 0.0, 0.0))

	# High Swept Motocross Front Fender & Angled Front Number Plate
	_box("FrontFenderMain", Vector3(0.18, 0.045, 0.54), Vector3(bx, 0.58, -0.88), _primary, Vector3(14.0, 0.0, 0.0))
	_box("FrontFenderRear", Vector3(0.16, 0.04, 0.28), Vector3(bx, 0.48, -0.56), _dark, Vector3(-34.0, 0.0, 0.0))
	_box("FrontNumberPlate", Vector3(0.24, 0.26, 0.04), Vector3(bx, 0.80, -0.66), _white_decal, Vector3(-22.0, 0.0, 0.0))

	# 6. Tapered Handlebars, Crossbar Pad & Wrap-Around Handguards
	var bar_center := Vector3(bx, 1.00, -0.52)
	_cylinder("BarRiserL", head_tube_top + Vector3(-0.08, 0.0, 0.0), bar_center + Vector3(-0.08, 0.0, 0.0), 0.022, _metal)
	_cylinder("BarRiserR", head_tube_top + Vector3(0.08, 0.0, 0.0), bar_center + Vector3(0.08, 0.0, 0.0), 0.022, _metal)
	_cylinder("Handlebar", bar_center + Vector3(-0.40, 0.02, 0.04), bar_center + Vector3(0.40, 0.02, 0.04), 0.022, _dark)
	_box("BarPad", Vector3(0.18, 0.055, 0.055), bar_center + Vector3(0.0, 0.03, 0.02), _primary)
	for side: float in [-1.0, 1.0]:
		_box("Handguard_%d" % int(side), Vector3(0.12, 0.08, 0.04), bar_center + Vector3(side * 0.34, 0.02, -0.05), _primary, Vector3(0.0, side * -18.0, 0.0))

	# Motocross Rider in Attack Position
	_build_human_driver(Vector3(bx, 0.62, 0.24), true, accent, bar_center + Vector3(0.0, 0.02, 0.04))


# ==============================================================================
# 7. QUAD RUNNER (Yamaha Raptor 700R Sport ATV - Reference 2)
# ==============================================================================
func _build_quad_runner(accent: Color) -> void:
	# Narrow Lower Tubular Spaceframe (Exposes Front A-Arms & Engine!)
	_box("QuadLowerFrame", Vector3(0.46, 0.16, 1.65), Vector3(0.0, 0.12, 0.05), _dark)
	_box("QuadEngineBlock", Vector3(0.42, 0.34, 0.48), Vector3(0.0, 0.30, 0.02), _metal)
	_cylinder("EngineHeader", Vector3(0.18, 0.36, -0.10), Vector3(0.22, 0.42, 0.65), 0.038, _chrome)
	_tapered_cylinder("QuadMuffler", Vector3(0.22, 0.42, 0.65), Vector3(0.20, 0.54, 1.15), 0.055, 0.065, _dark)

	# Wide Front Double A-Arm Suspension & Aluminum Nerf Bars
	for side: float in [-1.0, 1.0]:
		var fx := side * 0.22
		var wx := side * 0.72
		_cylinder("QuadUpperAArmF_%d" % int(side), Vector3(fx, 0.28, -0.92), Vector3(wx, 0.06, -1.04), 0.032, _metal)
		_cylinder("QuadUpperAArmR_%d" % int(side), Vector3(fx, 0.28, -0.68), Vector3(wx, 0.06, -1.04), 0.032, _metal)
		_cylinder("QuadLowerAArmF_%d" % int(side), Vector3(fx, 0.08, -0.92), Vector3(wx, -0.12, -1.04), 0.036, _dark)
		_cylinder("QuadLowerAArmR_%d" % int(side), Vector3(fx, 0.08, -0.68), Vector3(wx, -0.12, -1.04), 0.036, _dark)
		# Aluminum Side Nerf Bars / Footpeg Cages
		_cylinder("NerfBarOuter_%d" % int(side), Vector3(side * 0.62, 0.10, -0.35), Vector3(side * 0.62, 0.10, 0.38), 0.028, _chrome)
		_cylinder("NerfBarFront_%d" % int(side), Vector3(fx, 0.10, -0.35), Vector3(side * 0.62, 0.10, -0.35), 0.028, _chrome)
		_cylinder("NerfBarRear_%d" % int(side), Vector3(fx, 0.10, 0.38), Vector3(side * 0.62, 0.10, 0.38), 0.028, _chrome)
		_box("FootPeg_%d" % int(side), Vector3(0.32, 0.04, 0.16), Vector3(side * 0.42, 0.10, 0.12), _dark)

	# Rear Swingarm & Solid Rear Axle
	_box("RearSwingarm", Vector3(0.34, 0.14, 0.72), Vector3(0.0, -0.02, 0.72), _metal, Vector3(-12.0, 0.0, 0.0))
	_cylinder("QuadRearAxle", Vector3(-0.76, -0.16, 1.05), Vector3(0.76, -0.16, 1.05), 0.048, _chrome)

	# Front Tubular Aluminum Bumper / Brush Guard
	_cylinder("FrontBumperL", Vector3(-0.20, 0.14, -1.18), Vector3(-0.26, 0.48, -1.36), 0.034, _chrome)
	_cylinder("FrontBumperR", Vector3(0.20, 0.14, -1.18), Vector3(0.26, 0.48, -1.36), 0.034, _chrome)
	_cylinder("FrontBumperTop", Vector3(-0.26, 0.48, -1.36), Vector3(0.26, 0.48, -1.36), 0.034, _chrome)
	_box("BumperSkidPlate", Vector3(0.36, 0.24, 0.04), Vector3(0.0, 0.32, -1.28), _metal, Vector3(-28.0, 0.0, 0.0))

	# Raptor Mantis-Style Angular Nose Cone, Tank & Swept Fenders (Replaces the green brick!)
	_prism("QuadNoseWedge", Vector3(0.56, 0.26, 0.68), Vector3(0.0, 0.56, -0.86), _primary, Vector3(-22.0, 0.0, 0.0), 0.15)
	_box("QuadRadiatorShroud", Vector3(0.42, 0.24, 0.14), Vector3(0.0, 0.44, -0.98), _carbon, Vector3(18.0, 0.0, 0.0))
	_box("QuadFuelTank", Vector3(0.44, 0.26, 0.52), Vector3(0.0, 0.58, -0.24), _primary, Vector3(6.0, 0.0, 0.0))
	_box("TankCoverBlack", Vector3(0.32, 0.08, 0.44), Vector3(0.0, 0.70, -0.22), _carbon, Vector3(6.0, 0.0, 0.0))

	# Contoured Sport Saddle
	_box("QuadSaddleF", Vector3(0.38, 0.16, 0.48), Vector3(0.0, 0.62, 0.22), _dark, Vector3(-4.0, 0.0, 0.0))
	_box("QuadSaddleR", Vector3(0.34, 0.14, 0.42), Vector3(0.0, 0.66, 0.58), _dark, Vector3(-10.0, 0.0, 0.0))

	# High-Swept Batwing Front & Rear Fenders + Angry-Eye Headlights
	for side: float in [-1.0, 1.0]:
		# Angry-eye recessed headlights
		_box("QuadHeadlight_%d" % int(side), Vector3(0.16, 0.06, 0.12), Vector3(side * 0.22, 0.54, -1.08), _light, Vector3(16.0, side * -18.0, side * -12.0))
		# Swept Front Fender Wing
		_box("FrontFenderInner_%d" % int(side), Vector3(0.28, 0.05, 0.46), Vector3(side * 0.42, 0.60, -0.82), _primary, Vector3(18.0, side * -10.0, side * 14.0))
		_box("FrontFenderOuter_%d" % int(side), Vector3(0.32, 0.05, 0.54), Vector3(side * 0.64, 0.58, -0.88), _primary, Vector3(14.0, side * -6.0, side * -6.0))
		# Flared Rear Sport Fenders
		_box("RearFenderInner_%d" % int(side), Vector3(0.26, 0.06, 0.66), Vector3(side * 0.34, 0.64, 0.72), _primary, Vector3(-12.0, 0.0, side * 12.0))
		_box("RearFenderOuter_%d" % int(side), Vector3(0.36, 0.06, 0.74), Vector3(side * 0.62, 0.62, 0.84), _primary, Vector3(-10.0, side * 6.0, side * -8.0))

	# Rear Tail Piece, Brake Light & Grab Bar
	_box("QuadTailPiece", Vector3(0.36, 0.10, 0.38), Vector3(0.0, 0.68, 0.94), _primary, Vector3(-14.0, 0.0, 0.0))
	_box("QuadBrakeLight", Vector3(0.18, 0.06, 0.06), Vector3(0.0, 0.66, 1.14), _brake_light)
	_cylinder("RearGrabBar", Vector3(-0.26, 0.60, 1.22), Vector3(0.26, 0.60, 1.22), 0.032, _chrome)

	# Steering Stem, Handlebars & Handguards
	var bar_pos := Vector3(0.0, 0.96, -0.46)
	_cylinder("SteeringStem", Vector3(0.0, 0.58, -0.36), bar_pos, 0.036, _metal)
	_cylinder("QuadHandlebar", bar_pos + Vector3(-0.42, 0.02, 0.04), bar_pos + Vector3(0.42, 0.02, 0.04), 0.026, _dark)
	_box("QuadBarPad", Vector3(0.18, 0.06, 0.06), bar_pos + Vector3(0.0, 0.03, 0.02), _primary)
	for side: float in [-1.0, 1.0]:
		_box("QuadHandguard_%d" % int(side), Vector3(0.12, 0.08, 0.04), bar_pos + Vector3(side * 0.36, 0.02, -0.04), _primary, Vector3(0.0, side * -16.0, 0.0))

	# Active ATV Rider
	_build_human_driver(Vector3(0.0, 0.60, 0.22), true, accent, bar_pos + Vector3(0.0, 0.02, 0.04))


# ==============================================================================
# ARTICULATED 3D HUMAN DRIVER / MOTOCROSS RIDER
# ==============================================================================
func _build_human_driver(seat_pos: Vector3, is_biker: bool, _accent: Color, handlebar_target: Vector3 = Vector3.ZERO) -> void:
	var driver_node := Node3D.new()
	driver_node.name = "HumanDriver"
	driver_node.position = seat_pos
	_vehicle_root.add_child(driver_node)

	# 1. Articulated Torso, Chest Armor & Neck Brace
	var torso_pos := Vector3(0.0, 0.30, -0.06 if is_biker else 0.02)
	var torso_rot := Vector3(24.0 if is_biker else -6.0, 0.0, 0.0)
	_box_child(driver_node, "DriverTorso", Vector3(0.36, 0.44, 0.24), torso_pos, _suit, torso_rot)
	_box_child(driver_node, "ChestProtector", Vector3(0.38, 0.28, 0.26), torso_pos + Vector3(0.0, 0.06, -0.02), _primary if is_biker else _dark, torso_rot)
	_torus_child(driver_node, "NeckBrace", torso_pos + Vector3(0.0, 0.24, -0.06 if is_biker else 0.0), 0.13, _dark)

	if not is_biker:
		# 5-Point Racing Harness Straps
		_box_child(driver_node, "HarnessL", Vector3(0.065, 0.44, 0.27), torso_pos + Vector3(0.10, 0.0, 0.0), _harness, torso_rot)
		_box_child(driver_node, "HarnessR", Vector3(0.065, 0.44, 0.27), torso_pos + Vector3(-0.10, 0.0, 0.0), _harness, torso_rot)

	# 2. Full-Face Off-Road Helmet (Fixed base position so _process never drops it!)
	var head_pos := torso_pos + Vector3(0.0, 0.38, -0.14 if is_biker else -0.02)
	var head_node := Node3D.new()
	head_node.name = "DriverHead"
	head_node.position = head_pos
	driver_node.add_child(head_node)
	_driver_head = head_node
	_driver_head_base_pos = head_pos

	_sphere_child(head_node, "HelmetShell", Vector3.ZERO, 0.185, _primary)
	_box_child(head_node, "HelmetStripe", Vector3(0.07, 0.36, 0.36), Vector3(0.0, 0.02, 0.0), _dark)
	_sphere_child(head_node, "HelmetGoggles", Vector3(0.0, 0.02, -0.08), 0.155, _glass)
	_box_child(head_node, "HelmetChinBar", Vector3(0.20, 0.10, 0.16), Vector3(0.0, -0.08, -0.11), _dark, Vector3(12.0, 0.0, 0.0))
	_box_child(head_node, "HelmetVisorPeak", Vector3(0.22, 0.03, 0.20), Vector3(0.0, 0.13, -0.12), _primary, Vector3(14.0, 0.0, 0.0))

	# 3. Articulated Upper Arms, Forearms, Gloves & Legs
	if is_biker:
		var local_bar := handlebar_target - seat_pos
		for side: float in [-1.0, 1.0]:
			var shoulder := torso_pos + Vector3(side * 0.21, 0.16, -0.06)
			var hand := local_bar + Vector3(side * 0.32, 0.0, 0.0)
			var elbow := (shoulder + hand) * 0.5 + Vector3(side * 0.09, -0.04, 0.06)
			_cylinder_child(driver_node, "UpperArm_%d" % int(side), shoulder, elbow, 0.052, _suit)
			_cylinder_child(driver_node, "Forearm_%d" % int(side), elbow, hand, 0.045, _primary)
			_sphere_child(driver_node, "Glove_%d" % int(side), hand, 0.058, _harness)

			# Rider Legs & Motocross Boots gripping bike/quad
			var hip := Vector3(side * 0.15, 0.08, 0.02)
			var knee := Vector3(side * 0.19, 0.02, -0.32)
			var foot := Vector3(side * 0.20, -0.38, -0.12)
			_cylinder_child(driver_node, "Thigh_%d" % int(side), hip, knee, 0.068, _suit)
			_sphere_child(driver_node, "KneePad_%d" % int(side), knee, 0.065, _dark)
			_cylinder_child(driver_node, "Boot_%d" % int(side), knee, foot, 0.058, _primary)
			_box_child(driver_node, "BootFoot_%d" % int(side), Vector3(0.11, 0.09, 0.22), foot + Vector3(0.0, 0.0, -0.05), _dark)
	else:
		var wheel_center := torso_pos + Vector3(0.0, 0.06, -0.44)
		for side: float in [-1.0, 1.0]:
			var shoulder := torso_pos + Vector3(side * 0.20, 0.14, 0.0)
			var hand := wheel_center + Vector3(side * 0.15, 0.03, 0.0)
			var elbow := (shoulder + hand) * 0.5 + Vector3(side * 0.06, -0.07, 0.05)
			_cylinder_child(driver_node, "UpperArm_%d" % int(side), shoulder, elbow, 0.052, _suit)
			_cylinder_child(driver_node, "Forearm_%d" % int(side), elbow, hand, 0.045, _suit)
			_sphere_child(driver_node, "Glove_%d" % int(side), hand, 0.055, _harness)

		# 3-Spoke Sport Steering Wheel & Column
		_torus_child(driver_node, "SteeringWheelRim", wheel_center, 0.16, _dark)
		_cylinder_child(driver_node, "SteeringColumn", wheel_center, wheel_center + Vector3(0.0, -0.14, 0.24), 0.032, _metal)
		_sphere_child(driver_node, "SteeringHub", wheel_center, 0.045, _primary)


func _build_bucket_seat(pos: Vector3) -> void:
	_box("SeatBase", Vector3(0.42, 0.10, 0.44), pos + Vector3(0.0, 0.06, -0.04), _dark)
	_box("SeatBack", Vector3(0.40, 0.62, 0.10), pos + Vector3(0.0, 0.36, 0.16), _dark, Vector3(-10.0, 0.0, 0.0))
	_box("SeatHeadrest", Vector3(0.30, 0.18, 0.10), pos + Vector3(0.0, 0.70, 0.22), _primary, Vector3(-10.0, 0.0, 0.0))
	for side: float in [-1.0, 1.0]:
		_box("SeatBolster_%d" % int(side), Vector3(0.08, 0.54, 0.20), pos + Vector3(side * 0.20, 0.34, 0.10), _primary, Vector3(-10.0, side * -8.0, 0.0))


func _build_spotlight_bar(center: Vector3, width: float, count: int) -> void:
	_cylinder("LightBarMount", center + Vector3(-width * 0.5, -0.04, 0.0), center + Vector3(width * 0.5, -0.04, 0.0), 0.026, _dark)
	for i in range(count):
		var t := float(i) / float(maxi(count - 1, 1)) - 0.5
		var lx := center.x + t * width * 0.86
		var lpos := Vector3(lx, center.y + 0.02, center.z)
		_cylinder("SpotHousing_%d" % i, lpos + Vector3(0.0, 0.0, 0.05), lpos + Vector3(0.0, 0.0, -0.05), 0.068, _dark)
		_cylinder("SpotBezel_%d" % i, lpos + Vector3(0.0, 0.0, -0.04), lpos + Vector3(0.0, 0.0, -0.065), 0.062, _chrome)
		_cylinder("SpotLens_%d" % i, lpos + Vector3(0.0, 0.0, -0.05), lpos + Vector3(0.0, 0.0, -0.072), 0.052, _light)


# ==============================================================================
# MODERN SCULPTED OFF-ROAD WHEELS & DYNAMIC SUSPENSION
# ==============================================================================
func _build_wheels() -> void:
	for wheel_name: String in _wheel_names:
		var wheel := get_parent().get_node_or_null(wheel_name) as Node3D
		if wheel == null:
			continue
		var old_tire := wheel.get_node_or_null("TireMesh") as MeshInstance3D
		var old_rim := wheel.get_node_or_null("RimMesh") as MeshInstance3D
		if old_tire:
			old_tire.visible = false
		if old_rim:
			old_rim.visible = false

		var is_far := wheel_name.contains("Far")
		var side_sign := -1.0 if is_far else 1.0

		# 1. Main Tire Carcass
		var tire := MeshInstance3D.new()
		tire.name = "TireCarcass"
		var tire_mesh := CylinderMesh.new()
		tire_mesh.top_radius = 0.45
		tire_mesh.bottom_radius = 0.45
		tire_mesh.height = 0.34
		tire_mesh.radial_segments = 28
		tire.mesh = tire_mesh
		tire.material_override = _rubber
		tire.rotation_degrees.z = 90.0
		wheel.add_child(tire)

		# 2. Rounded 3D Sidewall Shoulders (TorusMesh on inner & outer sidewalls)
		for side: float in [-1.0, 1.0]:
			var shoulder := MeshInstance3D.new()
			var sh_mesh := TorusMesh.new()
			sh_mesh.inner_radius = 0.27
			sh_mesh.outer_radius = 0.445
			sh_mesh.rings = 24
			sh_mesh.ring_segments = 12
			shoulder.mesh = sh_mesh
			shoulder.material_override = _rubber
			shoulder.position.x = side * 0.115
			shoulder.rotation_degrees.z = 90.0
			wheel.add_child(shoulder)

		# 3. 20 Sculpted Alternating Mud-Terrain Tread Blocks (No giant gear teeth!)
		var lug_count := 20
		for t in range(lug_count):
			var angle := TAU * float(t) / float(lug_count)
			var lug := MeshInstance3D.new()
			lug.name = "TreadBlock_%d" % t
			var lug_mesh := BoxMesh.new()
			lug_mesh.size = Vector3(0.35, 0.036, 0.082)
			lug.mesh = lug_mesh
			lug.material_override = _tread
			lug.position = Vector3((float(t % 2) - 0.5) * 0.03, sin(angle) * 0.452, cos(angle) * 0.452)
			lug.rotation = Vector3(angle, (0.14 if t % 2 == 0 else -0.14), 0.0)
			wheel.add_child(lug)

		# 4. Deep-Dish Alloy Wheel Barrel
		var rim := MeshInstance3D.new()
		rim.name = "AlloyBarrel"
		var rim_mesh := CylinderMesh.new()
		rim_mesh.top_radius = 0.285
		rim_mesh.bottom_radius = 0.285
		rim_mesh.height = 0.35
		rim_mesh.radial_segments = 24
		rim.mesh = rim_mesh
		rim.material_override = _dark
		rim.rotation_degrees.z = 90.0
		wheel.add_child(rim)

		# 5. Colored Outer Beadlock Ring + 12 Chrome Beadlock Bolts
		var beadlock := MeshInstance3D.new()
		var bl_mesh := TorusMesh.new()
		bl_mesh.inner_radius = 0.235
		bl_mesh.outer_radius = 0.295
		bl_mesh.rings = 24
		bl_mesh.ring_segments = 10
		beadlock.mesh = bl_mesh
		beadlock.material_override = _primary
		beadlock.position.x = side_sign * 0.168
		beadlock.rotation_degrees.z = 90.0
		wheel.add_child(beadlock)

		# 6. Properly Oriented 6-Spoke Split-Alloy Wheel Face (Rotated on X-axis!)
		for i in range(6):
			var spoke := MeshInstance3D.new()
			var spoke_mesh := BoxMesh.new()
			spoke_mesh.size = Vector3(0.04, 0.048, 0.50)
			spoke.mesh = spoke_mesh
			spoke.material_override = _metal
			spoke.position.x = side_sign * 0.145
			spoke.rotation_degrees = Vector3(float(i) * 30.0, 0.0, 0.0)
			wheel.add_child(spoke)

		# 7. Center Hub Cap, Vented Brake Disc & Racing Caliper
		var hub_cap := MeshInstance3D.new()
		var hub_mesh := CylinderMesh.new()
		hub_mesh.top_radius = 0.085
		hub_mesh.bottom_radius = 0.095
		hub_mesh.height = 0.08
		hub_mesh.radial_segments = 14
		hub_cap.mesh = hub_mesh
		hub_cap.material_override = _primary
		hub_cap.position.x = side_sign * 0.165
		hub_cap.rotation_degrees.z = 90.0
		wheel.add_child(hub_cap)

		var brake_disc := MeshInstance3D.new()
		var disc_mesh := CylinderMesh.new()
		disc_mesh.top_radius = 0.20
		disc_mesh.bottom_radius = 0.20
		disc_mesh.height = 0.03
		disc_mesh.radial_segments = 18
		brake_disc.mesh = disc_mesh
		brake_disc.material_override = _chrome
		brake_disc.position.x = side_sign * 0.08
		brake_disc.rotation_degrees.z = 90.0
		wheel.add_child(brake_disc)

		var caliper := MeshInstance3D.new()
		var cal_mesh := BoxMesh.new()
		cal_mesh.size = Vector3(0.06, 0.13, 0.09)
		caliper.mesh = cal_mesh
		caliper.material_override = _harness
		caliper.position = Vector3(side_sign * 0.09, 0.09, -0.14)
		wheel.add_child(caliper)


func _build_suspension() -> void:
	for wheel_name: String in _wheel_names:
		var shock_assembly := Node3D.new()
		shock_assembly.name = "VisibleShock_" + wheel_name
		_visual_root.add_child(shock_assembly)

		for part_name in ["UpperBody", "PistonRod", "CoilSpring", "ControlLink"]:
			var part := Node3D.new()
			part.name = part_name
			shock_assembly.add_child(part)

		_shock_roots.append(shock_assembly)


func _update_shocks() -> void:
	var is_bike := _variant_name in ["Trail Bike", "Dirt Bike"]
	var is_monster := _variant_name == "Monster Truck"
	var mount_height := 0.56 if is_monster else 0.26

	for index in range(_shock_roots.size()):
		var shock_root := _shock_roots[index]
		var wheel := get_parent().get_node_or_null(_wheel_names[index]) as Node3D
		if wheel == null or not wheel.visible or is_bike:
			shock_root.visible = false
			continue

		shock_root.visible = true
		# Convert wheel world position into _visual_root local space (Prevents X criss-crossing!)
		var wheel_local := _visual_root.to_local(wheel.global_position)
		var lower_mount := wheel_local + Vector3(-signf(wheel_local.x) * 0.08, 0.06, 0.0)
		var upper_mount := Vector3(wheel_local.x * 0.72, mount_height, wheel_local.z * 0.88)
		var mid_point := upper_mount.lerp(lower_mount, 0.54)
		var spring_top := upper_mount.lerp(lower_mount, 0.18)
		var spring_bot := upper_mount.lerp(lower_mount, 0.78)
		var link_inner := Vector3(wheel_local.x * 0.35, 0.08 if not is_monster else 0.28, wheel_local.z * 0.62)

		_set_segment(shock_root.get_node("UpperBody") as Node3D, upper_mount, mid_point, 0.046, _metal)
		_set_segment(shock_root.get_node("PistonRod") as Node3D, mid_point, lower_mount, 0.024, _chrome)
		_set_segment(shock_root.get_node("CoilSpring") as Node3D, spring_top, spring_bot, 0.064, _spring)
		_set_segment(shock_root.get_node("ControlLink") as Node3D, link_inner, wheel_local + Vector3(0.0, -0.04, 0.0), 0.036, _dark)


# ==============================================================================
# PROCEDURAL 3D GEOMETRY HELPERS (WITH ROTATION, PRISMS, ARCHES & TAPERS)
# ==============================================================================
func _box(node_name: String, mesh_size: Vector3, pos: Vector3, material: Material, rot_deg: Vector3 = Vector3.ZERO) -> void:
	_box_child(_vehicle_root, node_name, mesh_size, pos, material, rot_deg)


func _box_child(parent: Node3D, node_name: String, mesh_size: Vector3, pos: Vector3, material: Material, rot_deg: Vector3 = Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = mesh_size
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = pos
	visual.rotation_degrees = rot_deg
	parent.add_child(visual)


func _prism(node_name: String, mesh_size: Vector3, pos: Vector3, material: Material, rot_deg: Vector3 = Vector3.ZERO, left_to_right: float = 0.5) -> void:
	var mesh := PrismMesh.new()
	mesh.size = mesh_size
	mesh.left_to_right = left_to_right
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = pos
	visual.rotation_degrees = rot_deg
	_vehicle_root.add_child(visual)


func _wheel_arch(node_name: String, center: Vector3, radius: float, width: float, thickness: float, material: Material) -> void:
	# Builds a 5-segment polygonal 3D off-road fender flare arch around the top of a wheel well
	var arch_root := Node3D.new()
	arch_root.name = node_name
	arch_root.position = center
	_vehicle_root.add_child(arch_root)

	var segments := 5
	var start_angle := -PI * 0.38
	var end_angle := PI * 0.38
	for i in range(segments):
		var a0 := lerpf(start_angle, end_angle, float(i) / float(segments))
		var a1 := lerpf(start_angle, end_angle, float(i + 1) / float(segments))
		var mid_a := (a0 + a1) * 0.5
		var seg_len := 2.0 * radius * sin((a1 - a0) * 0.5) + 0.04
		var pos := Vector3(0.0, cos(mid_a) * radius, sin(mid_a) * radius)
		_box_child(arch_root, "ArchSeg_%d" % i, Vector3(width, thickness, seg_len), pos, material, Vector3(-rad_to_deg(mid_a), 0.0, 0.0))


func _sphere(node_name: String, pos: Vector3, radius: float, material: Material) -> void:
	_sphere_child(_vehicle_root, node_name, pos, radius, material)


func _sphere_child(parent: Node3D, node_name: String, pos: Vector3, radius: float, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = pos
	parent.add_child(visual)


func _torus(node_name: String, pos: Vector3, radius: float, material: Material, rot_deg: Vector3 = Vector3(90.0, 0.0, 0.0)) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.72
	mesh.outer_radius = radius
	mesh.rings = 16
	mesh.ring_segments = 10
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = pos
	visual.rotation_degrees = rot_deg
	_vehicle_root.add_child(visual)


func _torus_child(parent: Node3D, node_name: String, pos: Vector3, radius: float, material: Material) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.72
	mesh.outer_radius = radius
	mesh.rings = 16
	mesh.ring_segments = 10
	var visual := MeshInstance3D.new()
	visual.name = node_name
	visual.mesh = mesh
	visual.material_override = material
	visual.position = pos
	visual.rotation.x = PI * 0.5
	parent.add_child(visual)


func _cylinder(node_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	_cylinder_child(_vehicle_root, node_name, start, end, radius, material)


func _tapered_cylinder(node_name: String, start: Vector3, end: Vector3, bot_r: float, top_r: float, material: Material) -> void:
	var visual := Node3D.new()
	visual.name = node_name
	_vehicle_root.add_child(visual)
	_set_tapered_segment(visual, start, end, bot_r, top_r, material)


func _cylinder_child(parent: Node3D, node_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var visual := Node3D.new()
	visual.name = node_name
	parent.add_child(visual)
	_set_segment(visual, start, end, radius, material)


func _set_segment(node: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	_set_tapered_segment(node, start, end, radius, radius, material)


func _set_tapered_segment(node: Node3D, start: Vector3, end: Vector3, bot_r: float, top_r: float, material: Material) -> void:
	if node == null:
		return
	var delta := end - start
	var length := delta.length()
	if length < 0.001:
		return

	var mesh_visual := node.get_node_or_null("Segment") as MeshInstance3D
	var r_scale := top_r / maxf(bot_r, 0.001)
	if mesh_visual == null:
		mesh_visual = MeshInstance3D.new()
		mesh_visual.name = "Segment"
		var mesh := CylinderMesh.new()
		mesh.top_radius = r_scale
		mesh.bottom_radius = 1.0
		mesh.height = 1.0
		mesh.radial_segments = 12
		mesh_visual.mesh = mesh
		mesh_visual.material_override = material
		node.add_child(mesh_visual)
	else:
		mesh_visual.material_override = material

	node.position = (start + end) * 0.5
	var dir := delta / length
	var up := Vector3.FORWARD if absf(dir.y) > 0.92 else Vector3.UP
	var right := dir.cross(up).normalized()
	var forward := right.cross(dir).normalized()
	node.basis = Basis(right * bot_r, dir * length, forward * bot_r)


# ==============================================================================
# RUNTIME ANIMATION, PITCH, HEAD REACTION & DUST PARTICLES
# ==============================================================================
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
		var vibration := sin(_visual_time * 42.0) * controller.throttle_input * 0.006
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

		# Dynamic Driver Head bobbing & G-force reactions (Preserves _driver_head_base_pos.y!)
		if is_instance_valid(_driver_head):
			var target_head_x := -controller.throttle_input * 0.16 + controller.brake_input * 0.22
			_driver_head.rotation.x = lerpf(_driver_head.rotation.x, target_head_x, 1.0 - exp(-18.0 * delta))
			_driver_head.position.y = _driver_head_base_pos.y + sin(_visual_time * 26.0) * (controller.throttle_input * 0.012)

		# Dust particles
		var fwd_speed := controller.linear_velocity.dot(-controller.global_transform.basis.z)
		var emit_dust: bool = fwd_speed > 1.2 and controller._wheels[0]["in_contact"] and controller.throttle_input > 0.05
		for emitter: GPUParticles3D in _dust_emitters:
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
	for node_name: String in [
		"ChassisVisual", "CabinVisual", "UnderbodyVisual", "RoofVisual",
		"FrontBumperVisual", "RearBumperVisual", "RearSuspensionNear",
		"RearSuspensionFar", "FrontSuspensionNear", "FrontSuspensionFar",
		"RearContactDebug", "FrontContactDebug",
	]:
		var visual := get_parent().get_node_or_null(node_name) as Node3D
		if visual:
			visual.visible = false


func _create_materials() -> void:
	_primary = _material(Color(1.0, 0.62, 0.05), 0.24, 0.35)
	_primary.clearcoat_enabled = true
	_primary.clearcoat = 0.75
	_primary.clearcoat_roughness = 0.15

	_primary_dark = _material(Color(0.6, 0.35, 0.02), 0.32, 0.3)
	_secondary = _material(Color(0.18, 0.22, 0.26), 0.45, 0.2)
	_dark = _material(Color(0.06, 0.07, 0.085), 0.62, 0.15)
	_carbon = _material(Color(0.10, 0.11, 0.13), 0.35, 0.40)
	_rubber = _material(Color(0.035, 0.038, 0.042), 0.90, 0.0)
	_metal = _material(Color(0.45, 0.49, 0.54), 0.26, 0.82)
	_chrome = _material(Color(0.88, 0.91, 0.95), 0.12, 0.96)
	_gold_metal = _material(Color(0.92, 0.68, 0.16), 0.20, 0.88)
	_glass = _material(Color(0.05, 0.14, 0.22), 0.06, 0.35)
	_white_decal = _material(Color(0.94, 0.95, 0.97), 0.30, 0.1)

	_light = _material(Color(1.0, 0.96, 0.82), 0.08, 0.0)
	_light.emission_enabled = true
	_light.emission = Color(1.0, 0.92, 0.70)
	_light.emission_energy_multiplier = 2.2

	_amber_light = _material(Color(1.0, 0.55, 0.05), 0.1, 0.0)
	_amber_light.emission_enabled = true
	_amber_light.emission = Color(1.0, 0.50, 0.02)
	_amber_light.emission_energy_multiplier = 1.8

	_brake_light = _material(Color(0.95, 0.08, 0.06), 0.1, 0.0)
	_brake_light.emission_enabled = true
	_brake_light.emission = Color(1.0, 0.12, 0.08)
	_brake_light.emission_energy_multiplier = 2.0

	_spring = _material(Color(1.0, 0.52, 0.08), 0.32, 0.35)
	_tread = _material(Color(0.022, 0.024, 0.028), 0.95, 0.0)
	_suit = _material(Color(0.09, 0.12, 0.16), 0.65, 0.05)
	_skin = _material(Color(0.55, 0.30, 0.18), 0.85, 0.0)
	_harness = _material(Color(0.92, 0.16, 0.08), 0.45, 0.1)

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
