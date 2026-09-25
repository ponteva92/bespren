extends SceneTree
## Deterministic regression gate for authoritative movement, rate limits, and host-loss reset.

var _checks: int = 0
var _failures: int = 0
var _interaction_count: int = 0
var _projectile_count: int = 0
var _last_projectile_direction: Vector2 = Vector2.ZERO
var _resolver_calls: int = 0


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_validate_rpc_transfer_contracts()
	_validate_defense_rpc_contracts()
	await _validate_host_authority_and_interaction_limit()
	await _validate_established_client_fallback()
	if _failures == 0:
		print("COOP HARDENING OK (%d checks)" % _checks)
	else:
		push_error("COOP HARDENING FAILED (%d/%d checks failed)" % [_failures, _checks])
	quit(_failures)


func _validate_rpc_transfer_contracts() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/coop/coop_session.gd")
	_check(
		source.contains(
			"@rpc(\"any_peer\", \"call_local\", \"unreliable_ordered\")\n"
			+ "func _request_movement"
		),
		"Replaceable movement requests use unreliable-ordered delivery"
	)
	_check(
		source.contains(
			"@rpc(\"authority\", \"call_local\", \"unreliable_ordered\")\n"
			+ "func _broadcast_authoritative_state"
		),
		"Replaceable authoritative snapshots use unreliable-ordered delivery"
	)
	_check(
		source.contains(
			"@rpc(\"any_peer\", \"call_local\", \"reliable\")\n"
			+ "func _request_registration"
		),
		"Registration remains reliable"
	)
	_check(
		source.contains(
			"@rpc(\"any_peer\", \"call_local\", \"reliable\")\n"
			+ "func _request_interaction"
		),
		"Interaction requests remain reliable"
	)


func _validate_defense_rpc_contracts() -> void:
	var build_source: String = FileAccess.get_file_as_string(
		"res://src/tactical/tactical_build_system.gd"
	)
	var structure_source: String = FileAccess.get_file_as_string(
		"res://src/tactical/placed_structure_2d.gd"
	)
	var controller_source: String = FileAccess.get_file_as_string(
		"res://src/tactical/tower_targeting_controller_2d.gd"
	)
	var flow_source: String = FileAccess.get_file_as_string(
		"res://src/ai/flow_field_navigation_2d.gd"
	)
	_check(
		build_source.contains("@rpc(\"any_peer\", \"call_local\", \"reliable\")")
		and build_source.contains("func _request_structure_placement")
		and build_source.contains("if not multiplayer.is_server():")
		and build_source.contains("var source_peer_id: int = _get_requesting_peer_id()"),
		"Client build requests remain reliable and are validated only by peer one"
	)
	_check(
		build_source.contains(
			"@rpc(\"authority\", \"call_remote\", \"reliable\")\n"
			+ "func _commit_structure_runtime_state"
		),
		"Health and EMP lifecycle commits are reliable authority-only remote state"
	)
	_check(
		build_source.contains("runtime_revisions: PackedInt32Array")
		and build_source.contains("health_values: PackedInt32Array")
		and build_source.contains("emp_remaining_values: PackedFloat32Array")
		and build_source.contains("aim_directions: PackedVector2Array")
		and build_source.contains("cooldown_remaining_values: PackedFloat32Array")
		and build_source.contains("target_ids: PackedInt32Array")
		and build_source.contains("seen_instance_ids: Dictionary[int, bool]"),
		"Late-join defense snapshot carries and validates runtime lifecycle arrays"
	)
	_check(
		structure_source.contains("if not _authority_enabled or amount <= 0")
		and structure_source.contains("if not _authority_enabled or not is_finite(duration_seconds)")
		and structure_source.contains("func apply_runtime_snapshot("),
		"Client structure shells reject damage and EMP mutation but accept authoritative snapshots"
	)
	_check(
		controller_source.contains("## Host-only radial tower targeting")
		and controller_source.contains("target.apply_movement_slow(")
		and flow_source.contains("or not structure.blocks_navigation()"),
		"Trap slow/root effects stay in the host controller while nonblocking traps stay out of flow rasterization"
	)


func _validate_host_authority_and_interaction_limit() -> void:
	var session: CoopSession = CoopSession.new()
	session.name = &"AuthoritySession"
	root.add_child(session)
	session.set_physics_process(false)
	session.interaction_received.connect(_on_interaction_received)
	session.projectile_fired.connect(_on_projectile_fired)
	session.set_motion_resolver(_block_motion)
	session.start_solo(&"heikki")
	var peer_id: int = CoopSession.AUTHORITY_PEER_ID
	var starting_position: Vector2 = session.get_authoritative_position(peer_id)
	session.submit_movement(Vector2.RIGHT)
	session._physics_process(0.1)
	_check(_resolver_calls == 1, "Host movement invokes the world collision resolver")
	_check(
		session.get_authoritative_position(peer_id).is_equal_approx(starting_position),
		"Host collision authority can reject blocked movement"
	)
	session.submit_interaction(&"interact")
	session.submit_interaction(&"fire")
	_check(_interaction_count == 1, "Per-peer cooldown rejects same-tick interaction spam")
	_check(not session.is_interaction_ready(peer_id), "Accepted interaction arms its cooldown")
	_check(
		session.get_interaction_cooldown_remaining(peer_id) > 0.0,
		"Cooldown exposes a positive deterministic remaining interval"
	)
	session._physics_process(CoopSession.INTERACTION_COOLDOWN_SECONDS + 0.001)
	session.submit_interaction(&"fire")
	_check(_interaction_count == 2, "Interaction is accepted after the host clock advances")
	_check(_projectile_count == 1, "Only an accepted fire interaction emits a projectile")
	_check(
		_last_projectile_direction.is_equal_approx(Vector2.RIGHT),
		"Projectile follows the host-validated player facing direction"
	)
	session.queue_free()
	await process_frame


func _validate_established_client_fallback() -> void:
	var world_scene: PackedScene = load("res://scenes/game/game_world.tscn") as PackedScene
	var world: GameWorld = world_scene.instantiate() as GameWorld
	world.configure_launch(CoopSession.SessionMode.SOLO, &"heikki", "127.0.0.1")
	root.add_child(world)
	for _frame_index: int in range(3):
		await process_frame
	var session: CoopSession = world.get_node("CoopSession") as CoopSession
	var players_root: Node2D = world.get_node("YSortWorld/Players") as Node2D
	_check(players_root.get_child_count() == 1, "World starts with one local authority avatar")
	var original_player: PlayerAvatar = players_root.get_child(0) as PlayerAvatar
	var original_instance_id: int = original_player.get_instance_id()

	# Recreate the state an established client holds after receiving the host roster.
	session._prepare_session(&"shane")
	_check(players_root.get_child_count() == 0, "Roster reset immediately detaches stale avatars")
	session.mode = CoopSession.SessionMode.CLIENT
	session._announce_registration(1, &"heikki", Vector2(-220.0, 285.0))
	session._announce_registration(9, &"shane", Vector2(360.0, 380.0))
	_check(
		session.get_registered_peer_ids() == [1, 9],
		"Client mirrors the authoritative roster for later cleanup"
	)
	_check(players_root.get_child_count() == 2, "Established client presents the mirrored roster")
	var remote_player: PlayerAvatar = _find_player(players_root, 9)
	_check(remote_player != null, "Mirrored client roster includes its assigned avatar")
	if remote_player != null:
		var snapshot_position: Vector2 = Vector2(3200.0, -1800.0)
		remote_player.apply_authoritative_state(snapshot_position, Vector2.RIGHT)
		remote_player._physics_process(0.05)
		_check(
			remote_player.global_position.is_equal_approx(snapshot_position),
			"A large authoritative correction snaps the physics-backed presentation"
		)

	session._fallback_to_solo("Deterministic host-loss fallback")
	await process_frame
	_check(session.mode == CoopSession.SessionMode.SOLO, "Established client falls back to Solo")
	_check(
		session.get_registered_peer_ids() == [CoopSession.AUTHORITY_PEER_ID],
		"Fallback discards the remote roster and registers only peer one"
	)
	_check(players_root.get_child_count() == 1, "Fallback leaves exactly one avatar in GameWorld")
	var fallback_player: PlayerAvatar = players_root.get_child(0) as PlayerAvatar
	_check(
		fallback_player.get_instance_id() != original_instance_id,
		"Fallback local avatar replaces the stale pre-transition instance"
	)
	_check(
		fallback_player.peer_id == CoopSession.AUTHORITY_PEER_ID
		and fallback_player.character_id == &"shane"
		and fallback_player.is_local_player,
		"Fallback re-registers the selected character as local peer one"
	)
	_check(fallback_player.camera.enabled, "Fallback enables the new local peer-one camera")
	_check(fallback_player is CharacterBody2D, "Player presentation uses CharacterBody2D physics")
	var collision: CollisionShape2D = fallback_player.get_node("CollisionShape2D") as CollisionShape2D
	var circle: CircleShape2D = collision.shape as CircleShape2D
	_check(collision != null and not collision.disabled, "Player owns an active collision shape")
	_check(
		circle != null and is_equal_approx(circle.radius, CoopSession.PLAYER_COLLISION_RADIUS),
		"Player collision radius matches host-authoritative motion resolution"
	)
	_check(
		fallback_player.collision_layer == 1 and fallback_player.collision_mask == 2,
		"Player collision filters target WorldStatic obstacles"
	)
	world.queue_free()
	await process_frame


func _find_player(players_root: Node2D, peer_id: int) -> PlayerAvatar:
	for child: Node in players_root.get_children():
		var player: PlayerAvatar = child as PlayerAvatar
		if player != null and player.peer_id == peer_id:
			return player
	return null


func _block_motion(
	current_position: Vector2,
	_next_position: Vector2,
	_collision_radius: float
) -> Vector2:
	_resolver_calls += 1
	return current_position


func _on_interaction_received(
	_peer_id: int,
	_interaction: StringName,
	_position: Vector2
) -> void:
	_interaction_count += 1


func _on_projectile_fired(
	_peer_id: int,
	_position: Vector2,
	direction: Vector2
) -> void:
	_projectile_count += 1
	_last_projectile_direction = direction


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("PASS | %s" % message)
		return
	_failures += 1
	push_error("FAIL | %s" % message)
