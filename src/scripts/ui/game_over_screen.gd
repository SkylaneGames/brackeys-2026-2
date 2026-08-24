extends Control


func _on_retry_pressed() -> void:
	GameManager.restart_run()


func _on_title_pressed() -> void:
	GameManager.return_to_title()
