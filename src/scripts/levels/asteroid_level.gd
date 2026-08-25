extends Level

@onready var lives_label: Label = %LivesLabel
@onready var pause_menu: Control = %PauseMenu


func _ready() -> void:
	super()
	player.lives_changed.connect(_on_lives_changed)
	_on_lives_changed(player.lives)
	GameManager.state_changed.connect(_on_game_state_changed)


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
