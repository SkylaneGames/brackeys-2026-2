extends Control

@onready var result_label: Label = %ResultLabel


func _ready() -> void:
	var seconds := floori(GameManager.final_time)
	result_label.text = "SCORE  %06d\nTIME  %02d:%02d" % [GameManager.final_score, seconds / 60, seconds % 60]


func _on_retry_pressed() -> void:
	GameManager.restart_run()


func _on_title_pressed() -> void:
	GameManager.return_to_title()
