extends Node3D
const GAME_HUD_SCRIPT = preload("res://scripts/game_hud.gd")
const MAIN_MENU_SCRIPT = preload("res://scripts/main_menu.gd")

@export var camera_follow_speed := 5.0
@export var show_debug_overlay := false

@onready var vehicle: VehicleController = $PlaceholderVehicle
@onready var side_camera: Camera3D = $SideCamera
@onready var terrain: Node3D = $ProceduralTerrain
@onready var environment_visuals: Node3D = $EnvironmentVisuals
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var profile = get_node("/root/GameProfile")

var _debug_label: Label
var _distance_label: Label
var _stage_label: Label
var _coin_label: Label
var _nitro_label: Label
var _fuel_label: Label
var _fuel_bar: ColorRect
var _game_hud: Control
var _hud_panel: ColorRect
var _status_panel: ColorRect
var _status_label: Label
var _eliminated := false
var _elimination_timer := 0.0
var _best_distance := 0.0
var _coins_collected := 0
var _restart_timer := 0.0
var _fuel := 100.0
var _fuel_game_over := false
var _main_menu: Control
var _rollover_timer := 0.0
const FUEL_CONSUMPTION_PER_SECOND := 1.8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var overlay := CanvasLayer.new()
	overlay.name = "VehicleDebugOverlay"
	add_child(overlay)

	_debug_label = Label.new()
	_debug_label.name = "Telemetry"
	_debug_label.position = Vector2(16.0, 16.0)
	_debug_label.add_theme_color_override("font_color", Color.WHITE)
	_debug_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_debug_label.add_theme_constant_override("shadow_offset_x", 1)
	_debug_label.add_theme_constant_override("shadow_offset_y", 1)
	overlay.add_child(_debug_label)
	_debug_label.visible = show_debug_overlay
	_create_game_hud()
	_create_status_hud()
	_create_main_menu(overlay)
	terrain.connect("coin_collected", Callable(self, "_on_coin_collected"))
	terrain.connect("fuel_collected", Callable(self, "_on_fuel_collected"))
	vehicle.stunt_completed.connect(_on_stunt_completed)
	_best_distance = profile.best_distance
	_apply_profile()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()


func _create_main_menu(overlay: CanvasLayer) -> void:
	_main_menu = MAIN_MENU_SCRIPT.new()
	_main_menu.name = "MainMenu"
	_main_menu.setup(self, profile)
	overlay.add_child(_main_menu)
	_main_menu.play_requested.connect(_on_play_requested)
	_main_menu.vehicle_changed.connect(_apply_profile)
	_main_menu.stage_changed.connect(_apply_profile)
	get_tree().paused = true


func _apply_profile() -> void:
	var vehicle_data: Dictionary = profile.VEHICLES.get(profile.selected_vehicle, profile.VEHICLES["Buggy"])
	vehicle.configure_vehicle(profile.selected_vehicle, vehicle_data)
	vehicle.set_stage_gravity(profile.selected_stage)
	terrain.call("set_stage_theme", profile.selected_stage)
	environment_visuals.set_stage_theme(profile.selected_stage)
	_apply_world_sky(profile.selected_stage)


func _apply_world_sky(stage_name: String) -> void:
	var environment := world_environment.environment
	if environment == null:
		return
	var sky := environment.sky
	var sky_material: ProceduralSkyMaterial = null
	if sky:
		sky_material = sky.sky_material as ProceduralSkyMaterial
	if stage_name == "Moon":
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.005, 0.008, 0.03)
	elif stage_name == "Highway":
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.18, 0.48, 0.78)
	elif stage_name == "Desert":
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.82, 0.45, 0.2)
	elif stage_name == "Mars":
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.26, 0.055, 0.025)
	elif stage_name == "Snow":
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.48, 0.7, 0.86)
	else:
		environment.background_mode = Environment.BG_SKY
	if sky_material:
		sky_material.sky_top_color = Color(0.01, 0.015, 0.06) if stage_name == "Moon" else sky_material.sky_top_color


func _create_status_hud() -> void:
	var overlay := get_node("VehicleDebugOverlay") as CanvasLayer
	_status_panel = ColorRect.new()
	_status_panel.name = "StatusPanel"
	_status_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_panel.color = Color(0.01, 0.02, 0.03, 0.76)
	_status_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_status_panel.visible = false
	overlay.add_child(_status_panel)
	_status_label = Label.new()
	_status_label.set_anchors_preset(Control.PRESET_CENTER)
	_status_label.position = Vector2(-220.0, -90.0)
	_status_label.size = Vector2(440.0, 180.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 26)
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58))
	_status_panel.add_child(_status_label)


func _toggle_pause_menu() -> void:
	if _eliminated:
		return
	if _status_panel.visible:
		return
	if get_tree().paused:
		_resume_game()
	else:
		_show_pause_menu()


func _show_pause_menu() -> void:
	get_tree().paused = true
	_status_panel.visible = true
	_status_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_status_label.text = "PAUSED"
	_create_pause_buttons()


func _create_pause_buttons() -> void:
	for child in _status_panel.get_children():
		if child is Button:
			child.queue_free()
	var buttons := VBoxContainer.new()
	buttons.set_anchors_preset(Control.PRESET_CENTER)
	buttons.position = Vector2(-110.0, 42.0)
	buttons.size = Vector2(220.0, 168.0)
	buttons.add_theme_constant_override("separation", 12)
	_status_panel.add_child(buttons)
	for button_data in [
		["RESUME", Callable(self, "_resume_game")],
		["RESTART", Callable(self, "_restart_from_pause")],
		["MAIN MENU", Callable(self, "_return_to_main_menu")],
	]:
		var button := Button.new()
		button.text = button_data[0]
		button.custom_minimum_size = Vector2(220.0, 48.0)
		button.pressed.connect(button_data[1])
		buttons.add_child(button)


func _resume_game() -> void:
	_status_panel.visible = false
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().paused = false


func _restart_from_pause() -> void:
	_status_panel.visible = false
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().paused = false
	_restart_run()


func _create_game_hud() -> void:
	var overlay := get_node("VehicleDebugOverlay") as CanvasLayer
	_game_hud = GAME_HUD_SCRIPT.new()
	_game_hud.name = "DashboardHud"
	overlay.add_child(_game_hud)
	_game_hud.accelerator_changed.connect(Callable(self, "_on_touch_accelerator_changed"))
	_game_hud.brake_changed.connect(Callable(self, "_on_touch_brake_changed"))
	_game_hud.pause_requested.connect(_toggle_pause_menu)
	_hud_panel = ColorRect.new()
	_hud_panel.visible = false
	overlay.add_child(_hud_panel)
	return
	_hud_panel.name = "GameHudPanel"
	_hud_panel.position = Vector2(24.0, 22.0)
	_hud_panel.size = Vector2(270.0, 132.0)
	_hud_panel.color = Color(0.025, 0.04, 0.055, 0.78)
	overlay.add_child(_hud_panel)
	_distance_label = Label.new()
	_distance_label.position = Vector2(18.0, 8.0)
	_distance_label.add_theme_font_size_override("font_size", 24)
	_distance_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42))
	_hud_panel.add_child(_distance_label)
	_stage_label = Label.new()
	_stage_label.position = Vector2(18.0, 46.0)
	_stage_label.add_theme_font_size_override("font_size", 13)
	_stage_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.9))
	_hud_panel.add_child(_stage_label)
	_coin_label = Label.new()
	_coin_label.position = Vector2(18.0, 61.0)
	_coin_label.add_theme_font_size_override("font_size", 14)
	_coin_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.16))
	_hud_panel.add_child(_coin_label)
	_nitro_label = Label.new()
	_nitro_label.position = Vector2(18.0, 79.0)
	_nitro_label.add_theme_font_size_override("font_size", 13)
	_nitro_label.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	_hud_panel.add_child(_nitro_label)
	_fuel_label = Label.new()
	_fuel_label.position = Vector2(18.0, 98.0)
	_fuel_label.add_theme_font_size_override("font_size", 13)
	_hud_panel.add_child(_fuel_label)
	_fuel_bar = ColorRect.new()
	_fuel_bar.position = Vector2(122.0, 101.0)
	_fuel_bar.size = Vector2(125.0, 10.0)
	_fuel_bar.color = Color(0.2, 0.82, 0.28)
	_hud_panel.add_child(_fuel_bar)


func _physics_process(delta: float) -> void:
	if _eliminated:
		_restart_timer -= delta
		if Input.is_action_just_pressed("vehicle_reset"):
			_restart_run()
		elif not _fuel_game_over and _restart_timer <= 0.0:
			_restart_run()
		return
	_update_fuel(delta)
	var target := vehicle.global_position + Vector3(24.0, 2.35, 0.0)
	var weight := 1.0 - exp(-camera_follow_speed * delta)
	side_camera.global_position = side_camera.global_position.lerp(target, weight)
	var speed := absf(vehicle.linear_velocity.dot(-vehicle.global_transform.basis.z))
	var target_camera_size := clampf(10.0 + speed * 0.05, 10.0, 11.5)
	side_camera.size = lerpf(side_camera.size, target_camera_size, 1.0 - exp(-4.0 * delta))
	var profile: Dictionary = terrain.call("get_difficulty_profile")
	_game_hud.set("distance", int(maxf(-vehicle.global_position.z, 0.0)))
	_game_hud.set("best_distance", int(_best_distance))
	_game_hud.set("coins", _coins_collected)
	_game_hud.set("fuel", _fuel)
	_game_hud.set("nitro", vehicle.nitro_amount)
	_game_hud.set("rpm", vehicle.engine_rpm)
	_game_hud.set("speed", speed * 3.6)
	_game_hud.set("throttle", vehicle.throttle_input)
	_game_hud.set("brake", vehicle.brake_input)
	_check_elimination(delta)
	if show_debug_overlay:
		var forward_speed := vehicle.linear_velocity.dot(-vehicle.global_transform.basis.z)
		_debug_label.text = (
			"Throttle: %+.1f   Brake: %.1f   Drive torque: %+.0f Nm   Rear traction: %+.0f N\n"
			+ "Speed: %+.2f m/s   Velocity: %s   Distance: %.1f m\n"
			+ "Pitch input: %+.1f   Pitch angle: %+.2f rad   Pitch speed: %+.2f rad/s\n"
			+ "Rear contact: %s (%.2f m)   Front contact: %s (%.2f m)\n"
			+ "Terrain chunks: %d   Seeded procedural track\n"
			+ "Stage: %s   Difficulty: %.2fx   Obstacles: %d\n"
			+ "W/Up accelerate  S/Down reverse  Space brake  A/D pitch  R reset"
		) % [
			vehicle.throttle_input,
			vehicle.brake_input,
			vehicle.applied_engine_torque,
			vehicle.applied_drive_force,
			forward_speed,
			str(vehicle.linear_velocity.snapped(Vector3(0.01, 0.01, 0.01))),
			-vehicle.global_position.z,
			vehicle.pitch_input,
			vehicle.global_rotation.x,
			vehicle.angular_velocity.x,
			"YES" if vehicle._wheels[0]["in_contact"] else "NO",
			vehicle._wheels[0]["compression"],
			"YES" if vehicle._wheels[1]["in_contact"] else "NO",
			vehicle._wheels[1]["compression"],
			terrain.call("get_active_chunk_count"),
			terrain.call("get_difficulty_profile")["stage"],
			terrain.call("get_difficulty_profile")["multiplier"],
			terrain.call("get_obstacle_count"),
		]
	else:
		_debug_label.visible = false


func _check_elimination(delta: float) -> void:
	var distance := maxf(-vehicle.global_position.z, 0.0)
	_best_distance = maxf(_best_distance, distance)
	if distance > profile.best_distance:
		profile.best_distance = distance
	var fallen: bool = vehicle.global_position.y < -5.5
	if fallen:
		_elimination_timer += delta
	else:
		_elimination_timer = 0.0
	var up_direction := vehicle.global_transform.basis.y.normalized()
	var upside_down := up_direction.dot(Vector3.UP) < -0.58
	var nearly_stopped := vehicle.linear_velocity.length() < 1.4 and absf(vehicle.angular_velocity.x) < 1.5
	var has_ground_contact := bool(vehicle._wheels[0]["in_contact"]) or bool(vehicle._wheels[1]["in_contact"])
	if upside_down and nearly_stopped and has_ground_contact:
		_rollover_timer += delta
	else:
		_rollover_timer = maxf(_rollover_timer - delta * 2.0, 0.0)
	if _elimination_timer > 0.7 or _rollover_timer > 1.25:
		_show_game_over("RUN OVER")


func _restart_run() -> void:
	get_tree().paused = false
	vehicle.request_reset()
	terrain.call("reset_run")
	_fuel = 100.0
	_fuel_game_over = false
	_coins_collected = 0
	vehicle.set_fuel_depleted(false)
	_elimination_timer = 0.0
	_rollover_timer = 0.0
	_eliminated = false
	_status_panel.visible = false
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_restart_timer = 0.0
	profile.save_profile()


func _on_play_requested() -> void:
	_main_menu.visible = false
	get_tree().paused = false



func _update_fuel(delta: float) -> void:
	if _fuel_game_over:
		return
	var activity := absf(vehicle.throttle_input)
	if activity > 0.01:
		_fuel = maxf(_fuel - (FUEL_CONSUMPTION_PER_SECOND * activity * delta), 0.0)
	if is_zero_approx(_fuel):
		_fuel_game_over = true
		vehicle.set_fuel_depleted(true)
		_show_game_over("OUT OF FUEL")


func _update_fuel_hud() -> void:
	if not is_instance_valid(_fuel_label):
		return
	_fuel_label.text = "FUEL  %03d%%" % int(_fuel)
	_fuel_bar.size.x = 125.0 * _fuel / 100.0
	if _fuel <= 10.0:
		_fuel_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.12))
	elif _fuel <= 25.0:
		_fuel_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.12))
	else:
		_fuel_label.add_theme_color_override("font_color", Color(0.4, 0.92, 0.4))
	_fuel_bar.color = Color(0.86, 0.12, 0.08) if _fuel <= 10.0 else Color(0.95, 0.58, 0.08) if _fuel <= 25.0 else Color(0.2, 0.82, 0.28)


func _show_game_over(title: String) -> void:
	if _eliminated:
		return
	_eliminated = true
	get_tree().paused = false
	_status_panel.visible = true
	_restart_timer = 4.0
	_status_label.text = "%s\n\nDistance  %04d m\nCoins     %04d\nBest      %04d m\nFuel      %03d%%" % [
		title,
		int(maxf(-vehicle.global_position.z, 0.0)),
		_coins_collected,
		int(_best_distance),
		int(_fuel),
	]
	_create_game_over_buttons()


func _create_game_over_buttons() -> void:
	for child in _status_panel.get_children():
		if child != _status_label:
			child.queue_free()
	var restart := Button.new()
	restart.text = "RESTART"
	restart.set_anchors_preset(Control.PRESET_CENTER)
	restart.position = Vector2(-175.0, 90.0)
	restart.size = Vector2(160.0, 52.0)
	restart.pressed.connect(_restart_run)
	_status_panel.add_child(restart)
	var main_menu := Button.new()
	main_menu.text = "MAIN MENU"
	main_menu.set_anchors_preset(Control.PRESET_CENTER)
	main_menu.position = Vector2(15.0, 90.0)
	main_menu.size = Vector2(160.0, 52.0)
	main_menu.pressed.connect(_return_to_main_menu)
	_status_panel.add_child(main_menu)


func _return_to_main_menu() -> void:
	get_tree().reload_current_scene()


func _on_touch_accelerator_changed(value: float) -> void:
	vehicle.set_touch_controls(value, vehicle.touch_brake)


func _on_touch_brake_changed(value: float) -> void:
	vehicle.set_touch_controls(vehicle.touch_accelerate, value)


func _on_fuel_collected(amount: float) -> void:
	_fuel = minf(_fuel + amount, 100.0)
	if is_instance_valid(_game_hud) and _game_hud.has_method("show_fuel_pickup"):
		_game_hud.call("show_fuel_pickup", amount)
	_update_fuel_hud()


func _on_coin_collected(value: int) -> void:
	_coins_collected += value
	profile.coins += value
	profile.save_profile()
	if is_instance_valid(_game_hud) and _game_hud.has_method("show_coin_pickup"):
		_game_hud.call("show_coin_pickup", value)
	if is_instance_valid(_coin_label):
		_coin_label.text = "◆  %04d COINS  +%d" % [_coins_collected, value]


func _on_stunt_completed(flips: int, airtime: float) -> void:
	var stunt_reward := flips * 500
	_coins_collected += stunt_reward
	profile.coins += stunt_reward
	profile.save_profile()
	if is_instance_valid(_coin_label):
		_coin_label.text = "◆  %04d COINS  STUNT +%d" % [_coins_collected, stunt_reward]
