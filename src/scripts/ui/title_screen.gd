extends Control


func _ready() -> void:
	GameManager.state = GameManager.GameState.TITLE


func _on_start_pressed() -> void:
	GameManager.show_intro()
