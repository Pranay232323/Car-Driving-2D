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
signal pause_requested

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
var _mouse_pressed_brake := false
var _mouse_pressed_gas := false
var _pause_rect := Rect2()
var _stunt_banner_timer := 0.0
var _stunt_banner_title := ""
var _stunt_banner_coins := 0
var _stunt_banner_combo := 1

# Modern game UI palette
const COLOR_GOLD := Color(1.0, 0.78, 0.16)
const COLOR_GOLD_LIGHT := Color(1.0, 0.92, 0.45)
const COLOR_GOLD_DARK := Color(0.68, 0.42, 0.04)
const COLOR_CYAN := Color(0.12, 0.88, 1.0)
const COLOR_CYAN_GLOW := Color(0.25, 0.95, 1.0, 0.45)
const COLOR_ORANGE := Color(1.0, 0.58, 0.08)
const COLOR_ORANGE_GLOW := Color(1.0, 0.55, 0.05, 0.4)
const COLOR_RED := Color(1.0, 0.22, 0.18)
const COLOR_RED_GLOW := Color(1.0, 0.18, 0.15, 0.45)
const COLOR_PANEL_BG := Color(0.04, 0.07, 0.10, 0.75)
const COLOR_PANEL_BORDER := Color(0.24, 0.38, 0.48, 0.85)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
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


func show_stunt_banner(title: String, coins_awarded: int, combo: int) -> void:
	_stunt_banner_title = title
	_stunt_banner_coins = coins_awarded
	_stunt_banner_combo = combo
	_stunt_banner_timer = 2.4
	queue_redraw()


func _process(delta: float) -> void:
	_fuel_display = lerpf(_fuel_display, fuel, 1.0 - exp(-8.0 * delta))
	_nitro_display = lerpf(_nitro_display, nitro, 1.0 - exp(-9.0 * delta))
	_rpm_display = lerpf(_rpm_display, rpm, 1.0 - exp(-14.0 * delta))
	_speed_display = lerpf(_speed_display, speed, 1.0 - exp(-12.0 * delta))
	_fuel_flash = maxf(_fuel_flash - delta * 2.0, 0.0)
	_stunt_banner_timer = maxf(_stunt_banner_timer - delta, 0.0)
	if _coins_display != float(coins):
		_coins_display = lerpf(_coins_display, float(coins), 1.0 - exp(-16.0 * delta))
		_coin_flash = minf(_coin_flash + delta * 5.0, 1.0)
	else:
		_coin_flash = maxf(_coin_flash - delta * 3.0, 0.0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	var scale_factor := _ui_scale()
	var logical_size := size / scale_factor
	var brake_rect := Rect2(Vector2(26.0, logical_size.y - 165.0), Vector2(165.0, 140.0))
	var gas_rect := Rect2(Vector2(logical_size.x - 191.0, logical_size.y - 165.0), Vector2(165.0, 140.0))

	# Mouse clicks for desktop
	if event is InputEventMouseButton:
		var pos: Vector2 = event.position / scale_factor
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _pause_rect.has_point(pos):
					pause_requested.emit()
					get_viewport().set_input_as_handled()
					return
				if brake_rect.has_point(pos):
					_mouse_pressed_brake = true
					brake_changed.emit(1.0)
				if gas_rect.has_point(pos):
					_mouse_pressed_gas = true
					accelerator_changed.emit(1.0)
			else:
				if _mouse_pressed_brake:
					_mouse_pressed_brake = false
					brake_changed.emit(0.0)
				if _mouse_pressed_gas:
					_mouse_pressed_gas = false
					accelerator_changed.emit(0.0)

	# Touch events for mobile / touchscreen
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			var pos: Vector2 = event.position / scale_factor
			if _pause_rect.has_point(pos):
				pause_requested.emit()
				_touches.erase(event.index)
				get_viewport().set_input_as_handled()
				return
		else:
			_touches.erase(event.index)
		_emit_touch_state()
	elif event is InputEventScreenDrag and _touches.has(event.index):
		_touches[event.index] = event.position
		_emit_touch_state()


func _emit_touch_state() -> void:
	var scale_factor := _ui_scale()
	var logical_size := size / scale_factor
	var brake_rect := Rect2(Vector2(26.0, logical_size.y - 165.0), Vector2(165.0, 140.0))
	var gas_rect := Rect2(Vector2(logical_size.x - 191.0, logical_size.y - 165.0), Vector2(165.0, 140.0))
	var accelerator := 1.0 if _mouse_pressed_gas else 0.0
	var brake_val := 1.0 if _mouse_pressed_brake else 0.0
	for raw_position: Vector2 in _touches.values():
		var pos: Vector2 = raw_position / scale_factor
		if gas_rect.has_point(pos):
			accelerator = 1.0
		if brake_rect.has_point(pos):
			brake_val = 1.0
	accelerator_changed.emit(accelerator)
	brake_changed.emit(brake_val)


func _ui_scale() -> float:
	return clampf(minf(size.x / 1280.0, size.y / 720.0), 0.72, 1.35)


func _draw() -> void:
	var scale_factor := _ui_scale()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_factor, scale_factor))
	var viewport_size := size / scale_factor

	# 1. Top HUD
	_draw_modern_top_left(Vector2(36.0, 28.0))
	_draw_modern_top_right(viewport_size)
	if _stunt_banner_timer > 0.0:
		_draw_stunt_banner(viewport_size)

	# 2. Bottom Dashboard cluster
	_draw_modern_dashboard(viewport_size)

	# 3. Modern Pedals
	var is_brake_down := brake > 0.01 or _mouse_pressed_brake
	var is_gas_down := throttle > 0.01 or _mouse_pressed_gas
	_draw_modern_pedal(Vector2(108.0, viewport_size.y - 88.0), "BRAKE", is_brake_down, true)
	_draw_modern_pedal(Vector2(viewport_size.x - 108.0, viewport_size.y - 88.0), "ACCELERATE", is_gas_down, false)


# ==========================================
# 1. TOP-LEFT STATS CLUSTER (Matches Reference)
# ==========================================
func _draw_modern_top_left(origin: Vector2) -> void:
	# Row 1: Flag / Road Icon + Distance (e.g. 0684 m)
	_draw_subtle_capsule(origin + Vector2(-6.0, -4.0), Vector2(160.0, 38.0))
	_draw_flag_icon(origin + Vector2(14.0, 15.0))
	draw_string(_font, origin + Vector2(42.0, 23.0), "%04d m" % distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

	# Row 2: Embossed Golden Coin + Coins count (e.g. 00023)
	var coin_origin := origin + Vector2(0.0, 48.0)
	_draw_subtle_capsule(coin_origin + Vector2(-6.0, -4.0), Vector2(175.0, 38.0))
	_draw_embossed_coin(coin_origin + Vector2(14.0, 15.0))
	draw_string(_font, coin_origin + Vector2(42.0, 23.0), "%05d" % int(round(_coins_display)), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, COLOR_GOLD)
	if _coin_flash > 0.0:
		var bonus_text := "+%d" % _coin_flash_value
		var flash_color := Color(1.0, 0.95, 0.45, _coin_flash)
		draw_string(_font, coin_origin + Vector2(140.0, 17.0 - _coin_flash * 6.0), bonus_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, flash_color)

	# Row 3: Golden Trophy + BEST 0520 m
	var trophy_origin := origin + Vector2(0.0, 96.0)
	_draw_subtle_capsule(trophy_origin + Vector2(-6.0, -4.0), Vector2(185.0, 34.0))
	_draw_golden_trophy(trophy_origin + Vector2(14.0, 13.0))
	draw_string(_font, trophy_origin + Vector2(42.0, 19.0), "BEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_GOLD)
	draw_string(_font, trophy_origin + Vector2(82.0, 21.0), "%04d m" % best_distance, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)


func _draw_stunt_banner(viewport_size: Vector2) -> void:
	var alpha := clampf(_stunt_banner_timer * 1.8, 0.0, 1.0)
	var float_offset := (2.4 - _stunt_banner_timer) * 6.0
	var banner_w := 380.0
	var banner_h := 56.0
	var banner_pos := Vector2(viewport_size.x * 0.5 - banner_w * 0.5, 38.0 - float_offset)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.03, 0.06, 0.10, 0.88 * alpha)
	var border_color := (COLOR_ORANGE if _stunt_banner_combo > 1 else COLOR_GOLD)
	border_color.a = alpha
	bg_style.border_color = border_color
	bg_style.set_border_width_all(2)
	bg_style.corner_radius_top_left = 16
	bg_style.corner_radius_top_right = 16
	bg_style.corner_radius_bottom_left = 16
	bg_style.corner_radius_bottom_right = 16
	draw_style_box(bg_style, Rect2(banner_pos, Vector2(banner_w, banner_h)))

	var title_str := ""
	if _stunt_banner_combo > 1:
		title_str = "🔥 %dx %s!" % [_stunt_banner_combo, _stunt_banner_title]
	else:
		title_str = "⚡ %s!" % _stunt_banner_title

	var text_color := (COLOR_ORANGE if _stunt_banner_combo > 1 else COLOR_GOLD_LIGHT)
	text_color.a = alpha
	draw_string(_font, banner_pos + Vector2(22.0, 36.0), title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, text_color)

	var coin_text := "+%d" % _stunt_banner_coins
	var coin_color := COLOR_GOLD
	coin_color.a = alpha
	draw_string(_font, banner_pos + Vector2(banner_w - 110.0, 37.0), coin_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 22, coin_color)
	_draw_embossed_coin(banner_pos + Vector2(banner_w - 24.0, 28.0))


func _draw_subtle_capsule(pos: Vector2, sz: Vector2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.06, 0.62)
	style.border_color = Color(0.35, 0.5, 0.65, 0.3)
	style.set_border_width_all(1)
	style.corner_radius_top_left = int(sz.y * 0.5)
	style.corner_radius_top_right = int(sz.y * 0.5)
	style.corner_radius_bottom_left = int(sz.y * 0.5)
	style.corner_radius_bottom_right = int(sz.y * 0.5)
	draw_style_box(style, Rect2(pos, sz))


func _draw_flag_icon(center: Vector2) -> void:
	# Stylized road / checkered flag badge
	draw_circle(center, 12.0, Color(0.12, 0.16, 0.2, 0.95))
	draw_arc(center, 12.0, 0.0, TAU, 24, COLOR_GOLD, 1.5)
	var pole_top := center + Vector2(-4.0, -8.0)
	var pole_bottom := center + Vector2(-4.0, 8.0)
	draw_line(pole_top, pole_bottom, Color.WHITE, 2.0)
	var flag_pts := PackedVector2Array([
		pole_top,
		center + Vector2(8.0, -4.0),
		center + Vector2(-4.0, 1.0)
	])
	draw_colored_polygon(flag_pts, COLOR_GOLD)


func _draw_embossed_coin(center: Vector2) -> void:
	var radius := 12.0 + _coin_flash * 2.0
	# Outer glow
	draw_circle(center, radius + 3.0, Color(1.0, 0.7, 0.1, 0.25))
	# Rim
	draw_circle(center + Vector2(1.0, 1.5), radius, COLOR_GOLD_DARK)
	draw_circle(center, radius, COLOR_GOLD)
	draw_arc(center, radius - 2.5, 0.0, TAU, 24, COLOR_GOLD_LIGHT, 1.5)
	# Center star / diamond
	var star := PackedVector2Array([
		center + Vector2(0.0, -5.0),
		center + Vector2(3.5, 0.0),
		center + Vector2(0.0, 5.0),
		center + Vector2(-3.5, 0.0),
	])
	draw_colored_polygon(star, COLOR_GOLD_DARK)


func _draw_golden_trophy(center: Vector2) -> void:
	draw_circle(center, 11.0, Color(0.12, 0.16, 0.2, 0.95))
	draw_arc(center, 11.0, 0.0, TAU, 24, COLOR_GOLD, 1.5)
	# Cup
	var cup := PackedVector2Array([
		center + Vector2(-5.0, -6.0),
		center + Vector2(5.0, -6.0),
		center + Vector2(3.5, 1.0),
		center + Vector2(-3.5, 1.0),
	])
	draw_colored_polygon(cup, COLOR_GOLD)
	# Stem & base
	draw_line(center + Vector2(0.0, 1.0), center + Vector2(0.0, 5.0), COLOR_GOLD, 2.0)
	draw_line(center + Vector2(-4.0, 6.0), center + Vector2(4.0, 6.0), COLOR_GOLD, 2.0)


# ==========================================
# 2. TOP-RIGHT BARS (Matches Reference)
# ==========================================
func _draw_modern_top_right(viewport_size: Vector2) -> void:
	var top_right_x := viewport_size.x - 300.0
	var bar_width := 185.0
	var bar_height := 18.0

	# 1. Fuel Row
	var fuel_pos := Vector2(top_right_x, 28.0)
	_draw_subtle_capsule(fuel_pos - Vector2(10.0, 6.0), Vector2(285.0, 36.0))
	_draw_gas_pump_icon(fuel_pos + Vector2(10.0, 12.0), COLOR_ORANGE)
	_draw_capsule_bar(fuel_pos + Vector2(34.0, 3.0), Vector2(bar_width, bar_height), _fuel_display / 100.0, COLOR_ORANGE, COLOR_ORANGE_GLOW)
	var fuel_pct := _display_percent(_fuel_display, fuel)
	draw_string(_font, fuel_pos + Vector2(228.0, 17.0), "%d%%" % fuel_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	# 2. Nitro Row
	var nitro_pos := Vector2(top_right_x, 72.0)
	_draw_subtle_capsule(nitro_pos - Vector2(10.0, 6.0), Vector2(285.0, 36.0))
	_draw_lightning_bolt(nitro_pos + Vector2(10.0, 12.0), COLOR_CYAN)
	_draw_capsule_bar(nitro_pos + Vector2(34.0, 3.0), Vector2(bar_width, bar_height), _nitro_display / 100.0, COLOR_CYAN, COLOR_CYAN_GLOW)
	var nitro_pct := _display_percent(_nitro_display, nitro)
	draw_string(_font, nitro_pos + Vector2(228.0, 17.0), "%d%%" % nitro_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	# 3. Sleek Pause Button
	_pause_rect = Rect2(viewport_size.x - 62.0, 118.0, 42.0, 38.0)
	_draw_subtle_capsule(_pause_rect.position, _pause_rect.size)
	draw_rect(Rect2(_pause_rect.position + Vector2(13.0, 11.0), Vector2(4.5, 16.0)), COLOR_GOLD)
	draw_rect(Rect2(_pause_rect.position + Vector2(24.5, 11.0), Vector2(4.5, 16.0)), COLOR_GOLD)


func _draw_gas_pump_icon(center: Vector2, color: Color) -> void:
	draw_style_box(_rounded_box(Color(0.12, 0.15, 0.18, 1.0), color, 3), Rect2(center - Vector2(7.0, 9.0), Vector2(14.0, 18.0)))
	draw_rect(Rect2(center + Vector2(-4.0, -6.0), Vector2(8.0, 5.0)), color)
	draw_line(center + Vector2(7.0, -5.0), center + Vector2(11.0, -1.0), color, 2.0)
	draw_line(center + Vector2(11.0, -1.0), center + Vector2(11.0, 5.0), color, 2.0)


func _draw_lightning_bolt(center: Vector2, color: Color) -> void:
	var pts := PackedVector2Array([
		center + Vector2(2.0, -9.0),
		center + Vector2(-6.0, 1.0),
		center + Vector2(-1.0, 1.0),
		center + Vector2(-3.0, 9.0),
		center + Vector2(6.0, -1.0),
		center + Vector2(1.0, -1.0),
	])
	draw_colored_polygon(pts, color)


func _draw_capsule_bar(pos: Vector2, sz: Vector2, fill_fraction: float, fill_color: Color, glow_color: Color) -> void:
	var r := int(sz.y * 0.5)
	# Recessed dark trough
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.03, 0.06, 0.08, 0.95)
	bg_style.border_color = Color(0.25, 0.35, 0.42, 0.8)
	bg_style.set_border_width_all(1)
	bg_style.corner_radius_top_left = r
	bg_style.corner_radius_top_right = r
	bg_style.corner_radius_bottom_left = r
	bg_style.corner_radius_bottom_right = r
	draw_style_box(bg_style, Rect2(pos, sz))

	# Filled capsule
	var fill_w := maxf((sz.x - 4.0) * clampf(fill_fraction, 0.0, 1.0), 0.0)
	if fill_w > 6.0:
		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = fill_color
		fill_style.corner_radius_top_left = r - 2
		fill_style.corner_radius_top_right = r - 2
		fill_style.corner_radius_bottom_left = r - 2
		fill_style.corner_radius_bottom_right = r - 2
		draw_style_box(fill_style, Rect2(pos + Vector2(2.0, 2.0), Vector2(fill_w, sz.y - 4.0)))

		# Top gloss sheen
		var gloss_style := StyleBoxFlat.new()
		gloss_style.bg_color = Color(1.0, 1.0, 1.0, 0.28)
		gloss_style.corner_radius_top_left = r - 2
		gloss_style.corner_radius_top_right = r - 2
		draw_style_box(gloss_style, Rect2(pos + Vector2(2.0, 2.0), Vector2(fill_w, (sz.y - 4.0) * 0.42)))


# ==========================================
# 3. MODERN DASHBOARD CLUSTER (Matches Reference)
# ==========================================
func _draw_modern_dashboard(viewport_size: Vector2) -> void:
	var cluster_y := viewport_size.y - 96.0
	var cluster_x := viewport_size.x * 0.5
	var gauge_radius := 66.0

	# Ambient dark pod backplate linking all 3 gauges
	var backplate := StyleBoxFlat.new()
	backplate.bg_color = Color(0.015, 0.025, 0.035, 0.92)
	backplate.border_color = Color(0.18, 0.24, 0.30, 0.6)
	backplate.set_border_width_all(1)
	backplate.corner_radius_top_left = 40
	backplate.corner_radius_top_right = 40
	backplate.corner_radius_bottom_left = 20
	backplate.corner_radius_bottom_right = 20
	draw_style_box(backplate, Rect2(Vector2(cluster_x - 195.0, cluster_y - 74.0), Vector2(390.0, 142.0)))

	# 1. Left: RPM Gauge
	_draw_rpm_gauge(Vector2(cluster_x - 120.0, cluster_y), gauge_radius)

	# 2. Right: Boost Gauge
	_draw_boost_gauge(Vector2(cluster_x + 120.0, cluster_y), gauge_radius)

	# 3. Center: Digital Speedometer (overlapping nicely)
	_draw_digital_speedometer(Vector2(cluster_x, cluster_y), gauge_radius - 4.0)


func _draw_rpm_gauge(center: Vector2, radius: float) -> void:
	# Metallic outer bevel
	_draw_chrome_bezel(center, radius)

	# Arc scale: 135 deg to 405 deg (PI*0.75 to PI*2.25)
	var arc_start := PI * 0.74
	var arc_sweep := PI * 1.52
	var fraction := clampf(_rpm_display / 8000.0, 0.0, 1.0)

	# Tick track
	draw_arc(center, radius - 7.0, arc_start, arc_start + arc_sweep, 36, Color(0.22, 0.28, 0.32), 2.5)
	# Redline warning zone from 6000 to 8000 (last 25% of sweep)
	var redline_start := arc_start + arc_sweep * 0.75
	draw_arc(center, radius - 7.0, redline_start, arc_start + arc_sweep, 16, COLOR_RED, 4.0)
	# Active RPM fill arc (amber to orange)
	draw_arc(center, radius - 7.0, arc_start, arc_start + arc_sweep * fraction, 36, COLOR_ORANGE, 3.5)

	# Radial ticks
	for i in range(9):
		var tick_f := float(i) / 8.0
		var angle := arc_start + arc_sweep * tick_f
		var inner_r := radius - (18.0 if i % 2 == 0 else 13.0)
		var outer_r := radius - 8.0
		var tick_color := COLOR_RED if i >= 6 else Color(0.85, 0.90, 0.92)
		draw_line(
			center + Vector2(cos(angle), sin(angle)) * inner_r,
			center + Vector2(cos(angle), sin(angle)) * outer_r,
			tick_color,
			2.5 if i % 2 == 0 else 1.5
		)
		if i % 2 == 0 and i > 0 and i < 8:
			var num_pos := center + Vector2(cos(angle), sin(angle)) * (radius - 28.0)
			draw_string(_font, num_pos + Vector2(-4.0, 4.0), "%d" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, tick_color)

	# Needle (Vibrant red)
	var needle_angle := arc_start + arc_sweep * fraction
	draw_line(center, center + Vector2(cos(needle_angle), sin(needle_angle)) * (radius - 12.0), COLOR_RED, 3.5)
	draw_circle(center, 7.0, Color(0.1, 0.12, 0.14))
	draw_circle(center, 3.5, COLOR_RED)

	# Labels
	draw_string(_font, center + Vector2(-15.0, 32.0), "RPM", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	draw_string(_font, center + Vector2(-18.0, 44.0), "x 1000", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, COLOR_ORANGE)


func _draw_digital_speedometer(center: Vector2, radius: float) -> void:
	# Dark recessed pod
	draw_circle(center, radius + 4.0, Color(0.02, 0.03, 0.04, 1.0))
	draw_arc(center, radius + 2.0, 0.0, TAU, 48, Color(0.15, 0.22, 0.28), 1.5)

	# Cyan Glowing Accent Ring around bottom / rim (Matches reference!)
	draw_arc(center, radius - 2.0, PI * 0.55, PI * 2.45, 48, COLOR_CYAN, 4.0)
	draw_arc(center, radius - 2.0, PI * 0.55, PI * 2.45, 48, COLOR_CYAN_GLOW, 8.0)

	# Big Bold Speed Readout (e.g. 45)
	var speed_val := int(round(_speed_display))
	var speed_str := "%d" % speed_val
	var num_offset_x := -14.0 if speed_val < 10 else (-22.0 if speed_val < 100 else -30.0)
	draw_string(_font, center + Vector2(num_offset_x, 10.0), speed_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color.WHITE)
	draw_string(_font, center + Vector2(-18.0, 32.0), "km/h", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_CYAN)


func _draw_boost_gauge(center: Vector2, radius: float) -> void:
	# Metallic outer bevel with cyan accent
	_draw_chrome_bezel(center, radius)

	var arc_start := PI * 0.74
	var arc_sweep := PI * 1.52
	var fraction := clampf(_nitro_display / 100.0, 0.0, 1.0)

	# Tick track & active cyan fill arc
	draw_arc(center, radius - 7.0, arc_start, arc_start + arc_sweep, 36, Color(0.2, 0.28, 0.32), 2.5)
	draw_arc(center, radius - 7.0, arc_start, arc_start + arc_sweep * fraction, 36, COLOR_CYAN, 4.0)
	draw_arc(center, radius - 7.0, arc_start, arc_start + arc_sweep * fraction, 36, COLOR_CYAN_GLOW, 7.0)

	# Radial ticks
	for i in range(6):
		var tick_f := float(i) / 5.0
		var angle := arc_start + arc_sweep * tick_f
		var inner_r := radius - 16.0
		var outer_r := radius - 8.0
		draw_line(
			center + Vector2(cos(angle), sin(angle)) * inner_r,
			center + Vector2(cos(angle), sin(angle)) * outer_r,
			COLOR_CYAN,
			2.5
		)
		var num_pos := center + Vector2(cos(angle), sin(angle)) * (radius - 28.0)
		draw_string(_font, num_pos + Vector2(-7.0, 4.0), "%d" % (i * 20), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.95, 1.0))

	# Needle (Vibrant electric cyan)
	var needle_angle := arc_start + arc_sweep * fraction
	draw_line(center, center + Vector2(cos(needle_angle), sin(needle_angle)) * (radius - 12.0), COLOR_CYAN, 3.5)
	draw_circle(center, 7.0, Color(0.1, 0.12, 0.14))
	draw_circle(center, 3.5, COLOR_CYAN)

	# Center Lightning Bolt & BOOST %
	_draw_lightning_bolt(center + Vector2(0.0, 22.0), COLOR_CYAN)
	draw_string(_font, center + Vector2(-22.0, 40.0), "BOOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_CYAN)
	draw_string(_font, center + Vector2(-4.0, 50.0), "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 0.9, 1.0))


func _draw_chrome_bezel(center: Vector2, radius: float) -> void:
	# Layered automotive metallic ring
	draw_circle(center, radius + 8.0, Color(0.02, 0.04, 0.05, 0.75))
	draw_circle(center, radius + 5.0, Color(0.32, 0.38, 0.44))
	draw_arc(center, radius + 4.0, 0.0, TAU, 48, Color(0.65, 0.75, 0.82), 2.0)
	draw_circle(center, radius + 1.0, Color(0.12, 0.15, 0.18))
	draw_circle(center, radius - 2.0, Color(0.04, 0.06, 0.08))


# ==========================================
# 4. MODERN PEDALS (Matches Reference)
# ==========================================
func _draw_modern_pedal(center: Vector2, title: String, active: bool, is_brake: bool) -> void:
	var press_offset := Vector2(0.0, 6.0) if active else Vector2.ZERO
	var rect := Rect2(center - Vector2(76.0, 58.0) + press_offset, Vector2(152.0, 116.0))
	var accent_color := COLOR_RED if is_brake else COLOR_CYAN
	var glow_color := COLOR_RED_GLOW if is_brake else COLOR_CYAN_GLOW

	# 1. Glowing Neon Aura Outer Border (Matches reference!)
	var outer_glow := StyleBoxFlat.new()
	outer_glow.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	outer_glow.border_color = accent_color if active else Color(accent_color.r, accent_color.g, accent_color.b, 0.65)
	outer_glow.set_border_width_all(3 if active else 2)
	outer_glow.corner_radius_top_left = 18
	outer_glow.corner_radius_top_right = 18
	outer_glow.corner_radius_bottom_left = 12
	outer_glow.corner_radius_bottom_right = 12
	draw_style_box(outer_glow, Rect2(rect.position - Vector2(4.0, 4.0), rect.size + Vector2(8.0, 8.0)))

	if active:
		# Extra glow aura when pressed
		var extra_glow := StyleBoxFlat.new()
		extra_glow.bg_color = glow_color
		extra_glow.corner_radius_top_left = 22
		extra_glow.corner_radius_top_right = 22
		extra_glow.corner_radius_bottom_left = 16
		extra_glow.corner_radius_bottom_right = 16
		draw_style_box(extra_glow, Rect2(rect.position - Vector2(8.0, 8.0), rect.size + Vector2(16.0, 16.0)))

	# 2. Main Pedal Plate (Metallic Silver / Chrome)
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0.55, 0.58, 0.62) if not active else Color(0.68, 0.72, 0.75)
	plate_style.border_color = Color(0.85, 0.92, 0.96)
	plate_style.set_border_width_all(2)
	plate_style.corner_radius_top_left = 14
	plate_style.corner_radius_top_right = 14
	plate_style.corner_radius_bottom_left = 10
	plate_style.corner_radius_bottom_right = 10
	draw_style_box(plate_style, rect)

	# 3. 3x3 Perforated Grip Holes
	for row in range(3):
		for col in range(3):
			var hole_center := rect.position + Vector2(40.0 + col * 36.0, 24.0 + row * 22.0)
			# Hole shadow depth & silver highlight
			draw_circle(hole_center + Vector2(1.0, 1.5), 6.5, Color(0.15, 0.18, 0.2, 0.95))
			draw_circle(hole_center, 5.0, Color(0.08, 0.1, 0.12, 1.0))
			draw_circle(hole_center - Vector2(1.0, 1.0), 2.0, Color(0.4, 0.45, 0.5, 0.4))

	# 4. Bottom Embossed Label Badge (BRAKE / ACCELERATE)
	var label_rect := Rect2(rect.position + Vector2(14.0, 82.0), Vector2(rect.size.x - 28.0, 26.0))
	var label_box := StyleBoxFlat.new()
	label_box.bg_color = Color(0.06, 0.08, 0.10, 0.95)
	label_box.border_color = accent_color if active else Color(0.3, 0.38, 0.44)
	label_box.set_border_width_all(1)
	label_box.corner_radius_top_left = 6
	label_box.corner_radius_top_right = 6
	label_box.corner_radius_bottom_left = 6
	label_box.corner_radius_bottom_right = 6
	draw_style_box(label_box, label_rect)

	var label_x_offset := -24.0 if is_brake else -44.0
	draw_string(
		_font,
		label_rect.position + Vector2(label_rect.size.x * 0.5 + label_x_offset, 18.0),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color.WHITE if not active else accent_color
	)


func _display_percent(display_value: float, source_value: float) -> int:
	if source_value >= 99.5:
		return 100
	return clampi(int(round(display_value)), 0, 100)


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
