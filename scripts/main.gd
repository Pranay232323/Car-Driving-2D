extends Node3D

@export var camera_follow_speed := 5.0

@onready var vehicle: VehicleController = $PlaceholderVehicle
@onready var side_camera: Camera3D = $SideCamera


func _process(delta: float) -> void:
	var target := vehicle.global_position + Vector3(24.0, 2.8, 0.0)
	var weight := 1.0 - exp(-camera_follow_speed * delta)
	side_camera.global_position = side_camera.global_position.lerp(target, weight)
