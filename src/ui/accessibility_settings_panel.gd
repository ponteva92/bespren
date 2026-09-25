class_name AccessibilitySettingsPanel
extends Panel
## The StartMenu's accessibility sheet: one row per `GameSettings` scale.
##
## Every row is a label, a step-down button, the value and a step-up button, and
## every button is a full 44 x 44 logical target (CLAUDE.md 11), so the sheet
## works under a thumb on a phone as well as with a keyboard. Steps are quarters
## and the value reads OFF at zero, because zero means the effect is absent
## rather than faint and the label should say so. Each change is saved at once,
## so there is no unsaved state to lose to a backgrounded app.

signal closed

const TOUCH_TARGET: float = 44.0
const ROW_GAP: float = 4.0
const MARGIN: float = 8.0
const VALUE_WIDTH: float = 60.0
const LABEL_COLOR: Color = Color(0.75, 0.86, 0.8, 1.0)
const TITLE_COLOR: Color = Color(1.0, 0.78, 0.35, 1.0)
const VALUE_COLOR: Color = Color(0.9, 0.94, 0.84, 1.0)
const OFF_COLOR: Color = Color(1.0, 0.72, 0.29, 1.0)

var _settings: GameSettings
var _save_path: String = GameSettings.DEFAULT_PATH
var _title: Label
var _done_button: Button
var _row_labels: Array[Label] = []
var _minus_buttons: Array[Button] = []
var _plus_buttons: Array[Button] = []
var _value_labels: Array[Label] = []
var _button_styles: Dictionary = {}


## [param button_styles] maps `normal`, `hover`, `pressed` and `focus` to the
## menu's own action styleboxes, so the sheet wears the menu's language.
func setup(settings: GameSettings, save_path: String, panel_style: StyleBox, button_styles: Dictionary) -> void:
	_settings = settings
	_save_path = save_path
	_button_styles = button_styles
	name = &"AccessibilitySettings"
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Opaque, unlike the session plate it copies: the sheet covers the menu, and
	# a card showing through behind a row of steppers reads as a second layer of
	# controls under the thumb.
	var sheet_style: StyleBox = panel_style.duplicate() if panel_style != null else null
	if sheet_style is StyleBoxFlat:
		(sheet_style as StyleBoxFlat).bg_color.a = 1.0
	if sheet_style != null:
		add_theme_stylebox_override(&"panel", sheet_style)
	_title = _make_label("ACCESSIBILITY", 12, TITLE_COLOR)
	_done_button = _make_button("DONE", 10)
	_done_button.pressed.connect(close)
	for key: int in range(GameSettings.KEY_LABELS.size()):
		_row_labels.append(_make_label(GameSettings.KEY_LABELS[key], 10, LABEL_COLOR))
		var minus: Button = _make_button("-", 14)
		var plus: Button = _make_button("+", 14)
		minus.pressed.connect(_on_step.bind(key, -1))
		plus.pressed.connect(_on_step.bind(key, 1))
		_minus_buttons.append(minus)
		_plus_buttons.append(plus)
		var value: Label = _make_label("", 10, VALUE_COLOR)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_value_labels.append(value)
	_refresh_values()


func setup_settings(settings: GameSettings, save_path: String) -> void:
	_settings = settings
	_save_path = save_path
	_refresh_values()


func open_in(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	_layout()
	visible = true
	_refresh_values()
	_done_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func get_settings() -> GameSettings:
	return _settings


## Untransformed rectangles of every touch target, for the layout gate.
func get_interactive_layout_rects() -> Dictionary:
	var rects: Dictionary = {&"done_button": Rect2(position + _done_button.position, _done_button.size)}
	for key: int in range(_minus_buttons.size()):
		rects[StringName("minus_%s" % GameSettings.KEY_NAMES[key])] = Rect2(position + _minus_buttons[key].position, _minus_buttons[key].size)
		rects[StringName("plus_%s" % GameSettings.KEY_NAMES[key])] = Rect2(position + _plus_buttons[key].position, _plus_buttons[key].size)
	return rects


func press_step_for_validation(key: int, direction: int) -> void:
	_on_step(key, direction)


func get_value_text(key: int) -> String:
	return _value_labels[key].text if key >= 0 and key < _value_labels.size() else ""


func _on_step(key: int, direction: int) -> void:
	if _settings == null:
		return
	_settings.step_value(key, direction)
	_settings.save_to_disk(_save_path)
	_refresh_values()


func _refresh_values() -> void:
	if _settings == null:
		return
	for key: int in range(_value_labels.size()):
		var value: float = _settings.get_value(key)
		_value_labels[key].text = "OFF" if is_zero_approx(value) else "%d%%" % roundi(value * 100.0)
		_value_labels[key].add_theme_color_override(
			&"font_color", OFF_COLOR if is_zero_approx(value) else VALUE_COLOR
		)
		_minus_buttons[key].disabled = is_zero_approx(value)
		_plus_buttons[key].disabled = is_equal_approx(value, 1.0)


func _layout() -> void:
	var inner_width: float = size.x - MARGIN * 2.0
	_done_button.position = Vector2(size.x - MARGIN - 72.0, MARGIN)
	_done_button.size = Vector2(72.0, TOUCH_TARGET)
	_title.position = Vector2(MARGIN + 2.0, MARGIN)
	_title.size = Vector2(inner_width - 80.0, TOUCH_TARGET)
	var controls_width: float = TOUCH_TARGET * 2.0 + VALUE_WIDTH + ROW_GAP * 2.0
	var controls_x: float = size.x - MARGIN - controls_width
	for key: int in range(_row_labels.size()):
		var row_y: float = MARGIN + TOUCH_TARGET + ROW_GAP + float(key) * (TOUCH_TARGET + ROW_GAP)
		_row_labels[key].position = Vector2(MARGIN + 2.0, row_y)
		_row_labels[key].size = Vector2(maxf(controls_x - MARGIN - 8.0, 0.0), TOUCH_TARGET)
		_minus_buttons[key].position = Vector2(controls_x, row_y)
		_minus_buttons[key].size = Vector2(TOUCH_TARGET, TOUCH_TARGET)
		_value_labels[key].position = Vector2(controls_x + TOUCH_TARGET + ROW_GAP, row_y)
		_value_labels[key].size = Vector2(VALUE_WIDTH, TOUCH_TARGET)
		_plus_buttons[key].position = Vector2(controls_x + TOUCH_TARGET + VALUE_WIDTH + ROW_GAP * 2.0, row_y)
		_plus_buttons[key].size = Vector2(TOUCH_TARGET, TOUCH_TARGET)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	add_child(label)
	return label


func _make_button(text: String, font_size: int) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override(&"font_size", font_size)
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		var style: StyleBox = _button_styles.get(state) as StyleBox
		if style != null:
			button.add_theme_stylebox_override(state, style)
	# A step that cannot go further is disabled, and must still read as the same
	# button, dimmed, rather than vanish into the sheet.
	var normal: StyleBox = _button_styles.get(&"normal") as StyleBox
	if normal is StyleBoxFlat:
		var dimmed: StyleBoxFlat = (normal as StyleBoxFlat).duplicate() as StyleBoxFlat
		dimmed.bg_color.a *= 0.45
		dimmed.border_color.a *= 0.35
		button.add_theme_stylebox_override(&"disabled", dimmed)
	add_child(button)
	return button
