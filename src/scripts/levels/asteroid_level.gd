extends Level

const RISKY_PATH_OFFSETS: Array[int] = [-1, 0, 1]
const ROW_CLEARANCE_DISTANCE := 70.0
const NORMAL_REVEAL_RADIUS := 0.19
const NORMAL_EDGE_FEATHER := 0.095
const CORRECTION_REVEAL_RADIUS := 0.115
const CORRECTION_EDGE_FEATHER := 0.055
const UNTRUSTED_REVEAL_RADIUS := 0.16
const UNTRUSTED_EDGE_FEATHER := 0.075

enum TrustedAi { NONE, ALPHA, BETA }

@export var asteroid_scene: PackedScene
@export var repair_pickup_scene: PackedScene
@export_range(5, 20) var lane_count := 8
@export_range(1.0, 1000.0) var asteroid_fall_speed := 180.0
@export_range(80.0, 400.0) var row_spacing := 150.0
@export_range(3, 6) var rows_per_sector := 4
@export_range(0.0, 3.0) var trust_handover_delay := 0.25
@export_range(0.0, 1.0) var benign_lie_chance := 0.45
@export_range(0.4, 0.9) var asteroid_lane_fill_ratio := 0.6
@export_range(0.3, 1.0) var risky_asteroid_scale := 0.55
@export_range(0.0, 1.0) var two_lane_move_chance := 0.10
@export_range(0.0, 1.0) var repair_sector_chance := 0.7
@export_range(1.0, 2.0) var trusted_game_speed_multiplier := 1.3
@export var speed_transition_rate := 180.0
@export var escape_distance := 9000.0
@export var escape_time_limit := 100.0
@export var role_swap_interval := 15.0
@export var minimum_role_swap_interval := 8.0
@export var maximum_fall_speed := 220.0

@onready var lives_label: Label = %LivesLabel
@onready var pause_menu: Control = %PauseMenu
@onready var spawn_timer: Timer = %AsteroidSpawnTimer
@onready var asteroids: Node2D = $Asteroids
@onready var alpha_route_preview = %AlphaRoutePreview
@onready var beta_route_preview = %BetaRoutePreview
@onready var trust_label: Label = %TrustLabel
@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var escape_progress: ProgressBar = %EscapeProgress
@onready var fog_field: ColorRect = %FogField
@onready var debug_trust_button: Button = %DebugTrustButton
@onready var alpha_ai: NavAi = %AlphaAI
@onready var beta_ai: NavAi = %BetaAI

var safe_lane := 0
var alpha_is_honest := true
var trusted_ai := TrustedAi.ALPHA
var pending_trusted_ai := TrustedAi.ALPHA
var trust_handover_left := 0.0
var elapsed_time := 0.0
var score := 0
var role_swap_left := 0.0
var current_fall_speed := 0.0
var sector_happy_is_alpha := true
var debug_trust_revealed := false
var correction_fog_blend := 0.0
var distance_remaining := 0.0
var run_finished := false
var displayed_manual_state := false

var alpha_plan: Array[int] = []
var beta_plan: Array[int] = []
var happy_plan: Array[int] = []
var risky_plan: Array[int] = []
var liar_route_is_clear: Array[bool] = []
var sector_repair_row := -1
var active_rows: Array[Dictionary] = []
var sector_row_index := 0


func _ready() -> void:
	super()
	player.lives_changed.connect(_on_lives_changed)
	_on_lives_changed(player.lives)
	GameManager.state_changed.connect(_on_game_state_changed)
	debug_trust_button.pressed.connect(_on_debug_trust_pressed)
	safe_lane = floori(lane_count / 2.0)
	current_fall_speed = asteroid_fall_speed
	distance_remaining = escape_distance
	escape_progress.max_value = escape_distance
	role_swap_left = _next_role_swap_interval()
	_generate_sector()
	spawn_timer.wait_time = row_spacing / current_fall_speed
	spawn_timer.timeout.connect(_spawn_asteroid_row)
	spawn_timer.start()
	_spawn_asteroid_row()
	_update_trust_display()


func _process(delta: float) -> void:
	if run_finished:
		return
	elapsed_time += delta
	score = floori(elapsed_time * 10.0)
	_update_difficulty(delta)
	distance_remaining = maxf(distance_remaining - current_fall_speed * delta, 0.0)
	_update_active_rows(delta)
	role_swap_left -= delta
	if role_swap_left <= 0.0:
		alpha_is_honest = not alpha_is_honest
		role_swap_left = _next_role_swap_interval()
	_update_trust_handover(delta)
	_update_correction_visibility(delta)
	if displayed_manual_state != player.is_correcting:
		displayed_manual_state = player.is_correcting
		if player.is_correcting:
			_clear_trust()
		_update_trust_display()
	_update_hud()
	run_result_changed.emit(score, elapsed_time)
	if distance_remaining <= 0.0:
		_finish_run(true)
	elif elapsed_time >= escape_time_limit:
		_finish_run(false)


func _update_active_rows(delta: float) -> void:
	for row in active_rows:
		row["y"] = float(row["y"]) + current_fall_speed * delta
	while not active_rows.is_empty() and float(active_rows[0]["y"]) > player.global_position.y + ROW_CLEARANCE_DISTANCE:
		active_rows.pop_front()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("trust_alpha"):
		_request_trust_change(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("trust_beta"):
		_request_trust_change(false)
		get_viewport().set_input_as_handled()


func _request_trust_change(next_trusts_alpha: bool) -> void:
	var requested_ai := TrustedAi.ALPHA if next_trusts_alpha else TrustedAi.BETA
	if requested_ai == trusted_ai:
		pending_trusted_ai = trusted_ai
		trust_handover_left = 0.0
	elif trust_handover_left > 0.0 and requested_ai == pending_trusted_ai:
		# Repeated input for the pending AI must not restart the handover.
		return
	else:
		pending_trusted_ai = requested_ai
		trust_handover_left = trust_handover_delay
	_update_trust_display()


func _update_trust_handover(delta: float) -> void:
	if trust_handover_left <= 0.0:
		return
	trust_handover_left = maxf(trust_handover_left - delta, 0.0)
	if trust_handover_left == 0.0:
		trusted_ai = pending_trusted_ai
		_update_trust_display()


func _clear_trust() -> void:
	trusted_ai = TrustedAi.NONE
	pending_trusted_ai = TrustedAi.NONE
	trust_handover_left = 0.0
	player.set_navigation_enabled(false)
	player.set_navigation_speed_multiplier(1.0)


func _generate_sector() -> void:
	alpha_plan.clear()
	beta_plan.clear()
	happy_plan.clear()
	risky_plan.clear()
	liar_route_is_clear.clear()
	sector_row_index = 0
	sector_repair_row = randi_range(0, rows_per_sector - 1) if player.lives < player.starting_lives and randf() < repair_sector_chance else -1
	var happy_lane := safe_lane
	var risky_lane := _choose_distinct_lane(happy_lane)
	for row in rows_per_sector:
		var previous_happy_lane := happy_lane
		happy_lane = clampi(happy_lane + _happy_path_offset(), 0, lane_count - 1)
		# Clamping at an edge may reduce the move, but can never increase it beyond
		# two lanes. Keep the assertion close to generation so this guarantee cannot
		# silently regress as procedural variation is added.
		assert(absi(happy_lane - previous_happy_lane) <= 2)
		risky_lane = clampi(risky_lane + RISKY_PATH_OFFSETS.pick_random(), 0, lane_count - 1)
		if risky_lane == happy_lane:
			risky_lane = _choose_distinct_lane(happy_lane)
		happy_plan.append(happy_lane)
		risky_plan.append(risky_lane)
		# Repair rows make both choices safe; the better read earns recovery.
		liar_route_is_clear.append(row == sector_repair_row or randf() < benign_lie_chance)
	safe_lane = happy_plan[happy_plan.size() - 1]
	if alpha_is_honest:
		alpha_plan.assign(happy_plan)
		beta_plan.assign(risky_plan)
	else:
		alpha_plan.assign(risky_plan)
		beta_plan.assign(happy_plan)
	sector_happy_is_alpha = alpha_is_honest
	_update_advice()


func _choose_distinct_lane(excluded_lane: int) -> int:
	var options: Array[int] = []
	for lane in lane_count:
		if lane != excluded_lane:
			options.append(lane)
	return options.pick_random()


func _happy_path_offset() -> int:
	if randf() < two_lane_move_chance:
		return -2 if randf() < 0.5 else 2
	var roll := randf()
	if roll < 0.34:
		return -1
	if roll < 0.68:
		return 1
	return 0


func _spawn_asteroid_row() -> void:
	if asteroid_scene == null:
		push_error("Asteroid Level requires an asteroid scene.")
		return
	if sector_row_index >= rows_per_sector:
		_generate_sector()
	# These routes are fixed when the sector is generated. A role swap may change
	# which AI receives the happy plan next sector, but cannot mutate rows already
	# promised to the player.
	var honest_lane := happy_plan[sector_row_index]
	var liar_lane := risky_plan[sector_row_index]
	var has_repair := sector_row_index == sector_repair_row
	var lane_width := 1280.0 / lane_count
	# The camera follows the ship laterally. Solid buffer lanes outside the playable
	# eight-lane field ensure that tracking never exposes an empty edge of the map.
	var border_lane_count := ceili(640.0 / lane_width) + 1
	for lane in range(-border_lane_count, lane_count + border_lane_count):
		if lane == honest_lane:
			continue
		if lane == liar_lane and liar_route_is_clear[sector_row_index]:
			continue
		var asteroid := asteroid_scene.instantiate() as Asteroid
		asteroid.position = Vector2((lane + 0.5) * lane_width, -50.0)
		# Standard asteroids deliberately leave a narrow manual-piloting route
		# between occupied lanes, while the guaranteed lane remains comfortably
		# wider. Scale uniformly so the art and collision shape stay asteroid-sized
		# rather than becoming wide horizontal walls.
		var asteroid_scale := lane_width * asteroid_lane_fill_ratio / 112.0
		if lane == liar_lane:
			asteroid_scale *= risky_asteroid_scale
			asteroid.set_destructible(true)
		asteroid.scale = Vector2.ONE * asteroid_scale
		asteroid.fall_speed = current_fall_speed
		asteroids.add_child(asteroid)
	if has_repair and repair_pickup_scene != null:
		var pickup = repair_pickup_scene.instantiate()
		pickup.position = Vector2((honest_lane + 0.5) * lane_width, -50.0)
		pickup.set_fall_speed(current_fall_speed)
		asteroids.add_child(pickup)
	active_rows.append({
		"alpha_lane": alpha_plan[sector_row_index],
		"beta_lane": beta_plan[sector_row_index],
		"happy_is_alpha": sector_happy_is_alpha,
		"has_repair": has_repair,
		"y": -50.0,
	})
	sector_row_index += 1
	_update_advice()


func _update_advice() -> void:
	if player == null or alpha_plan.is_empty():
		return
	var player_lane := clampi(floori(player.global_position.x / (1280.0 / lane_count)), 0, lane_count - 1)
	alpha_route_preview.set_route(_upcoming_lanes(true), player_lane, _upcoming_repair_step(true))
	beta_route_preview.set_route(_upcoming_lanes(false), player_lane, _upcoming_repair_step(false))
	_update_guidance_and_fog()


func _upcoming_lanes(for_alpha: bool) -> Array[int]:
	var lanes: Array[int] = []
	for row in active_rows:
		if lanes.size() >= rows_per_sector:
			break
		lanes.append(int(row["alpha_lane"] if for_alpha else row["beta_lane"]))
	for index in range(sector_row_index, rows_per_sector):
		if lanes.size() >= rows_per_sector:
			break
		lanes.append(alpha_plan[index] if for_alpha else beta_plan[index])
	return lanes


func _upcoming_repair_step(for_alpha: bool) -> int:
	var step := 0
	for row in active_rows:
		if step >= rows_per_sector:
			return -1
		if bool(row["has_repair"]) and bool(row["happy_is_alpha"]) == for_alpha:
			return step
		step += 1
	for index in range(sector_row_index, rows_per_sector):
		if step >= rows_per_sector:
			break
		if index == sector_repair_row and sector_happy_is_alpha == for_alpha:
			return step
		step += 1
	return -1


func _update_guidance_and_fog() -> void:
	if alpha_plan.is_empty():
		return
	var has_trusted_ai := trusted_ai != TrustedAi.NONE
	player.set_navigation_enabled(has_trusted_ai and not player.is_correcting)
	player.set_navigation_speed_multiplier(trusted_game_speed_multiplier if has_trusted_ai else 1.0)
	if not has_trusted_ai:
		_update_fog()
		return
	var navigation_lane := _navigation_lane(trusted_ai == TrustedAi.ALPHA)
	if navigation_lane < 0:
		return
	var lane_width := 1280.0 / lane_count
	player.set_navigation_target_x((navigation_lane + 0.5) * lane_width)
	_update_fog()


func _update_fog() -> void:
	var fog_material := fog_field.material as ShaderMaterial
	if fog_material == null:
		return
	var ship_screen_position := player.get_global_transform_with_canvas().origin
	var ship_uv := Vector2(
		clampf(ship_screen_position.x / 1280.0, 0.0, 1.0),
		clampf(ship_screen_position.y / 720.0, 0.0, 1.0)
	)
	fog_material.set_shader_parameter("ship_uv", ship_uv)
	var trust_tint := Color("172c50") if trusted_ai == TrustedAi.ALPHA else Color("421b36")
	if trusted_ai == TrustedAi.NONE or player.is_correcting:
		trust_tint = Color("17212d")
	var base_radius := UNTRUSTED_REVEAL_RADIUS if trusted_ai == TrustedAi.NONE else NORMAL_REVEAL_RADIUS
	var base_feather := UNTRUSTED_EDGE_FEATHER if trusted_ai == TrustedAi.NONE else NORMAL_EDGE_FEATHER
	fog_material.set_shader_parameter("fog_color", Color(trust_tint, lerpf(0.94, 0.99, correction_fog_blend)))
	fog_material.set_shader_parameter("reveal_radius", lerpf(base_radius, CORRECTION_REVEAL_RADIUS, correction_fog_blend))
	fog_material.set_shader_parameter("edge_feather", lerpf(base_feather, CORRECTION_EDGE_FEATHER, correction_fog_blend))


func _update_correction_visibility(delta: float) -> void:
	var target := 1.0 if player.is_correcting else 0.0
	correction_fog_blend = move_toward(correction_fog_blend, target, delta * 5.0)


func _navigation_lane(for_alpha: bool) -> int:
	# Keep steering through the current gap until its collision shapes have passed
	# the ship. Advancing based on lookahead made the ship visibly leave a safe gap
	# before it had actually cleared the row.
	var guidance_row := _guidance_row()
	if not guidance_row.is_empty():
		return int(guidance_row["alpha_lane"] if for_alpha else guidance_row["beta_lane"])
	var planned_lanes := _upcoming_lanes(for_alpha)
	return planned_lanes[0] if not planned_lanes.is_empty() else -1


func _guidance_row() -> Dictionary:
	return active_rows[0] if not active_rows.is_empty() else {}


func _right_ai_for_guidance() -> String:
	var guidance_row := _guidance_row()
	var right_is_alpha := sector_happy_is_alpha
	if not guidance_row.is_empty():
		right_is_alpha = bool(guidance_row["happy_is_alpha"])
	return "ALPHA" if right_is_alpha else "BETA"


func _next_role_swap_interval() -> float:
	var upper_bound := maxf(minimum_role_swap_interval, role_swap_interval - elapsed_time * 0.06)
	return randf_range(minimum_role_swap_interval, upper_bound)


func _update_difficulty(delta: float) -> void:
	var cruise_speed := minf(maximum_fall_speed, asteroid_fall_speed + elapsed_time * 0.55)
	var target_speed := cruise_speed * (trusted_game_speed_multiplier if trusted_ai != TrustedAi.NONE else 1.0)
	var next_speed := move_toward(current_fall_speed, target_speed, speed_transition_rate * delta)
	if is_equal_approx(next_speed, current_fall_speed):
		return
	current_fall_speed = next_speed
	spawn_timer.wait_time = row_spacing / current_fall_speed
	for child in asteroids.get_children():
		var asteroid := child as Asteroid
		if asteroid != null:
			asteroid.set_fall_speed(current_fall_speed)
		elif child.has_method("set_fall_speed"):
			child.set_fall_speed(current_fall_speed)


func _update_hud() -> void:
	score_label.text = "SCORE  %06d" % score
	var time_left := maxi(ceili(escape_time_limit - elapsed_time), 0)
	time_label.text = "ESCAPE  %02d:%02d" % [time_left / 60, time_left % 60]
	escape_progress.value = escape_distance - distance_remaining
	_update_advice()
	if trust_handover_left > 0.0:
		_update_trust_display()
	_update_debug_trust_display()


func _update_trust_display() -> void:
	if trusted_ai == TrustedAi.NONE and trust_handover_left <= 0.0:
		trust_label.text = "TRUST NO ONE"
		trust_label.modulate = Color("b7c7dd")
	elif trust_handover_left > 0.0:
		trust_label.text = "LINKING %s  %.1f" % ["ALPHA" if pending_trusted_ai == TrustedAi.ALPHA else "BETA", trust_handover_left]
		trust_label.modulate = Color("f6d365")
	else:
		trust_label.text = "TRUST: %s" % ("ALPHA" if trusted_ai == TrustedAi.ALPHA else "BETA")
		trust_label.modulate = Color("63e6ff") if trusted_ai == TrustedAi.ALPHA else Color("ff6aa9")
	var trust_is_active := trusted_ai != TrustedAi.NONE and trust_handover_left <= 0.0
	alpha_ai.set_active(trust_is_active and trusted_ai == TrustedAi.ALPHA)
	beta_ai.set_active(trust_is_active and trusted_ai == TrustedAi.BETA)
	alpha_route_preview.visible = trusted_ai != TrustedAi.NONE
	beta_route_preview.visible = trusted_ai != TrustedAi.NONE
	alpha_route_preview.set_active(trust_is_active and trusted_ai == TrustedAi.ALPHA)
	beta_route_preview.set_active(trust_is_active and trusted_ai == TrustedAi.BETA)
	_update_guidance_and_fog()


func _finish_run(escaped: bool) -> void:
	if run_finished:
		return
	run_finished = true
	spawn_timer.stop()
	if escaped:
		completed.emit()
	else:
		failed.emit(Level.FailureReason.ENVIRONMENT)


func _on_lives_changed(lives: int) -> void:
	lives_label.text = "LIVES: %d" % lives


func _on_game_state_changed(state: GameManager.GameState) -> void:
	pause_menu.visible = state == GameManager.GameState.PAUSED


func _on_resume_pressed() -> void:
	GameManager.set_paused(false)


func _on_restart_pressed() -> void:
	GameManager.restart_run()


func _on_exit_pressed() -> void:
	GameManager.return_to_title()


func _on_debug_trust_pressed() -> void:
	debug_trust_revealed = not debug_trust_revealed
	_update_debug_trust_display()


func _update_debug_trust_display() -> void:
	if not debug_trust_revealed:
		debug_trust_button.text = "DEBUG: REVEAL STEERING AI"
		debug_trust_button.modulate = Color.WHITE
		return
	var right_ai := _right_ai_for_guidance()
	var trusted_name := "NONE"
	if trusted_ai == TrustedAi.ALPHA:
		trusted_name = "ALPHA"
	elif trusted_ai == TrustedAi.BETA:
		trusted_name = "BETA"
	var matches := right_ai == trusted_name
	# This describes the uncleared row that currently drives the ship.
	debug_trust_button.text = "STEERING: %s   TRUST: %s" % [right_ai, "MATCH" if matches else "NONE" if trusted_ai == TrustedAi.NONE else "MISS"]
	debug_trust_button.modulate = Color("7dff9b") if matches else Color("ff8b8b")
