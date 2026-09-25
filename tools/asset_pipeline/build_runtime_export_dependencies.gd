extends SceneTree
## Writes the strong-retain export scene from the runtime closure manifest.
##
## `runtime_export_dependencies.tscn` exists so the Android exporter packs every
## resource the game reaches by name rather than by reference - a `class_name`
## built with `.new()`, a shader named by a `String` constant - which no
## scene-graph walk can find. It used to be hand-maintained, and it also sat
## under an unanchored `build/` ignore rule, so it lived on one machine and never
## reached git. This tool derives it from `data/runtime_export_closure.json`
## instead, in closure order with the manifest itself appended, so the scene can
## only ever say what the closure says. Re-run it after any closure edit.
##
## Usage: godot --headless --path . --script res://tools/asset_pipeline/build_runtime_export_dependencies.gd

const CLOSURE_PATH: String = "res://data/runtime_export_closure.json"
const SCENE_PATH: String = "res://scenes/build/runtime_export_dependencies.tscn"
const ROOT_NAME: StringName = &"RuntimeExportDependencies"


func _initialize() -> void:
	call_deferred(&"_build")


func _build() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLOSURE_PATH))
	if not (parsed is Dictionary):
		_fail("closure manifest does not parse as a dictionary")
		return
	var entries: Array = (parsed as Dictionary).get("resources", []) as Array
	if entries.is_empty():
		_fail("closure manifest lists no resources")
		return

	var dependencies: Array[Resource] = []
	var seen: Dictionary[String, bool] = {}
	for entry_variant: Variant in entries:
		if not (entry_variant is Dictionary):
			_fail("closure entry is not a dictionary")
			return
		var path: String = String((entry_variant as Dictionary).get("path", ""))
		if seen.has(path):
			_fail("duplicate closure path %s" % path)
			return
		seen[path] = true
		var resource: Resource = ResourceLoader.load(path)
		if resource == null:
			_fail("closure resource does not load: %s" % path)
			return
		dependencies.append(resource)
	var closure_resource: Resource = ResourceLoader.load(CLOSURE_PATH)
	if closure_resource == null:
		_fail("closure manifest does not load as a resource")
		return
	dependencies.append(closure_resource)

	var root: Node = Node.new()
	root.name = ROOT_NAME
	root.set_meta(&"export_dependencies", dependencies)
	root.set_meta(&"export_dependency_count", dependencies.size())
	var packed: PackedScene = PackedScene.new()
	var pack_error: Error = packed.pack(root)
	root.free()
	if pack_error != OK:
		_fail("could not pack scene: %s" % error_string(pack_error))
		return

	# Keep the scene's UID stable across regenerations. The per-save ext_resource
	# ids still change, so compare two builds by their resource list, not bytes.
	var previous_uid: int = ResourceLoader.get_resource_uid(SCENE_PATH)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_PATH.get_base_dir()))
	var save_error: Error = ResourceSaver.save(packed, SCENE_PATH)
	if save_error != OK:
		_fail("could not save %s: %s" % [SCENE_PATH, error_string(save_error)])
		return
	if previous_uid != ResourceUID.INVALID_ID:
		ResourceSaver.set_uid(SCENE_PATH, previous_uid)
	print(
		"RUNTIME EXPORT DEPENDENCIES OK | resources=%d | dependencies=%d | scene=%s"
		% [entries.size(), dependencies.size(), SCENE_PATH]
	)
	quit(0)


func _fail(message: String) -> void:
	push_error("RUNTIME EXPORT DEPENDENCIES FAILED: %s" % message)
	quit(1)
