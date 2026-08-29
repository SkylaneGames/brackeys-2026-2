extends Level

const HAPPY_PATH_OFFSETS: Array[int] = [-2, -1, 0, 1, 2]
const RISKY_PATH_OFFSETS: Array[int] = [-1, 0, 1]
const ADVICE_ARROWS: Array[String] = ["<<<", "<<", "<", "|", ">", ">>", ">>>"]

@export var asteroid_scene: PackedScene
@export_range(5, 7) var lane_count := 6
@export_range(1.0, 1000.0) var asteroid_fall_speed := 115.0
@export_range(80.0, 400.0) var row_spacing := 150.0
@export_range(3, 6) var rows_per_sector := 4
@export_range(0.1, 3.0) var trust_handover_delay := 1.0
@export_range(0.0, 1.0) var benign_lie_chance := 0.3
@export var role_swap_interval := 15.0
@export var minimum_role_swap_interval := 8.0
@export var maximum_fall_speed := 220.0

@onready var lives_label: Label = %LivesLabel
@onready var pause_menu: Control = %PauseMenu
@onready var spawn_timer: Timer = %AsteroidSpawnTimer
@onready var asteroids: Node2D = $Asteroids
@onready var alpha_advice: Label = %AlphaAdvice
@onready var beta_advice: Label = %BetaAdvice
@onready var trust_label: Label = %TrustLabel
@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var fog_field: ColorRect = %FogField

var safe_lane := 0
var alpha_is_honest := true
var trusts_alpha := true
var pending_trusts_alpha := true
var trust_handover_left := 0.0
var elapsed_time := 0.0
var score := 0
var role_swap_left := 0.0
var current_fall_speed := 0.0

var alpha_plan: Array[int] = []
var beta_plan: Array[int] = []
var happy_plan: Array[int] = []
var risky_plan: Array[int] = []
var liar_route_is_clear: Array[bool] = []
var active_rows: Array[Dictionary] = []
var sector_row_index := 0


func _ready() -> void:
	super()
	player.lives_changed.connect(_on_lives_changed)
	_on_lives_changed(player.lives)
	GameManager.state_changed.connect(_on_game_state_changed)
	safe_lane = floori(lane_count / 2.0)
	current_fall_speed = asteroid_fall_speed
	role_swap_left = _next_role_swap_interval()
	_generate_sector()
	spawn_timer.wait_time = row_spacing / current_fall_speed
	spawn_timer.timeout.connect(_spawn_asteroid_row)
	spawn_timer.start()
	_spawn_asteroid_row()
	_update_trust_display()


func _process(delta: float) -> void:
	elapsed_time += delta
	score = floori(elapsed_time * 10.0)
	_update_active_rows(delta)
	role_swap_left -= delta
	if role_swap_left <= 0.0:
		alpha_is_honest = not alpha_is_honest
		role_swap_left = _next_role_swap_interval()
	_update_trust_handover(delta)
	_update_difficulty()
	_update_hud()
	run_result_changed.emit(score, elapsed_time)


func _update_active_rows(delta: float) -> void:
	for row in active_rows:
		row["y"] = float(row["y"]) + current_fall_speed * delta
	while not active_rows.is_empty() and float(active_rows[0]["y"]) > player.global_position.y + 70.0:
		active_rows.pop_front()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("trust_alpha"):
		_request_trust_change(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("trust_beta"):
		_request_trust_change(false)
		get_viewport().set_input_as_handled()


func _request_trust_change(next_trusts_alpha: bool) -> void:
	if next_trusts_alpha == trusts_alpha:
		pending_trusts_alpha = trusts_alpha
		trust_handover_left = 0.0
	else:
		pending_trusts_alpha = next_trusts_alpha
		trust_handover_left = trust_handover_delay
	_update_trust_display()


func _update_trust_handover(delta: float) -> void:
	if trust_handover_left <= 0.0:
		return
	trust_handover_left = maxf(trust_handover_left - delta, 0.0)
	if trust_handover_left == 0.0:
		trusts_alpha = pending_trusts_alpha
		_update_trust_display()


func _generate_sector() -> void:
	alpha_plan.clear()
	beta_plan.clear()
	happy_plan.clear()
	risky_plan.clear()
	liar_route_is_clear.clear()
	sector_row_index = 0
	var happy_lane := safe_lane
	var risky_lane := _choose_distinct_lane(happy_lane)
	for row in rows_per_sector:
		var previous_happy_lane := happy_lane
		happy_lane = clampi(happy_lane + HAPPY_PATH_OFFSETS.pick_random(), 0, lane_count - 1)
		# Clamping at an edge may reduce the move, but can never increase it beyond
		# two lanes. Keep the assertion close to generation so this guarantee cannot
		# silently regress as procedural variation is added.
		assert(absi(happy_lane - previous_happy_lane) <= 2)
		risky_lane = clampi(risky_lane + RISKY_PATH_OFFSETS.pick_random(), 0, lane_count - 1)
		if risky_lane == happy_lane:
			risky_lane = _choose_distinct_lane(happy_lane)
		happy_plan.append(happy_lane)
		risky_plan.append(risky_lane)
		liar_route_is_clear.append(randf() < benign_lie_chance)
	safe_lane = happy_plan[happy_plan.size() - 1]
	if alpha_is_honest:
		alpha_plan.assign(happy_plan)
		beta_plan.assign(risky_plan)
	else:
		alpha_plan.assign(risky_plan)
		beta_plan.assign(happy_plan)
	_update_advice()


func _choose_distinct_lane(excluded_lane: int) -> int:
	var options: Array[int] = []
	for lane in lane_count:
		if lane != excluded_lane:
			options.append(lane)
	return options.pick_random()


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
	var lane_width := 1280.0 / lane_count
	for lane in lane_count:
		if lane == honest_lane:
			continue
		if lane == liar_lane and liar_route_is_clear[sector_row_index]:
			continue
		var asteroid := asteroid_scene.instantiate() as Asteroid
		asteroid.position = Vector2((lane + 0.5) * lane_width, -50.0)
		var width_scale := (lane_width - 12.0) / 112.0
		if lane == liar_lane:
			width_scale *= 0.48
		asteroid.scale.x = width_scale
		asteroid.fall_speed = current_fall_speed
		asteroids.add_child(asteroid)
	active_rows.append({
		"alpha_lane": alpha_plan[sector_row_index],
		"beta_lane": beta_plan[sector_row_index],
		"y": -50.0,
	})
	sector_row_index += 1
	_update_advice()


func _update_advice() -> void:
	if player == null or alpha_plan.is_empty():
		return
	alpha_advice.text = _plan_text(_upcoming_lanes(true))
	beta_advice.text = _plan_text(_upcoming_lanes(false))
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


func _plan_text(plan: Array[int]) -> String:
	var player_lane := clampi(floori(player.global_position.x / (1280.0 / lane_count)), 0, lane_count - 1)
	var previous_lane := player_lane
	var vectors: PackedStringArray = []
	for lane in plan:
		vectors.append(_direction_text(lane - previous_lane))
		previous_lane = lane
	return "  ".join(vectors)


func _direction_text(offset: int) -> String:
	return ADVICE_ARROWS[clampi(offset + 3, 0, ADVICE_ARROWS.size() - 1)]


func _update_guidance_and_fog() -> void:
	if alpha_plan.is_empty():
		return
	var active_plan := _upcoming_lanes(trusts_alpha)
	if active_plan.is_empty():
		return
	var lane_width := 1280.0 / lane_count
	player.set_navigation_target_x((active_plan[0] + 0.5) * lane_width)
	var fog_material := fog_field.material as ShaderMaterial
	if fog_material == null:
		return
	var fog_height := 720.0 - 108.0
	var ship_uv := Vector2(
		player.global_position.x / 1280.0,
		clampf((player.global_position.y - 108.0) / fog_height, 0.0, 1.0)
	)
	fog_material.set_shader_parameter("ship_uv", ship_uv)
	var trust_tint := Color("172c50") if trusts_alpha else Color("421b36")
	fog_material.set_shader_parameter("fog_color", Color(trust_tint, 0.94))


func _next_role_swap_interval() -> float:
	var upper_bound := maxf(minimum_role_swap_interval, role_swap_interval - elapsed_time * 0.06)
	return randf_range(minimum_role_swap_interval, upper_bound)


func _update_difficulty() -> void:
	var next_speed := minf(maximum_fall_speed, asteroid_fall_speed + elapsed_time * 0.55)
	if is_equal_approx(next_speed, current_fall_speed):
		return
	current_fall_speed = next_speed
	spawn_timer.wait_time = row_spacing / current_fall_speed
	for child in asteroids.get_children():
		var asteroid := child as Asteroid
		if asteroid != null:
			asteroid.set_fall_speed(current_fall_speed)


func _update_hud() -> void:
	score_label.text = "SCORE  %06d" % score
	time_label.text = "TIME  %02d:%02d" % [floori(elapsed_time) / 60, floori(elapsed_time) % 60]
	_update_advice()
	if trust_handover_left > 0.0:
		_update_trust_display()


func _update_trust_display() -> void:
	if trust_handover_left > 0.0:
		trust_label.text = "LINKING %s  %.1f" % ["ALPHA" if pending_trusts_alpha else "BETA", trust_handover_left]
		trust_label.modulate = Color("f6d365")
	else:
		trust_label.text = "TRUST: %s" % ("ALPHA" if trusts_alpha else "BETA")
		trust_label.modulate = Color("63e6ff") if trusts_alpha else Color("ff6aa9")
	_update_guidance_and_fog()


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
