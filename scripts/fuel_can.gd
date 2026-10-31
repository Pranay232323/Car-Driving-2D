extends Area3D
class_name FuelCan

signal collected(amount: float)

@export var fuel_amount := 35.0
@export var bob_height := 0.08
@export var bob_speed := 2.4
@export var rotation_speed := 1.8
@export var pickup_radius := 1.05

var _base_y := 0.0
var _phase := 0.0
var _elapsed := 0.0
var _collected := false
var _visual: Node3D
var _collection_shape: CollisionShape3D


func _ready() -> void:
	_base_y = position.y
	_phase = float(get_instance_id() % 13) * 0.37
	_visual = get_node_or_null("FuelVisual") as Node3D
	_collection_shape = get_node_or_null("CollectionShape") as CollisionShape3D
	if _collection_shape and _collection_shape.shape is SphereShape3D:
		(_collection_shape.shape as SphereShape3D).radius = pickup_radius
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_elapsed += delta
	rotate_y(delta * rotation_speed)
	position.y = _base_y + sin(_elapsed * bob_speed + _phase) * bob_height
	var pulse := 1.0 + sin(_elapsed * 3.2 + _phase) * 0.045
	if _visual:
		_visual.scale = Vector3.ONE * pulse


func _physics_process(_delta: float) -> void:
	if _collected:
		return
	for body in get_overlapping_bodies():
		if body is VehicleController:
			_collect()
			return


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body is VehicleController:
		return
	_collect()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	set_deferred("monitoring", false)
	if _collection_shape:
		_collection_shape.set_deferred("disabled", true)
	collected.emit(fuel_amount)
	var tween := create_tween()
	tween.set_parallel(true)
	if _visual:
		tween.tween_property(_visual, "rotation:y", _visual.rotation.y + TAU * 0.5, 0.18)
		tween.tween_property(_visual, "scale", Vector3.ZERO, 0.18)
	tween.tween_property(self, "position:y", position.y + 0.4, 0.18)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
