extends Control

@onready var result_label: Label = %ResultLabel
@onready var title: Label = %Title
@onready var background: ColorRect = %Background


func _ready() -> void:
	var seconds := floori(GameManager.final_time)
	if GameManager.run_escaped:
		title.text = "CLEAR SPACE"
		background.color = Color("031d22")
		result_label.text = "ESCAPED\nTIME  %02d:%02d" % [seconds / 60, seconds % 60]
	elif GameManager.last_failure_reason == GameManager.FailureReason.LEVEL_FAILED:
		title.text = "TIME EXPIRED"
		result_label.text = "LOST IN THE STORM\nSCORE  %06d" % GameManager.final_score
	else:
		title.text = "SHIP LOST"
		result_label.text = "SCORE  %06d\nTIME  %02d:%02d" % [GameManager.final_score, seconds / 60, seconds % 60]


func _on_retry_pressed() -> void:
	GameManager.restart_run()


func _on_title_pressed() -> void:
	GameManager.return_to_title()
