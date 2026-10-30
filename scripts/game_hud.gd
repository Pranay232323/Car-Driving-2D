extends Control
class_name GameHud

var distance := 0
var coins := 0
var fuel := 100.0
var nitro := 100.0
var rpm := 900.0
var speed := 0.0
var throttle := 0.0
var brake := 0.0

signal accelerator_changed(value: float)
signal brake_changed(value: float)

var _font: Font
var _display_fuel := 100.0
var _display_nitro := 100.0
var _touches: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	queue_redraw()


func _process(delta: float) -> void:
	_display_fuel = lerpf(_display_fuel, fuel, 1.0 - exp(-7.0 * delta))
	_display_nitro = lerpf(_display_nitro, nitro, 1.0 - exp(-9.0 * delta))
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_emit_touch_state()
	elif event is InputEventScreenDrag and _touches.has(event.index):
		_touches[event.index] = event.position
		_emit_touch_state()


func _emit_touch_state() -> void:
	var viewport_size := size
	var brake_rect := Rect2(Vector2(22.0, viewport_size.y - 120.0), Vector2(120.0, 90.0))
	var gas_rect := Rect2(Vector2(viewport_size.x - 142.0, viewport_size.y - 120.0), Vector2(120.0, 90.0))
	var accelerator := 0.0
	var brake_value := 0.0
	for position: Vector2 in _touches.values():
		if gas_rect.has_point(position):
			accelerator = 1.0
		if brake_rect.has_point(position):
			brake_value = 1.0
	accelerator_changed.emit(accelerator)
	brake_changed.emit(brake_value)


func _draw() -> void:
	var viewport_size := size
	_draw_reference_status(viewport_size)
	_draw_gauge(Vector2(viewport_size.x * 0.43, viewport_size.y - 78.0), 54.0, rpm, 8000.0, "RPM", Color(0.9, 0.25, 0.18))
	_draw_gauge(Vector2(viewport_size.x * 0.57, viewport_size.y - 78.0), 54.0, _display_nitro, 100.0, "BOOST", Color(0.95, 0.68, 0.12))
	_draw_pedal(Vector2(82.0, viewport_size.y - 67.0), "BRAKE", brake > 0.01, Color(0.82, 0.14, 0.1))
	_draw_pedal(Vector2(viewport_size.x - 82.0, viewport_size.y - 67.0), "GAS", throttle > 0.01, Color(0.18, 0.5, 0.2))


func _draw_reference_status(viewport_size: Vector2) -> void:
	var panel := Rect2(22.0, 20.0, 300.0, 150.0)
	draw_style_box(_panel(Color(0.015, 0.025, 0.04, 0.78), Color(0.42, 0.56, 0.6, 0.8)), panel)

	draw_string(_font, Vector2(42.0, 53.0), "↗", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(0.95, 0.96, 0.9))
	draw_string(_font, Vector2(78.0, 51.0), "%04d m" % distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(0.94, 0.98, 1.0))
	draw_string(_font, Vector2(205.0, 51.0), "★ %04d" % distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.82, 0.24))

	draw_string(_font, Vector2(40.0, 88.0), "▣", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(0.9, 0.14, 0.08))
	var fuel_bar := Rect2(78.0, 70.0, 205.0, 23.0)
	draw_style_box(_panel(Color(0.05, 0.07, 0.08, 1.0), Color(0.72, 0.78, 0.78, 1.0)), fuel_bar)
	var fuel_color := Color(0.25, 0.92, 0.06) if fuel > 25.0 else Color(1.0, 0.62, 0.08) if fuel > 10.0 else Color(0.94, 0.12, 0.08)
	draw_rect(Rect2(fuel_bar.position + Vector2(4.0, 4.0), Vector2(197.0 * clampf(fuel / 100.0, 0.0, 1.0), 15.0)), fuel_color)
	draw_string(_font, Vector2(143.0, 89.0), "%03d%%" % int(_display_fuel), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

	draw_circle(Vector2(52.0, 126.0), 18.0, Color(1.0, 0.78, 0.08))
	draw_circle(Vector2(52.0, 126.0), 13.0, Color(1.0, 0.55, 0.04))
	draw_string(_font, Vector2(77.0, 134.0), "%06d" % coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.88, 0.32))
	draw_string(_font, Vector2(viewport_size.x - 184.0, 50.0), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.84, 0.88))
	draw_string(_font, Vector2(viewport_size.x - 184.0, 79.0), "%06d" % (distance * 10 + coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(1.0, 0.87, 0.4))
	draw_string(_font, Vector2(viewport_size.x - 184.0, 105.0), "NITRO %03d%%" % int(_display_nitro), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.35, 0.82, 1.0))
	if fuel <= 10.0:
		draw_string(_font, Vector2(78.0, 112.0), "CRITICAL FUEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.18, 0.1))
	elif fuel <= 25.0:
		draw_string(_font, Vector2(78.0, 112.0), "LOW FUEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.66, 0.1))


func _draw_gauge(center: Vector2, radius: float, value: float, maximum: float, title: String, color: Color) -> void:
	draw_circle(center, radius + 7.0, Color(0.02, 0.025, 0.03, 0.94))
	draw_circle(center, radius, Color(0.28, 0.29, 0.29, 1.0))
	draw_arc(center, radius - 2.0, PI * 0.16, PI * 0.84, 40, Color(0.76, 0.76, 0.72), 2.0)
	var fraction := clampf(value / maximum, 0.0, 1.0)
	for tick in range(9):
		var angle := PI * (0.16 + 0.68 * float(tick) / 8.0)
		var inner := center + Vector2(cos(angle), sin(angle)) * (radius - 13.0)
		var outer := center + Vector2(cos(angle), sin(angle)) * (radius - 3.0)
		draw_line(inner, outer, Color(0.45, 0.12, 0.1) if tick > 6 else Color(0.86, 0.86, 0.8), 3.0)
	var needle_angle := PI * (0.16 + 0.68 * fraction)
	draw_line(center, center + Vector2(cos(needle_angle), sin(needle_angle)) * (radius - 16.0), Color(0.08, 0.05, 0.04), 4.0)
	draw_circle(center, 6.0, Color(0.88, 0.9, 0.88))
	draw_string(_font, center + Vector2(-25.0, 31.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)


func _draw_pedal(center: Vector2, title: String, active: bool, color: Color) -> void:
	var press_offset := Vector2(0.0, 5.0) if active else Vector2.ZERO
	var rect := Rect2(center - Vector2(55.0, 30.0) + press_offset, Vector2(110.0, 60.0))
	draw_style_box(_panel(Color(0.64, 0.64, 0.58, 0.96) if active else Color(0.86, 0.84, 0.7, 0.94), Color(0.16, 0.18, 0.18, 1.0)), rect)
	for row in range(2):
		for column in range(3):
			var dot := center - Vector2(30.0, 13.0) + Vector2(column * 30.0, row * 25.0) + press_offset
			draw_circle(dot, 8.0, Color(0.08, 0.08, 0.07, 1.0))
	draw_string(_font, center + Vector2(-27.0, 49.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color if active else Color(0.15, 0.17, 0.17))


func _panel(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
