extends Control
class_name GameHud

var distance := 0
var best_distance := 0
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
var _fuel_display := 100.0
var _nitro_display := 100.0
var _rpm_display := 900.0
var _speed_display := 0.0
var _coins_display := 0.0
var _coin_flash := 0.0
var _coin_flash_value := 0
var _fuel_flash := 0.0
var _fuel_flash_amount := 0.0
var _touches: Dictionary = {}

const GOLD := Color(1.0, 0.78, 0.22)
const CYAN := Color(0.2, 0.86, 1.0)
const GRAPHITE := Color(0.035, 0.05, 0.065, 0.94)
const PANEL_EDGE := Color(0.28, 0.42, 0.5, 0.9)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	queue_redraw()


func show_fuel_pickup(amount: float) -> void:
	_fuel_flash = 1.0
	_fuel_flash_amount = amount
	queue_redraw()


func show_coin_pickup(value: int) -> void:
	_coin_flash = 1.0
	_coin_flash_value = value
	queue_redraw()


func _process(delta: float) -> void:
	_fuel_display = lerpf(_fuel_display, fuel, 1.0 - exp(-8.0 * delta))
	_nitro_display = lerpf(_nitro_display, nitro, 1.0 - exp(-9.0 * delta))
	_rpm_display = lerpf(_rpm_display, rpm, 1.0 - exp(-12.0 * delta))
	_speed_display = lerpf(_speed_display, speed, 1.0 - exp(-10.0 * delta))
	_fuel_flash = maxf(_fuel_flash - delta * 1.8, 0.0)
	if _coins_display != float(coins):
		_coins_display = lerpf(_coins_display, float(coins), 1.0 - exp(-16.0 * delta))
		_coin_flash = minf(_coin_flash + delta * 5.0, 1.0)
	else:
		_coin_flash = maxf(_coin_flash - delta * 3.0, 0.0)
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
	var scale_factor := _ui_scale()
	var logical_size := size / scale_factor
	var brake_rect := Rect2(Vector2(24.0, logical_size.y - 172.0), Vector2(168.0, 116.0))
	var gas_rect := Rect2(Vector2(logical_size.x - 192.0, logical_size.y - 172.0), Vector2(168.0, 116.0))
	var accelerator := 0.0
	var brake_value := 0.0
	for raw_position: Vector2 in _touches.values():
		var position := raw_position / scale_factor
		if gas_rect.has_point(position):
			accelerator = 1.0
		if brake_rect.has_point(position):
			brake_value = 1.0
	accelerator_changed.emit(accelerator)
	brake_changed.emit(brake_value)


func _ui_scale() -> float:
	return clampf(minf(size.x / 1280.0, size.y / 720.0), 0.72, 1.35)


func _draw() -> void:
	var scale_factor := _ui_scale()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_factor, scale_factor))
	var viewport_size := size / scale_factor
	_draw_top_bar(viewport_size)
	_draw_dashboard(viewport_size)
	_draw_pedal(Vector2(108.0, viewport_size.y - 114.0), "BRAKE", brake > 0.01, Color(1.0, 0.28, 0.2))
	_draw_pedal(Vector2(viewport_size.x - 108.0, viewport_size.y - 114.0), "ACCELERATE", throttle > 0.01, Color(0.35, 1.0, 0.5))


func _draw_top_bar(viewport_size: Vector2) -> void:
	_draw_status_stack(Vector2(42.0, 42.0))
	_draw_resource_stack(Vector2(viewport_size.x - 330.0, 42.0))


func _draw_distance(origin: Vector2) -> void:
	var route_icon := PackedVector2Array([
		origin + Vector2(0, 17),
		origin + Vector2(10, 5),
		origin + Vector2(17, 13),
		origin + Vector2(27, 0),
	])
	draw_polyline(route_icon, Color(0.95, 0.98, 1.0), 4.0, true)
	draw_circle(origin + Vector2(0, 17), 3.0, GOLD)
	draw_circle(origin + Vector2(27, 0), 3.0, Color(0.95, 0.98, 1.0))
	draw_string(_font, origin + Vector2(30, 2), "DISTANCE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.58, 0.7, 0.75))
	draw_string(_font, origin + Vector2(30, 34), "%04d m" % distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.96, 0.98, 1.0))


func _draw_status_stack(origin: Vector2) -> void:
	_draw_soft_shadow(Rect2(origin - Vector2(20, 25), Vector2(260, 182)))
	_draw_distance(origin)
	_draw_coin(origin + Vector2(7, 63), int(round(_coins_display)))
	_draw_trophy(origin + Vector2(8, 118))
	draw_string(_font, origin + Vector2(30, 113), "BEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.76, 0.18))
	draw_string(_font, origin + Vector2(72, 113), "%04d m" % best_distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.94, 0.98, 1.0))
	_draw_score_badge(origin + Vector2(11, 146))
	draw_string(_font, origin + Vector2(30, 141), "SCORE  %07d" % (distance * 10 + coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.68, 0.8, 0.84))


func _draw_coin(origin: Vector2, value: int) -> void:
	var radius := 17.0 + _coin_flash * 3.0
	draw_circle(origin, radius + 4.0, Color(1.0, 0.6, 0.08, 0.12))
	draw_circle(origin + Vector2(2, 3), radius, Color(0.62, 0.3, 0.03, 0.85))
	draw_circle(origin, radius, GOLD)
	draw_arc(origin, radius - 4.0, 0.0, TAU, 24, Color(0.95, 0.45, 0.05), 2.0)
	draw_arc(origin, radius - 8.0, 0.0, TAU, 24, Color(1.0, 0.94, 0.5), 2.0)
	draw_string(_font, origin + Vector2(-5, 7), "C", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.55, 0.28, 0.02))
	draw_string(_font, origin + Vector2(29, -3), "COINS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.58, 0.7, 0.75))
	draw_string(_font, origin + Vector2(29, 29), "%06d" % value, HORIZONTAL_ALIGNMENT_LEFT, -1, 25 + _coin_flash * 3.0, GOLD)
	if _coin_flash > 0.0:
		draw_string(
			_font,
			origin + Vector2(126, 8),
			"+%d" % _coin_flash_value,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color(1.0, 0.9, 0.45, _coin_flash)
		)


func _draw_trophy(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-8, -5), Vector2(16, 12)), GOLD)
	draw_arc(center + Vector2(-8, 0), 7.0, PI * 0.5, PI * 1.5, 12, GOLD, 3.0)
	draw_arc(center + Vector2(8, 0), 7.0, -PI * 0.5, PI * 0.5, 12, GOLD, 3.0)
	draw_line(center + Vector2(0, 7), center + Vector2(0, 14), GOLD, 3.0)
	draw_line(center + Vector2(-9, 16), center + Vector2(9, 16), GOLD, 3.0)


func _draw_score_badge(center: Vector2) -> void:
	draw_circle(center, 8.0, Color(0.18, 0.72, 0.82))
	draw_line(center + Vector2(-4, 0), center + Vector2(4, 0), Color(0.02, 0.1, 0.13), 2.0)
	draw_line(center + Vector2(0, -4), center + Vector2(0, 4), Color(0.02, 0.1, 0.13), 2.0)


func _draw_resource_stack(origin: Vector2) -> void:
	_draw_soft_shadow(Rect2(origin - Vector2(30, 25), Vector2(340, 116)))
	_draw_fuel(origin)
	_draw_nitro(origin + Vector2(0, 51))


func _draw_score(origin: Vector2, width: float) -> void:
	var score := distance * 10 + coins
	draw_string(_font, origin, "RUN SCORE", HORIZONTAL_ALIGNMENT_LEFT, int(width), 12, Color(0.58, 0.7, 0.75))
	draw_string(_font, origin + Vector2(0, 34), "%07d" % score, HORIZONTAL_ALIGNMENT_LEFT, int(width), 27, GOLD)
	draw_string(_font, origin + Vector2(0, 57), "BEST  %04d m" % distance, HORIZONTAL_ALIGNMENT_LEFT, int(width), 11, Color(0.45, 0.62, 0.68))


func _draw_fuel(origin: Vector2) -> void:
	var warning := fuel <= 10.0
	var bar_color := Color(0.28, 0.95, 0.35) if fuel > 25.0 else Color(1.0, 0.65, 0.12) if fuel > 10.0 else Color(1.0, 0.18, 0.12)
	if _fuel_flash > 0.0:
		var flash_alpha := _fuel_flash * 0.22
		draw_style_box(
			_rounded_box(Color(0.2, 0.95, 0.45, flash_alpha), Color(0.35, 1.0, 0.55, flash_alpha + 0.18), 8),
			Rect2(origin + Vector2(-24, -6), Vector2(305, 58))
		)
	_draw_fuel_icon(origin + Vector2(-15, 16), bar_color)
	draw_string(_font, origin + Vector2(10, 4), "FUEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, bar_color)
	var bar := Rect2(origin + Vector2(10, 11), Vector2(220.0, 15.0))
	_draw_glass(bar, Color(0.015, 0.025, 0.03, 0.95), Color(0.2, 0.3, 0.33))
	draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2(214.0 * clampf(_fuel_display / 100.0, 0.0, 1.0), 9),), bar_color)
	draw_string(_font, origin + Vector2(240, 23), "%03d%%" % _display_percent(_fuel_display, fuel), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.94, 0.98, 1.0))
	if fuel <= 5.0:
		var alpha := 0.55 + 0.45 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008))
		draw_string(_font, origin + Vector2(0, 42), "CRITICAL FUEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.18, 0.12, alpha))
	elif fuel <= 10.0:
		draw_string(_font, origin + Vector2(0, 42), "CRITICAL FUEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.18, 0.12))
	elif fuel <= 25.0:
		draw_string(_font, origin + Vector2(0, 42), "LOW FUEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.65, 0.12))
	if _fuel_flash > 0.0:
		draw_string(
			_font,
			origin + Vector2(170, 42),
			"+%d%%" % int(round(_fuel_flash_amount)),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color(0.55, 1.0, 0.68, _fuel_flash)
		)
	if warning:
		draw_circle(origin + Vector2(-14, 17), 3.0, bar_color)


func _draw_nitro(origin: Vector2) -> void:
	_draw_lightning_icon(origin + Vector2(-15, 16))
	draw_string(_font, origin + Vector2(10, 4), "NITRO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CYAN)
	var bar := Rect2(origin + Vector2(10, 11), Vector2(220.0, 15.0))
	_draw_glass(bar, Color(0.015, 0.025, 0.03, 0.95), Color(0.15, 0.42, 0.5))
	draw_rect(Rect2(bar.position + Vector2(3, 3), Vector2(214.0 * clampf(_nitro_display / 100.0, 0.0, 1.0), 9),), CYAN)
	draw_string(_font, origin + Vector2(240, 23), "%03d%%" % _display_percent(_nitro_display, nitro), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.94, 0.98, 1.0))


func _draw_fuel_icon(center: Vector2, color: Color) -> void:
	draw_style_box(_rounded_box(Color(0.12, 0.14, 0.15, 1.0), color, 3), Rect2(center - Vector2(8, 11), Vector2(16, 22)))
	draw_rect(Rect2(center + Vector2(3, -9), Vector2(7, 4)), color)
	draw_line(center + Vector2(8, -7), center + Vector2(13, -2), color, 2.0)
	draw_line(center + Vector2(13, -2), center + Vector2(13, 5), color, 2.0)
	draw_string(_font, center + Vector2(-4, 5), "F", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)


func _draw_lightning_icon(center: Vector2) -> void:
	var bolt := PackedVector2Array([
		center + Vector2(4, -13),
		center + Vector2(-7, 1),
		center + Vector2(0, 1),
		center + Vector2(-4, 13),
		center + Vector2(8, -3),
		center + Vector2(1, -3),
	])
	draw_colored_polygon(bolt, CYAN)
	draw_polyline(bolt, Color(0.65, 0.96, 1.0), 1.5, true)


func _draw_dashboard(viewport_size: Vector2) -> void:
	var baseline := viewport_size.y - 108.0
	var gauge_radius := clampf(viewport_size.y * 0.105, 62.0, 82.0)
	_draw_gauge(Vector2(viewport_size.x * 0.39, baseline), gauge_radius, _rpm_display, 8000.0, "RPM", Color(1.0, 0.3, 0.2))
	_draw_speedometer(Vector2(viewport_size.x * 0.5, baseline), gauge_radius)
	_draw_gauge(Vector2(viewport_size.x * 0.61, baseline), gauge_radius, _nitro_display, 100.0, "BOOST", CYAN)


func _draw_speedometer(center: Vector2, radius: float) -> void:
	_draw_instrument_shell(center, radius, CYAN)
	for tick in range(12):
		var angle := TAU * float(tick) / 12.0 - PI * 0.5
		var inner := center + Vector2(cos(angle), sin(angle)) * (radius - 18.0)
		var outer := center + Vector2(cos(angle), sin(angle)) * (radius - 7.0)
		draw_line(inner, outer, CYAN, 2.0 if tick % 3 else 3.0)
		var label_position := center + Vector2(cos(angle), sin(angle)) * (radius - 32.0)
		draw_string(_font, label_position + Vector2(-7, 5), "%d" % (tick * 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.88, 0.92))
	var speed_text := "%02d" % int(round(_speed_display))
	draw_string(_font, center + Vector2(-38, 9), speed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.96, 0.99, 1.0))
	draw_string(_font, center + Vector2(25, 8), "km/h", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CYAN)
	draw_string(_font, center + Vector2(-22, 33), "SPEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.58, 0.72, 0.76))


func _draw_gauge(center: Vector2, radius: float, value: float, maximum: float, label: String, accent: Color) -> void:
	_draw_instrument_shell(center, radius, accent)
	var fraction := clampf(value / maximum, 0.0, 1.0)
	draw_arc(center, radius - 5.0, PI * 0.74, PI * 2.26, 48, Color(0.3, 0.35, 0.37), 3.0)
	draw_arc(center, radius - 5.0, PI * 0.74, PI * (0.74 + 1.52 * fraction), 48, accent, 5.0)
	for tick in range(17):
		var angle := PI * (0.74 + 1.52 * float(tick) / 16.0)
		var inner := center + Vector2(cos(angle), sin(angle)) * (radius - 20.0)
		var outer := center + Vector2(cos(angle), sin(angle)) * (radius - 7.0)
		var tick_color := Color(1.0, 0.22, 0.12) if tick > 13 and label == "RPM" else Color(0.82, 0.88, 0.88)
		draw_line(inner, outer, tick_color, 2.0 if tick % 4 else 3.0)
		if tick % 4 == 0:
			var number_position := center + Vector2(cos(angle), sin(angle)) * (radius - 34.0)
			var number := "%d" % (tick / 2 if label == "RPM" else tick * 6)
			draw_string(_font, number_position + Vector2(-6, 4), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.78, 0.86, 0.88))
	var needle_angle := PI * (0.74 + 1.52 * fraction)
	draw_line(center, center + Vector2(cos(needle_angle), sin(needle_angle)) * (radius - 24.0), Color(1.0, 0.95, 0.82), 4.0)
	draw_circle(center, 8.0, Color(0.12, 0.15, 0.17))
	draw_circle(center, 4.0, accent)
	draw_string(_font, center + Vector2(-22, 40), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, accent)


func _draw_instrument_shell(center: Vector2, radius: float, accent: Color) -> void:
	draw_circle(center, radius + 13.0, Color(0.0, 0.0, 0.0, 0.42))
	draw_circle(center, radius + 9.0, Color(0.08, 0.11, 0.13, 1.0))
	draw_arc(center, radius + 7.0, 0.0, TAU, 64, Color(0.38, 0.52, 0.57), 2.0)
	draw_circle(center, radius + 2.0, Color(0.02, 0.035, 0.045, 1.0))
	draw_circle(center, radius - 3.0, Color(0.025, 0.045, 0.06, 1.0))
	draw_arc(center, radius - 6.0, 0.0, TAU, 64, Color(accent, 0.22), 3.0)


func _draw_pedal(center: Vector2, title: String, active: bool, accent: Color) -> void:
	var offset := Vector2(0, 6) if active else Vector2.ZERO
	var rect := Rect2(center - Vector2(84, 54) + offset, Vector2(168, 108))
	draw_style_box(_rounded_box(Color(0.0, 0.0, 0.0, 0.45), Color(0, 0, 0, 0), 12), Rect2(rect.position + Vector2(0, 9), rect.size))
	_draw_glass(rect, Color(0.42, 0.45, 0.45, 0.98) if not active else Color(0.58, 0.6, 0.58, 1.0), accent if active else Color(0.65, 0.7, 0.7))
	draw_line(rect.position + Vector2(10, 12), rect.position + Vector2(rect.size.x - 10, 12), Color(1, 1, 1, 0.38), 3.0)
	for row in range(2):
		for column in range(3):
			var hole := rect.position + Vector2(34.0 + column * 50.0, 33.0 + row * 25.0)
			draw_circle(hole + Vector2(1, 2), 7.0, Color(0.1, 0.12, 0.13, 0.45))
			draw_circle(hole, 5.0, Color(0.09, 0.12, 0.13, 1.0))
	draw_line(rect.position + Vector2(18, 80), rect.position + Vector2(rect.size.x - 18, 80), Color(0.18, 0.22, 0.23), 3.0)
	draw_string(_font, center + Vector2(-45, 97) + offset, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.82, 0.9, 0.92))


func _display_percent(display_value: float, source_value: float) -> int:
	if source_value >= 99.5:
		return 100
	return clampi(int(round(display_value)), 0, 100)


func _draw_divider(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, Color(0.25, 0.38, 0.42, 0.65), 1.0)


func _draw_soft_shadow(rect: Rect2) -> void:
	draw_style_box(_rounded_box(Color(0.0, 0.0, 0.0, 0.34), Color(0.0, 0.0, 0.0, 0.0), 12), rect)


func _draw_glass(rect: Rect2, fill: Color, edge: Color) -> void:
	draw_style_box(_rounded_box(fill, edge, 9), rect)


func _rounded_box(fill: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
