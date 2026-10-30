extends Node3D

@export var camera_follow_speed := 5.0
@export var show_debug_overlay := true

@onready var vehicle: VehicleController = $PlaceholderVehicle
@onready var side_camera: Camera3D = $SideCamera

var _debug_label: Label


func _ready() -> void:
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


func _physics_process(delta: float) -> void:
	var target := vehicle.global_position + Vector3(24.0, 2.8, 0.0)
	var weight := 1.0 - exp(-camera_follow_speed * delta)
	side_camera.global_position = side_camera.global_position.lerp(target, weight)
	if show_debug_overlay:
		var forward_speed := vehicle.linear_velocity.dot(-vehicle.global_transform.basis.z)
		_debug_label.text = (
			"Throttle: %+.1f   Brake: %.1f   Drive torque: %+.0f Nm   Rear traction: %+.0f N\n"
			+ "Speed: %+.2f m/s   Velocity: %s   Distance: %.1f m\n"
			+ "Pitch input: %+.1f   Pitch angle: %+.2f rad   Pitch speed: %+.2f rad/s\n"
			+ "Rear contact: %s (%.2f m)   Front contact: %s (%.2f m)\n"
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
		]
	else:
		_debug_label.visible = false
