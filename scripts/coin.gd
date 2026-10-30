extends Area3D
class_name Coin

signal collected

@export var bob_height := 0.10
@export var bob_speed := 2.8
@export var rotation_speed := 3.2

var _base_y := 0.0
var _phase := 0.0
var _collected := false
var _visual: Node3D


func _ready() -> void:
	_base_y = position.y
	_phase = float(get_instance_id() % 17) * 0.31
	body_entered.connect(_on_body_entered)
	_visual = get_node_or_null("CoinVisual") as Node3D


func _process(delta: float) -> void:
	if _collected:
		return
	rotate_y(rotation_speed * delta)
	position.y = _base_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed + _phase) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body is VehicleController:
		return
	_collected = true
	set_deferred("monitoring", false)
	collected.emit()
	var tween := create_tween()
	tween.set_parallel(true)
	if _visual:
		tween.tween_property(_visual, "scale", Vector3.ZERO, 0.16)
	tween.tween_property(self, "position:y", position.y + 0.32, 0.16)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
