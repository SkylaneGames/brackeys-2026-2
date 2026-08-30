extends Control

@onready var start_button: Button = %StartButton


func _ready() -> void:
	GameManager.state = GameManager.GameState.TITLE
	start_button.grab_focus()


func _on_start_pressed() -> void:
	GameManager.show_intro()
