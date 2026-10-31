extends Control
class_name MainMenu

signal play_requested
signal vehicle_changed
signal stage_changed

const ACCENT := Color(1.0, 0.57, 0.08)
const GOLD := Color(1.0, 0.78, 0.22)
const PANEL := Color(0.025, 0.04, 0.055, 0.94)

var profile
var _main: Node
var _content: VBoxContainer
var _panel: Panel
var _message: Label
var _garage_button: Button
var _settings_button: Button
var _menu_mode := "home"
var _button_style: StyleBoxFlat
var _hover_style: StyleBoxFlat


func setup(main_node: Node, profile_node: Node) -> void:
	_main = main_node
	profile = profile_node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_button_style = _style(Color(0.08, 0.1, 0.12, 0.96), Color(0.25, 0.3, 0.32, 1.0), 8)
	_hover_style = _style(Color(0.22, 0.13, 0.045, 0.98), ACCENT, 8)
	_build_home()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.45)


func _process(_delta: float) -> void:
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _menu_mode == "home":
			if get_tree().paused:
				_resume_game()
			else:
				_show_menu()
		else:
			_build_home()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.022, 0.03, 0.98))
	for index in range(7):
		var y := size.y * 0.26 + index * size.y * 0.09
		draw_rect(
			Rect2(0, y, size.x, maxf(size.y - y, 0.0)),
			Color(0.06 + index * 0.008, 0.09 + index * 0.008, 0.1 + index * 0.01, 1.0)
		)
	draw_circle(Vector2(size.x * 0.78, size.y * 0.22), size.y * 0.13, Color(1.0, 0.47, 0.12, 0.12))
	draw_circle(Vector2(size.x * 0.78, size.y * 0.22), size.y * 0.075, Color(1.0, 0.68, 0.26, 0.11))


func _build_home() -> void:
	_menu_mode = "home"
	_clear_children()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 42)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	margin.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	var eyebrow := _label("ORIGINAL OFFROAD // SEASON 01", 14, Color(0.6, 0.72, 0.76))
	left.add_child(eyebrow)
	var title := _label("DUST//\nVECTOR", 62, Color(0.97, 0.98, 0.96))
	title.add_theme_color_override("font_shadow_color", Color(1.0, 0.42, 0.05, 0.35))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	left.add_child(title)
	left.add_child(_label("RACE THE RIDGE. OWN THE AIR.", 17, ACCENT))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)
	var best := _label("BEST DISTANCE  %04d m" % int(profile.best_distance), 15, Color(0.78, 0.86, 0.88))
	left.add_child(best)
	left.add_child(_label("%s  /  %s" % [profile.selected_vehicle.to_upper(), profile.STAGES[profile.selected_stage]["label"]], 13, Color(0.55, 0.67, 0.71)))
	columns.add_child(_build_home_panel())
	queue_redraw()


func _build_home_panel() -> Control:
	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(365, 0)
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_theme_stylebox_override("panel", _style(PANEL, Color(0.2, 0.27, 0.3, 1), 14))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 12)
	box.add_theme_constant_override("margin_left", 28)
	box.add_theme_constant_override("margin_right", 28)
	box.add_theme_constant_override("margin_top", 30)
	box.add_theme_constant_override("margin_bottom", 30)
	_panel.add_child(box)
	var header := _label("GARAGE CONTROL", 13, ACCENT)
	box.add_child(header)
	var balance := _label("◈  %06d COINS" % profile.coins, 25, GOLD)
	balance.name = "Balance"
	box.add_child(balance)
	var line := HSeparator.new()
	box.add_child(line)
	_add_action(box, "START EXPEDITION", "PLAY", _start_game)
	_garage_button = _add_action(box, "VEHICLES & UPGRADES", "GARAGE", _build_garage)
	_settings_button = _add_action(box, "AUDIO / DISPLAY", "SETTINGS", _build_settings)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(fill)
	box.add_child(_label("W / ↑  ACCELERATE     SPACE  BRAKE\nA / D  AIR CONTROL     SHIFT  NITRO", 12, Color(0.55, 0.67, 0.71)))
	var exit := _button("EXIT TO DESKTOP", _exit_game)
	box.add_child(exit)
	return _panel


func _build_garage() -> void:
	_menu_mode = "garage"
	_clear_children()
	var panel := _make_subpanel("VEHICLE & STAGE SELECT")
	var content := panel.get_node("Content") as VBoxContainer
	content.add_child(_label("CHOOSE YOUR MACHINE", 15, ACCENT))
	for name in profile.VEHICLES:
		var data: Dictionary = profile.VEHICLES[name]
		var unlocked: bool = profile.is_vehicle_unlocked(name)
		var text := "%s    TORQUE %.1f   GRIP %.1f" % [name.to_upper(), data["torque"], data["grip"]]
		if not unlocked:
			text += "    ◈ %d" % int(data["price"])
		var button := _button(text, Callable(self, "_select_vehicle").bind(name))
		if name == profile.selected_vehicle:
			button.add_theme_stylebox_override("normal", _hover_style)
		content.add_child(button)
	content.add_child(_label("CHOOSE A WORLD", 15, ACCENT))
	for name in profile.STAGES:
		var stage_data: Dictionary = profile.STAGES[name]
		var unlocked: bool = profile.is_stage_unlocked(name)
		var text := "%s" % stage_data["label"]
		if not unlocked:
			text += "    ◈ %d" % int(stage_data["price"])
		var button := _button(text, Callable(self, "_select_stage").bind(name))
		if name == profile.selected_stage:
			button.add_theme_stylebox_override("normal", _hover_style)
		content.add_child(button)
	content.add_child(_button("BACK TO COMMAND", _build_home))


func _build_settings() -> void:
	_menu_mode = "settings"
	_clear_children()
	var panel := _make_subpanel("SETTINGS")
	var content := panel.get_node("Content") as VBoxContainer
	_add_slider(content, "MASTER VOLUME", profile.master_volume, "_set_master")
	_add_slider(content, "MUSIC VOLUME", profile.music_volume, "_set_music")
	_add_slider(content, "SFX VOLUME", profile.effects_volume, "_set_effects")
	content.add_child(_label("GRAPHICS QUALITY", 13, ACCENT))
	var quality := OptionButton.new()
	quality.add_item("LOW")
	quality.add_item("MEDIUM")
	quality.add_item("HIGH")
	quality.select(["Low", "Medium", "High"].find(profile.graphics_quality))
	quality.item_selected.connect(_set_quality)
	content.add_child(quality)
	content.add_child(_button("BACK TO COMMAND", _build_home))


func _make_subpanel(title: String) -> Panel:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -285)
	panel.size = Vector2(620, 570)
	panel.add_theme_stylebox_override("panel", _style(PANEL, Color(0.25, 0.32, 0.35, 1), 14))
	add_child(panel)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 10)
	content.add_theme_constant_override("margin_left", 32)
	content.add_theme_constant_override("margin_right", 32)
	content.add_theme_constant_override("margin_top", 28)
	content.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(content)
	content.add_child(_label(title, 28, GOLD))
	content.add_child(HSeparator.new())
	_message = _label("", 12, Color(1.0, 0.54, 0.3))
	content.add_child(_message)
	return panel


func _add_slider(parent: VBoxContainer, title: String, value: float, method: String) -> void:
	parent.add_child(_label(title, 13, ACCENT))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size.y = 28
	slider.value_changed.connect(Callable(self, method))
	parent.add_child(slider)


func _select_vehicle(name: String) -> void:
	if profile.is_vehicle_unlocked(name):
		profile.selected_vehicle = name
		profile.save_profile()
		vehicle_changed.emit()
		_build_garage()
	elif profile.purchase_vehicle(name):
		profile.selected_vehicle = name
		vehicle_changed.emit()
		_build_garage()
	else:
		_show_message("MORE COINS REQUIRED TO UNLOCK %s" % name.to_upper())


func _select_stage(name: String) -> void:
	if profile.is_stage_unlocked(name):
		profile.selected_stage = name
		profile.save_profile()
		stage_changed.emit()
		_build_garage()
	elif profile.purchase_stage(name):
		profile.selected_stage = name
		stage_changed.emit()
		_build_garage()
	else:
		_show_message("MORE COINS REQUIRED TO UNLOCK %s" % name.to_upper())


func _show_message(text: String) -> void:
	if is_instance_valid(_message):
		_message.text = text


func _set_master(value: float) -> void:
	profile.master_volume = value
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001)))
	profile.save_profile()


func _set_music(value: float) -> void:
	profile.music_volume = value
	profile.save_profile()


func _set_effects(value: float) -> void:
	profile.effects_volume = value
	profile.save_profile()


func _set_quality(index: int) -> void:
	profile.graphics_quality = ["Low", "Medium", "High"][index]
	profile.save_profile()


func _start_game() -> void:
	play_requested.emit()


func _resume_game() -> void:
	visible = false
	get_tree().paused = false


func _show_menu() -> void:
	visible = true
	get_tree().paused = true


func _exit_game() -> void:
	get_tree().quit()


func _clear_children() -> void:
	for child in get_children():
		if child != _message:
			child.queue_free()


func _add_action(parent: VBoxContainer, description: String, text: String, action: Callable) -> Button:
	parent.add_child(_label(description, 11, Color(0.48, 0.6, 0.64)))
	var button := _button(text, action)
	button.custom_minimum_size.y = 58
	parent.add_child(button)
	return button


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.92, 0.96, 0.96))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style)
	button.add_theme_stylebox_override("hover", _hover_style)
	button.add_theme_stylebox_override("pressed", _style(Color(0.35, 0.17, 0.04, 1), GOLD, 8))
	button.pressed.connect(action)
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _style(fill: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style
