extends Level

const LANE_OFFSETS: Array[int] = [-1, 0, 1]

@export var asteroid_scene: PackedScene
@export_range(5, 20) var lane_count := 6
@export_range(1.0, 1000.0) var asteroid_fall_speed := 180.0
@export_range(80.0, 400.0) var row_spacing := 150.0

@onready var lives_label: Label = %LivesLabel
@onready var pause_menu: Control = %PauseMenu
@onready var spawn_timer: Timer = %AsteroidSpawnTimer
@onready var asteroids: Node2D = $Asteroids

var safe_lane := 0


func _ready() -> void:
	super()
	player.lives_changed.connect(_on_lives_changed)
	_on_lives_changed(player.lives)
	GameManager.state_changed.connect(_on_game_state_changed)
	safe_lane = floori(lane_count / 2.0)
	spawn_timer.wait_time = row_spacing / asteroid_fall_speed
	spawn_timer.timeout.connect(_spawn_asteroid_row)
	spawn_timer.start()
	_spawn_asteroid_row()


func _spawn_asteroid_row() -> void:
	if asteroid_scene == null:
		push_error("Asteroid Level requires an asteroid scene.")
		return
	var lane_offset: int = LANE_OFFSETS.pick_random()
	safe_lane = clampi(safe_lane + lane_offset, 0, lane_count - 1)
	var lane_width := 1280.0 / lane_count
	for lane in lane_count:
		if lane == safe_lane:
			continue
		var asteroid := asteroid_scene.instantiate() as Asteroid
		asteroid.position = Vector2((lane + 0.5) * lane_width, -50.0)
		# asteroid.scale.x = (lane_width - 12.0) / 112.0
		asteroid.fall_speed = asteroid_fall_speed
		asteroids.add_child(asteroid)


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


func _on_debug_hit_pressed() -> void:
	player.take_hit()
