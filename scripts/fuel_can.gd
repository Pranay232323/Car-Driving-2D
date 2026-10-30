extends Area3D
class_name FuelCan

signal collected(amount: float)

@export var fuel_amount := 35.0
@export var bob_height := 0.08
@export var bob_speed := 2.4

var _base_y := 0.0
var _phase := 0.0
var _collected := false
var _visual: Node3D


func _ready() -> void:
	_base_y = position.y
	_phase = float(get_instance_id() % 13) * 0.37
	_visual = get_node_or_null("FuelVisual") as Node3D
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	rotate_y(delta * 1.8)
	position.y = _base_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed + _phase) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body is VehicleController:
		return
	_collected = true
	set_deferred("monitoring", false)
	collected.emit(fuel_amount)
	var tween := create_tween()
	tween.set_parallel(true)
	if _visual:
		tween.tween_property(_visual, "scale", Vector3.ZERO, 0.18)
	tween.tween_property(self, "position:y", position.y + 0.28, 0.18)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
