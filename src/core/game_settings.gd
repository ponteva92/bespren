class_name GameSettings
extends RefCounted
## The player's accessibility settings, persisted to `user://settings.cfg`.
##
## CLAUDE.md 11 requires weather intensity, camera shake and emissive pulse
## amplitude to be adjustable before content production locks them in, and the
## feedback stack already carries a scale for three of them where zero means
## absent rather than dim - `CameraShake2D.intensity_scale`,
## `WeatherOverlay.damage_intensity_scale` and the weather preset's intensity.
## Nothing set them and nothing remembered them, so each shipped at full
## strength whatever the player needed. This is the one place that does both,
## and pulse amplitude joins it as a fourth scale through the
## `bespren_pulse_amount` global shader uniform every pulsing material reads.
##
## A plain typed object rather than an autoload, because the project has none
## and nothing here needs process-global lifetime: `StartMenu` loads and saves
## it, and `GameWorld` loads it once and applies it to the nodes it composes.
## Values snap to quarters, which is what the menu's step buttons produce and
## what a hand-edited file is coerced to.

const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION: String = "accessibility"
const STEP: float = 0.25
## The global shader uniform declared under `[shader_globals]` in project.godot.
const PULSE_GLOBAL: StringName = &"bespren_pulse_amount"

enum Key {
	CAMERA_SHAKE,
	DAMAGE_FLASH,
	WEATHER,
	PULSE,
}

## Config keys and menu labels, in `Key` order.
const KEY_NAMES: Array[String] = ["camera_shake", "damage_flash", "weather", "pulse"]
const KEY_LABELS: Array[String] = ["CAMERA SHAKE", "DAMAGE FLASH", "WEATHER", "GLOW PULSE"]

var _values: PackedFloat32Array = PackedFloat32Array([1.0, 1.0, 1.0, 1.0])


static func load_from_disk(path: String = DEFAULT_PATH) -> GameSettings:
	var settings: GameSettings = GameSettings.new()
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return settings
	for key: int in range(KEY_NAMES.size()):
		var stored: Variant = file.get_value(SECTION, KEY_NAMES[key], 1.0)
		if stored is float or stored is int:
			settings.set_value(key, float(stored))
	return settings


func save_to_disk(path: String = DEFAULT_PATH) -> Error:
	var file: ConfigFile = ConfigFile.new()
	for key: int in range(KEY_NAMES.size()):
		file.set_value(SECTION, KEY_NAMES[key], _values[key])
	return file.save(path)


func get_value(key: int) -> float:
	if key < 0 or key >= _values.size():
		return 1.0
	return _values[key]


## Clamps to 0..1 and snaps to the nearest quarter; a non-finite value is
## ignored rather than stored.
func set_value(key: int, value: float) -> void:
	if key < 0 or key >= _values.size() or not is_finite(value):
		return
	_values[key] = snappedf(clampf(value, 0.0, 1.0), STEP)


func step_value(key: int, direction: int) -> void:
	set_value(key, get_value(key) + STEP * float(signi(direction)))


func get_camera_shake() -> float:
	return get_value(Key.CAMERA_SHAKE)


func get_damage_flash() -> float:
	return get_value(Key.DAMAGE_FLASH)


func get_weather() -> float:
	return get_value(Key.WEATHER)


func get_pulse() -> float:
	return get_value(Key.PULSE)


## Writes the one setting that is global rather than per node. Harmless under
## the headless dummy renderer, where the call has nothing to update.
func apply_pulse_global() -> void:
	RenderingServer.global_shader_parameter_set(PULSE_GLOBAL, get_pulse())
