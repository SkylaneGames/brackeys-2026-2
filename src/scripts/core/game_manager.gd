extends Node

enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER }
enum FailureReason { PLAYER_DIED, LEVEL_FAILED }

signal state_changed(state: GameState)

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/game_over_screen.tscn"
const LEVEL_SCENES: Array[String] = ["res://scenes/levels/asteroid_level.tscn"]

var state: GameState = GameState.TITLE
var current_level_index := 0
var last_failure_reason := FailureReason.PLAYER_DIED
var final_score := 0
var final_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and state in [GameState.PLAYING, GameState.PAUSED]:
		set_paused(state == GameState.PLAYING)
		get_viewport().set_input_as_handled()


func start_run() -> void:
	current_level_index = 0
	final_score = 0
	final_time = 0.0
	get_tree().paused = false
	_set_state(GameState.PLAYING)
	_change_scene(LEVEL_SCENES[current_level_index])


func restart_run() -> void:
	start_run()


func register_level(level: Level) -> void:
	level.completed.connect(_on_level_completed)
	level.failed.connect(_on_level_failed)
	level.player_died.connect(_on_player_died)
	level.run_result_changed.connect(_on_run_result_changed)


func set_paused(paused: bool) -> void:
	if state not in [GameState.PLAYING, GameState.PAUSED]:
		return
	get_tree().paused = paused
	_set_state(GameState.PAUSED if paused else GameState.PLAYING)


func return_to_title() -> void:
	get_tree().paused = false
	_set_state(GameState.TITLE)
	_change_scene(TITLE_SCENE)


func _on_level_completed() -> void:
	current_level_index += 1
	if current_level_index < LEVEL_SCENES.size():
		_change_scene(LEVEL_SCENES[current_level_index])
	else:
		# The current game is endless. This branch is retained for future finite levels.
		return_to_title()


func _on_level_failed(reason: Level.FailureReason) -> void:
	last_failure_reason = FailureReason.LEVEL_FAILED
	_show_game_over()


func _on_player_died() -> void:
	last_failure_reason = FailureReason.PLAYER_DIED
	_show_game_over()


func _on_run_result_changed(score: int, elapsed_time: float) -> void:
	final_score = score
	final_time = elapsed_time


func _show_game_over() -> void:
	get_tree().paused = false
	_set_state(GameState.GAME_OVER)
	_change_scene(GAME_OVER_SCENE)


func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s (error %s)." % [path, error])


func _set_state(next_state: GameState) -> void:
	state = next_state
	state_changed.emit(state)
