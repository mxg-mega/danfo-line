class_name PauseScreen
extends CanvasLayer

## Pause / Options modal for Danfo Line.
## Toggled by Esc (ui_cancel) or the HUD pause button. Freezes the whole tree
## while visible — only this layer (PROCESS_MODE_ALWAYS) keeps processing.
## Embeds a SettingsScreen overlay for in-race options.

const PANEL: Color = Color("100D16")
const INK: Color = Color("F4ECE4")
const MUTED: Color = Color("A79FB4")
const ACCENT: Color = Color("FFC400")

const MAIN_MENU_SCENE: String = "res://src/ui/main_menu.tscn"

## Set by Main so pausing can be suppressed once the results screen is up.
var results_screen: CanvasLayer

var _menu_box: VBoxContainer
var _settings: SettingsScreen

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_layout()

func _build_layout() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.01, 0.01, 0.02, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "MenuPanel"
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 12)
	_menu_box.custom_minimum_size = Vector2(320, 0)
	panel.add_child(_menu_box)

	var title: Label = _label("PAUSED", 34, ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_box.add_child(title)

	_menu_box.add_child(_menu_button("RESUME", close))
	_menu_box.add_child(_menu_button("RESTART SHIFT", _on_restart_pressed))
	_menu_box.add_child(_menu_button("SETTINGS", _on_settings_pressed))
	_menu_box.add_child(_menu_button("MAIN MENU", _on_main_menu_pressed))
	_menu_box.add_child(_label("ESC TO TOGGLE", 12, MUTED))

func _menu_button(text: String, on_pressed: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(on_pressed)
	return b

func _label(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	# Never pause over the results modal — the day is already over.
	if results_screen and results_screen.visible:
		return
	get_tree().paused = true
	visible = true

func close() -> void:
	get_tree().paused = false
	visible = false
	_remove_settings()

func _handle_overlay_closed() -> void:
	# While paused the tree must stay frozen; just swap settings back to the menu.
	_remove_settings()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_settings_pressed() -> void:
	_remove_settings()
	_settings = SettingsScreen.new()
	_settings.closed.connect(_handle_overlay_closed)
	add_child(_settings)

func _remove_settings() -> void:
	if is_instance_valid(_settings):
		_settings.queue_free()