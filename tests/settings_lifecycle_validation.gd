extends SceneTree
## Headless gate for the accessibility settings and the backgrounded-app pause.
##
## CLAUDE.md 11 requires camera shake, weather intensity and emissive pulse to
## be adjustable, and the feedback stack defines each scale so that zero means
## absent rather than dim. This proves the whole path a player's choice travels:
## the menu sheet steps a value and saves it at once, the file round-trips, and
## the game world reads it and pushes it into the nodes it composes, where each
## effect is then measured at zero - not merely its scale property read back.
## It also proves the lifecycle contract: a backgrounded Solo session pauses the
## tree and releases held touches, returning resumes it, a LAN session releases
## touches without pausing, and leaving the world never strands a pause.

const MENU_SCENE: PackedScene = preload("res://scenes/ui/StartMenu.tscn")
const WORLD_SCENE: PackedScene = preload("res://scenes/game/game_world.tscn")
const SCRATCH_PATH: String = "user://settings_validation.cfg"
const MIN_TOUCH_TARGET: float = 44.0

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PATH))
	_validate_settings_model()
	await _validate_menu_sheet()
	await _validate_world_application()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PATH))
	_finish()


func _validate_settings_model() -> void:
	var fresh: GameSettings = GameSettings.load_from_disk(SCRATCH_PATH)
	var every_default_is_full: bool = true
	for key: int in range(GameSettings.KEY_NAMES.size()):
		if not is_equal_approx(fresh.get_value(key), 1.0):
			every_default_is_full = false
	_check(every_default_is_full, "A missing settings file yields every effect at full strength")
	var settings: GameSettings = GameSettings.new()
	settings.set_value(GameSettings.Key.CAMERA_SHAKE, 0.37)
	_check(is_equal_approx(settings.get_camera_shake(), 0.25), "Values snap to the nearest quarter")
	settings.set_value(GameSettings.Key.WEATHER, 1.4)
	settings.set_value(GameSettings.Key.PULSE, -2.0)
	_check(
		is_equal_approx(settings.get_weather(), 1.0) and is_zero_approx(settings.get_pulse()),
		"Values clamp to the 0..1 range"
	)
	settings.set_value(GameSettings.Key.DAMAGE_FLASH, NAN)
	_check(is_equal_approx(settings.get_damage_flash(), 1.0), "A non-finite value is ignored rather than stored")
	settings.step_value(GameSettings.Key.WEATHER, -1)
	_check(is_equal_approx(settings.get_weather(), 0.75), "A step moves one quarter")
	_check(settings.save_to_disk(SCRATCH_PATH) == OK, "Settings save to disk")
	var reloaded: GameSettings = GameSettings.load_from_disk(SCRATCH_PATH)
	var round_trips: bool = true
	for key: int in range(GameSettings.KEY_NAMES.size()):
		if not is_equal_approx(reloaded.get_value(key), settings.get_value(key)):
			round_trips = false
	_check(round_trips, "Every setting round-trips through the file exactly")
	var corrupt: ConfigFile = ConfigFile.new()
	corrupt.set_value(GameSettings.SECTION, "camera_shake", "loud")
	corrupt.save(SCRATCH_PATH)
	_check(
		is_equal_approx(GameSettings.load_from_disk(SCRATCH_PATH).get_camera_shake(), 1.0),
		"A malformed stored value falls back to the default"
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PATH))


func _validate_menu_sheet() -> void:
	var menu: StartMenu = MENU_SCENE.instantiate() as StartMenu
	menu.settings_path = SCRATCH_PATH
	root.add_child(menu)
	await process_frame
	await process_frame
	var rects: Dictionary = menu.get_interactive_layout_rects()
	_check(rects.has(&"options_button"), "The start menu exposes an OPTIONS touch target")
	var options_rect: Rect2 = rects.get(&"options_button", Rect2()) as Rect2
	_check(
		options_rect.size.x >= MIN_TOUCH_TARGET and options_rect.size.y >= MIN_TOUCH_TARGET,
		"OPTIONS keeps the 44px touch contract"
	)
	_check(menu.get_layout_safe_rect().encloses(options_rect), "OPTIONS stays inside the safe area")
	menu.options_button.pressed.emit()
	await process_frame
	_check(menu.is_settings_open(), "OPTIONS opens the accessibility sheet")
	var sheet: AccessibilitySettingsPanel = menu.get_settings_panel()
	var sheet_rects: Dictionary = sheet.get_interactive_layout_rects()
	_check(sheet_rects.size() == 1 + GameSettings.KEY_NAMES.size() * 2, "The sheet has a step pair per setting and a DONE button")
	var sheet_bounds: Rect2 = Rect2(sheet.position, sheet.size)
	var targets_hold: bool = true
	var targets_inside: bool = true
	var names: Array = sheet_rects.keys()
	for name_variant: Variant in names:
		var rect: Rect2 = sheet_rects[name_variant] as Rect2
		if rect.size.x < MIN_TOUCH_TARGET or rect.size.y < MIN_TOUCH_TARGET:
			targets_hold = false
		if not sheet_bounds.encloses(rect) or not menu.get_layout_safe_rect().encloses(rect):
			targets_inside = false
	var no_overlap: bool = true
	for first: int in range(names.size()):
		for second: int in range(first + 1, names.size()):
			if (sheet_rects[names[first]] as Rect2).intersects(sheet_rects[names[second]] as Rect2):
				no_overlap = false
	_check(targets_hold, "Every sheet button keeps the 44px touch contract")
	_check(targets_inside, "Every sheet button stays inside the sheet and the safe area")
	_check(no_overlap, "No two sheet buttons overlap")
	for _step: int in range(4):
		sheet.press_step_for_validation(GameSettings.Key.CAMERA_SHAKE, -1)
	_check(sheet.get_value_text(GameSettings.Key.CAMERA_SHAKE) == "OFF", "Zero reads OFF rather than 0%")
	_check(
		is_zero_approx(GameSettings.load_from_disk(SCRATCH_PATH).get_camera_shake()),
		"Each step is saved to disk immediately"
	)
	sheet.close()
	_check(not menu.is_settings_open(), "DONE closes the sheet")
	menu.queue_free()
	await process_frame


func _validate_world_application() -> void:
	var stored: GameSettings = GameSettings.new()
	stored.set_value(GameSettings.Key.CAMERA_SHAKE, 0.0)
	stored.set_value(GameSettings.Key.DAMAGE_FLASH, 0.0)
	stored.set_value(GameSettings.Key.WEATHER, 0.5)
	stored.set_value(GameSettings.Key.PULSE, 0.0)
	stored.save_to_disk(SCRATCH_PATH)
	var world: GameWorld = WORLD_SCENE.instantiate() as GameWorld
	world.settings_path = SCRATCH_PATH
	world.configure_launch(CoopSession.SessionMode.SOLO, &"heikki", "127.0.0.1")
	root.add_child(world)
	for _frame: int in range(4):
		await process_frame
		await physics_frame
	var overlay: WeatherOverlay = world.screen_effects
	_check(is_zero_approx(overlay.damage_intensity_scale), "The world applies the stored damage-flash scale")
	overlay.flash(1.0)
	_check(is_zero_approx(overlay.get_damage_wash()), "At zero a full hit raises no damage wash at all")
	_check(
		is_equal_approx(overlay.get_effective_intensity(), overlay.intensity * 0.5),
		"The weather pass runs at the stored half intensity"
	)
	var core: CorePulseDriver = world.base_core
	_check(is_zero_approx(core.pulse_scale), "The refuge light takes the stored pulse scale")
	var light: PointLight2D = core.get_node_or_null(core.light_path) as PointLight2D
	var energies: PackedFloat32Array = PackedFloat32Array()
	for _sample: int in range(3):
		core._process(0.37)
		energies.append(light.energy if light != null else -1.0)
	_check(
		light != null and is_equal_approx(energies[0], energies[1]) and is_equal_approx(energies[1], energies[2]),
		"At zero the refuge light holds still across its whole pulse"
	)
	var local_player: PlayerAvatar = null
	for player: Node in world.players_root.get_children():
		if player is PlayerAvatar and (player as PlayerAvatar).is_local_player:
			local_player = player as PlayerAvatar
	var shake: CameraShake2D = local_player.get_camera_shake() if local_player != null else null
	_check(shake != null and is_zero_approx(shake.intensity_scale), "The local survivor's camera shake takes the stored scale")
	if local_player != null:
		local_player.add_camera_impact(1.0, Vector2.RIGHT)
		await process_frame
		_check(local_player.camera.offset.is_zero_approx(), "At zero a full impact leaves the camera untouched")

	# Lifecycle: Solo pauses on background and resumes on return.
	world.controls._set_movement(Vector2.RIGHT)
	_check(not world.controls.movement_vector.is_zero_approx(), "A held stick is live before backgrounding")
	world.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(paused and world.is_paused_for_background(), "A backgrounded Solo session pauses the tree")
	_check(world.controls.movement_vector.is_zero_approx(), "Backgrounding releases every held touch")
	world.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(not paused and not world.is_paused_for_background(), "Returning to the foreground resumes the session")
	world.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(paused, "Android's application-paused notification pauses Solo too")
	world.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_check(not paused, "Android's application-resumed notification resumes it")
	# A LAN session releases touches but never pauses, because a paused host
	# would stall its client's snapshots.
	world.session.mode = CoopSession.SessionMode.HOST
	world.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not paused and not world.is_paused_for_background(), "A backgrounded LAN session is not paused")
	world.session.mode = CoopSession.SessionMode.SOLO
	world.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(paused, "Solo pauses again before the world is torn down")
	world.queue_free()
	await process_frame
	_check(not paused, "Leaving the world never strands its own pause")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS | %s" % message)
		return
	_failures += 1
	push_error("FAIL | %s" % message)


func _finish() -> void:
	if _failures > 0:
		push_error("SETTINGS LIFECYCLE FAILED (%d/%d checks failed)" % [_failures, _checks])
		quit(1)
		return
	print("SETTINGS LIFECYCLE OK (%d checks)" % _checks)
	quit(0)
