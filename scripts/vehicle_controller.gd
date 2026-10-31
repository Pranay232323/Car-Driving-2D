extends RigidBody3D
class_name VehicleController

const WHEEL_RADIUS := 0.4
const WHEEL_REST_LENGTH := 0.52
const SUSPENSION_RAY_EXTRA := 0.18
const TIRE_FRICTION := 1.2
const TIRE_SLIP_STIFFNESS := 1800.0
const WHEEL_INERTIA := 2.5
const ENGINE_TORQUE := 1200.0
const BRAKE_TORQUE := 3200.0
const AIR_PITCH_TORQUE := 2200.0
const AIR_PITCH_STABILIZATION := 420.0
const MAX_AIR_PITCH_SPEED := 6.8
const MAX_AIR_PITCH_ANGLE := 12.0
const NITRO_FORCE := 2400.0
const NITRO_CAPACITY := 100.0
const NITRO_DRAIN_RATE := 30.0
const NITRO_RECHARGE_RATE := 5.0

@export var wheel_track := 0.88
@export var axle_spacing := 1.05
@export_group("Suspension")
@export_range(12000.0, 30000.0, 500.0) var rear_spring_rate := 21000.0
@export_range(12000.0, 30000.0, 500.0) var front_spring_rate := 19000.0
@export_range(1000.0, 5000.0, 100.0) var rear_compression_damping := 2600.0
@export_range(1000.0, 5000.0, 100.0) var front_compression_damping := 2400.0
@export_range(1000.0, 6000.0, 100.0) var rear_rebound_damping := 3600.0
@export_range(1000.0, 6000.0, 100.0) var front_rebound_damping := 3200.0
@export_range(12000.0, 24000.0, 500.0) var max_suspension_force := 18000.0
@export_range(0.0, 100000.0, 1000.0) var bump_stop_rate := 50000.0

var _starting_transform: Transform3D
var _wheels: Array[Dictionary] = []
var throttle_input := 0.0
var brake_input := 0.0
var pitch_input := 0.0
var applied_engine_torque := 0.0
var applied_drive_force := 0.0
var _reset_requested := false
var air_time := 0.0
var air_rotation := 0.0
var completed_flips := 0
var nitro_amount := NITRO_CAPACITY
var nitro_active := false
var engine_rpm := 900.0
var fuel_depleted := false
var touch_accelerate := 0.0
var touch_brake := 0.0
var _was_airborne := false
var _stunt_air_time := 0.0
var _stunt_rotation := 0.0

signal stunt_completed(flips: int, airtime: float)


func request_reset() -> void:
	_reset_requested = true


func set_fuel_depleted(depleted: bool) -> void:
	fuel_depleted = depleted


func set_touch_controls(accelerate: float, brake: float) -> void:
	touch_accelerate = clampf(accelerate, 0.0, 1.0)
	touch_brake = clampf(brake, 0.0, 1.0)


func _ready() -> void:
	_starting_transform = global_transform
	can_sleep = false
	_wheels = [
		_make_wheel(
			Vector3(0.0, -0.1, axle_spacing),
			$RearWheelNear,
			$RearWheelFar,
			$RearSuspensionNear,
			$RearSuspensionFar,
			true
		),
		_make_wheel(
			Vector3(0.0, -0.1, -axle_spacing),
			$FrontWheelNear,
			$FrontWheelFar,
			$FrontSuspensionNear,
			$FrontSuspensionFar,
			false
		),
	]


func _make_wheel(
	anchor: Vector3,
	near_visual: Node3D,
	far_visual: Node3D,
	near_suspension: MeshInstance3D,
	far_suspension: MeshInstance3D,
	driven: bool
) -> Dictionary:
	var ray_query := PhysicsRayQueryParameters3D.create(
		Vector3.ZERO,
		Vector3.DOWN,
		collision_mask,
		[get_rid()]
	)
	ray_query.collide_with_bodies = true
	ray_query.collide_with_areas = false
	return {
		"anchor": anchor,
		"near_visual": near_visual,
		"far_visual": far_visual,
		"near_suspension": near_suspension,
		"far_suspension": far_suspension,
		"driven": driven,
		"spring_rate": rear_spring_rate if driven else front_spring_rate,
		"compression_damping": rear_compression_damping if driven else front_compression_damping,
		"rebound_damping": rear_rebound_damping if driven else front_rebound_damping,
		"query": ray_query,
		"in_contact": false,
		"compression": 0.0,
		"spring_length": WHEEL_REST_LENGTH,
		"previous_spring_length": WHEEL_REST_LENGTH,
		"wheel_position": anchor + Vector3.DOWN * WHEEL_REST_LENGTH,
		"previous_wheel_position": anchor + Vector3.DOWN * WHEEL_REST_LENGTH,
		"visual_wheel_position": anchor + Vector3.DOWN * WHEEL_REST_LENGTH,
		"contact_position": Vector3.ZERO,
		"spin": 0.0,
		"previous_spin": 0.0,
		"angular_speed": 0.0,
		"debug_visual": $RearContactDebug if driven else $FrontContactDebug,
	}


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if Input.is_action_just_pressed("vehicle_reset") or _reset_requested:
		_reset_requested = false
		state.transform = _starting_transform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		state.sleeping = false
		throttle_input = 0.0
		brake_input = 0.0
		pitch_input = 0.0
		applied_engine_torque = 0.0
		applied_drive_force = 0.0
		nitro_active = false
		engine_rpm = 900.0
		fuel_depleted = false
		touch_accelerate = 0.0
		touch_brake = 0.0
		air_time = 0.0
		air_rotation = 0.0
		_was_airborne = false
		_stunt_air_time = 0.0
		_stunt_rotation = 0.0
		for wheel: Dictionary in _wheels:
			wheel["in_contact"] = false
			wheel["compression"] = 0.0
			wheel["spring_length"] = WHEEL_REST_LENGTH
			wheel["previous_spring_length"] = WHEEL_REST_LENGTH
			wheel["angular_speed"] = 0.0
			wheel["spin"] = 0.0
			wheel["previous_spin"] = 0.0
			wheel["wheel_position"] = wheel["anchor"] + Vector3.DOWN * WHEEL_REST_LENGTH
			wheel["previous_wheel_position"] = wheel["wheel_position"]
			wheel["visual_wheel_position"] = wheel["wheel_position"]
		return

	var delta := state.step
	var basis := state.transform.basis.orthonormalized()
	var forward := -basis.z
	var suspension_down := -basis.y
	var throttle := maxf(Input.get_action_strength("vehicle_accelerate"), touch_accelerate)
	throttle -= Input.get_action_strength("vehicle_reverse")
	if fuel_depleted:
		throttle = 0.0
	var brake := maxf(Input.get_action_strength("vehicle_brake"), touch_brake)
	pitch_input = Input.get_axis("vehicle_pitch_backward", "vehicle_pitch_forward")
	nitro_active = Input.is_action_pressed("vehicle_nitro") and throttle > 0.05 and nitro_amount > 0.0
	if nitro_active:
		nitro_amount = maxf(nitro_amount - NITRO_DRAIN_RATE * delta, 0.0)
	else:
		nitro_amount = minf(nitro_amount + NITRO_RECHARGE_RATE * delta, NITRO_CAPACITY)
	throttle_input = throttle
	brake_input = brake
	applied_engine_torque = 0.0
	applied_drive_force = 0.0
	if nitro_active:
		state.apply_force(forward * NITRO_FORCE)
	var grounded_wheels := 0
	var space_state := get_world_3d().direct_space_state

	for wheel: Dictionary in _wheels:
		var anchor: Vector3 = wheel["anchor"]
		var ray_origin := state.transform * anchor
		var ray_end := ray_origin + suspension_down * (
			WHEEL_REST_LENGTH + WHEEL_RADIUS + SUSPENSION_RAY_EXTRA
		)
		var query: PhysicsRayQueryParameters3D = wheel["query"]
		query.from = ray_origin
		query.to = ray_end
		var hit := space_state.intersect_ray(query)
		var contact_force := 0.0
		var wheel_position := anchor + Vector3.DOWN * WHEEL_REST_LENGTH
		var longitudinal_speed := state.linear_velocity.dot(forward)
		var contact_normal := Vector3.UP
		var contact_point := ray_end
		var contact_local := Vector3.ZERO
		var in_contact := not hit.is_empty()

		if in_contact:
			grounded_wheels += 1
			contact_point = hit["position"]
			contact_normal = hit["normal"].normalized()
			var ray_distance := (contact_point - ray_origin).dot(suspension_down)
			var spring_length: float = clampf(ray_distance - WHEEL_RADIUS, 0.0, WHEEL_REST_LENGTH)
			var compression := WHEEL_REST_LENGTH - spring_length
			contact_local = basis.inverse() * (contact_point - state.transform.origin)
			var local_contact := contact_local
			var point_velocity := state.get_velocity_at_local_position(local_contact)
			var suspension_velocity := point_velocity.dot(-suspension_down)
			var damping := (
				float(wheel["rebound_damping"])
				if suspension_velocity > 0.0
				else float(wheel["compression_damping"])
			)
			contact_force = compression * float(wheel["spring_rate"]) - suspension_velocity * damping
			var bump_stop_start := WHEEL_REST_LENGTH * 0.82
			var bump_stop_compression := maxf(compression - bump_stop_start, 0.0)
			contact_force += bump_stop_compression * bump_stop_compression * bump_stop_rate
			contact_force = clampf(contact_force, 0.0, max_suspension_force)
			state.apply_force(contact_normal * contact_force, contact_point - state.transform.origin)
			wheel_position = anchor + Vector3.DOWN * spring_length
			longitudinal_speed = point_velocity.dot(forward.slide(contact_normal).normalized())
			wheel["compression"] = compression
			wheel["spring_length"] = spring_length
		else:
			wheel["compression"] = 0.0
			wheel["spring_length"] = WHEEL_REST_LENGTH

		wheel["in_contact"] = in_contact
		wheel["previous_wheel_position"] = wheel["wheel_position"]
		wheel["previous_spring_length"] = wheel["spring_length"]
		wheel["previous_spin"] = wheel["spin"]
		wheel["wheel_position"] = wheel_position
		wheel["contact_position"] = contact_local

		var tire_forward := forward.slide(contact_normal).normalized()
		if tire_forward.length_squared() < 0.001:
			tire_forward = forward
		var angular_speed: float = wheel["angular_speed"]
		var drive_torque := ENGINE_TORQUE * throttle if wheel["driven"] else 0.0
		var tire_force := 0.0
		var braking_torque := brake * BRAKE_TORQUE
		if wheel["driven"]:
			applied_engine_torque = drive_torque

		if in_contact:
			var slip_speed := angular_speed * WHEEL_RADIUS - longitudinal_speed
			var traction_limit := contact_force * TIRE_FRICTION
			tire_force = clampf(slip_speed * TIRE_SLIP_STIFFNESS, -traction_limit, traction_limit)
			var max_brake_force := braking_torque / WHEEL_RADIUS
			var brake_force := clampf(-longitudinal_speed * 1800.0, -max_brake_force, max_brake_force)
			tire_force += clampf(brake_force, -traction_limit - tire_force, traction_limit - tire_force)
			state.apply_force(tire_forward * tire_force, contact_point - state.transform.origin)
			if wheel["driven"]:
				applied_drive_force = tire_force
			angular_speed += (drive_torque - tire_force * WHEEL_RADIUS - signf(angular_speed) * braking_torque) / WHEEL_INERTIA * delta
		else:
			angular_speed += (drive_torque - signf(angular_speed) * braking_torque) / WHEEL_INERTIA * delta
			if is_zero_approx(drive_torque) and is_zero_approx(braking_torque):
				angular_speed *= exp(-delta * 1.5)

		wheel["angular_speed"] = angular_speed
		if (
			in_contact
			and absf(longitudinal_speed) < 0.12
			and is_zero_approx(drive_torque)
			and is_zero_approx(braking_torque)
		):
			angular_speed = 0.0
			wheel["angular_speed"] = 0.0
		wheel["spin"] = float(wheel["spin"]) + angular_speed * delta

	var driven_wheel_speed := absf(float(_wheels[0]["angular_speed"]))
	var target_rpm := clampf(900.0 + driven_wheel_speed * 60.0 / TAU * 4.2 + absf(throttle) * 950.0, 900.0, 8000.0)
	engine_rpm = lerpf(engine_rpm, target_rpm, 1.0 - exp(-10.0 * delta))

	if grounded_wheels == 0:
		air_time += delta
		_stunt_air_time += delta
		_stunt_rotation += state.angular_velocity.x * delta
		air_rotation = _stunt_rotation
		_was_airborne = true
		var pitch_speed := state.angular_velocity.x
		var pitch_angle := wrapf(state.transform.basis.get_euler().x, -PI, PI)
		var can_rotate_forward := pitch_input <= 0.0 or pitch_angle < MAX_AIR_PITCH_ANGLE
		var can_rotate_backward := pitch_input >= 0.0 or pitch_angle > -MAX_AIR_PITCH_ANGLE
		var air_control := pitch_input
		if not is_zero_approx(air_control):
			var control_limit := MAX_AIR_PITCH_SPEED if signf(air_control) == signf(pitch_speed) else MAX_AIR_PITCH_SPEED * 1.35
			if absf(pitch_speed) < control_limit and can_rotate_forward and can_rotate_backward:
				state.apply_torque(Vector3.RIGHT * air_control * AIR_PITCH_TORQUE)
		else:
			state.apply_torque(Vector3.RIGHT * -pitch_speed * AIR_PITCH_STABILIZATION)
	elif grounded_wheels == 1:
		state.apply_torque(Vector3.RIGHT * pitch_input * AIR_PITCH_TORQUE * 0.12)
	if grounded_wheels > 0 and _was_airborne:
		var flips := int(floor(absf(_stunt_rotation) / TAU))
		if flips > 0:
			completed_flips += flips
			stunt_completed.emit(flips, _stunt_air_time)
		air_time = 0.0
		air_rotation = 0.0
		_stunt_air_time = 0.0
		_stunt_rotation = 0.0
		_was_airborne = false
	if grounded_wheels < 2:
		var angular_velocity := state.angular_velocity
		angular_velocity.x = clampf(angular_velocity.x, -MAX_AIR_PITCH_SPEED, MAX_AIR_PITCH_SPEED)
		state.angular_velocity = angular_velocity


func _process(_delta: float) -> void:
	var interpolation := Engine.get_physics_interpolation_fraction()
	var visual_follow := 1.0 - exp(-18.0 * _delta)
	for wheel: Dictionary in _wheels:
		var physics_wheel_position: Vector3 = wheel["previous_wheel_position"].lerp(
			wheel["wheel_position"],
			interpolation
		)
		var wheel_position: Vector3 = wheel["visual_wheel_position"].lerp(
			physics_wheel_position,
			visual_follow
		)
		wheel["visual_wheel_position"] = wheel_position
		var spin: float = lerpf(wheel["previous_spin"], wheel["spin"], interpolation)
		var spring_length: float = lerpf(
			wheel["previous_spring_length"],
			wheel["spring_length"],
			interpolation
		)
		var near_visual: Node3D = wheel["near_visual"]
		var far_visual: Node3D = wheel["far_visual"]
		var anchor: Vector3 = wheel["anchor"]
		near_visual.position = Vector3(wheel_track, wheel_position.y, wheel_position.z)
		far_visual.position = Vector3(-wheel_track, wheel_position.y, wheel_position.z)
		near_visual.rotation = Vector3(spin, 0.0, 0.0)
		far_visual.rotation = Vector3(spin, 0.0, 0.0)
		var near_suspension: MeshInstance3D = wheel["near_suspension"]
		var far_suspension: MeshInstance3D = wheel["far_suspension"]
		near_suspension.position = Vector3(
			wheel_track,
			anchor.y - spring_length * 0.5,
			anchor.z
		)
		far_suspension.position = Vector3(
			-wheel_track,
			anchor.y - spring_length * 0.5,
			anchor.z
		)
		near_suspension.scale.y = spring_length
		far_suspension.scale.y = spring_length
		var debug_visual: MeshInstance3D = wheel["debug_visual"]
		debug_visual.visible = wheel["in_contact"]
		if debug_visual.visible:
			debug_visual.position = wheel["contact_position"]
