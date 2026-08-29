extends Control

const STAR_COUNT := 120

@onready var title: Label = %Title
@onready var summary: Label = %Summary
@onready var outcome_rule: ColorRect = %OutcomeRule
@onready var result_status: Label = %ResultStatus
@onready var score_value: Label = %ScoreValue
@onready var time_value: Label = %TimeValue
@onready var nav_read_value: Label = %NavReadValue
@onready var nav_accuracy: ProgressBar = %NavAccuracy
@onready var nav_accuracy_caption: Label = %NavAccuracyCaption
@onready var clean_rows_value: Label = %CleanRowsValue
@onready var best_streak_value: Label = %BestStreakValue
@onready var recovery_stats: Label = %RecoveryStats
@onready var retry_button: Button = %Retry

var stars: Array[Vector3] = []
var outcome_accent := Color("63e6ff")


func _ready() -> void:
	_build_starfield()
	_update_outcome()
	_update_mastery_report()
	retry_button.grab_focus()
	queue_redraw()


func _process(delta: float) -> void:
	for index in stars.size():
		var star := stars[index]
		star.y += star.z * delta * 5.0
		if star.y > size.y:
			star.y = 0.0
		stars[index] = star
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050817"))
	for star in stars:
		var brightness := 0.24 + star.z * 0.24
		draw_circle(Vector2(star.x, star.y), star.z, Color(brightness, brightness, brightness + 0.12, 0.72))
	draw_line(Vector2(90.0, 670.0), Vector2(1190.0, 670.0), Color(outcome_accent, 0.16), 1.0)


func _build_starfield() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 8711
	for index in STAR_COUNT:
		stars.append(Vector3(random.randf_range(0.0, 1280.0), random.randf_range(0.0, 720.0), random.randf_range(0.5, 1.7)))


func _update_outcome() -> void:
	var seconds := floori(GameManager.final_time)
	score_value.text = "%06d" % GameManager.final_score
	time_value.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	if GameManager.run_escaped:
		title.text = "CLEAR SPACE"
		summary.text = "MISSION COMPLETE  //  CLEAR SPACE REACHED"
		result_status.text = "ESCAPED"
		outcome_accent = Color("73ffad")
	elif GameManager.last_failure_reason == GameManager.FailureReason.LEVEL_FAILED:
		title.text = "TIME EXPIRED"
		summary.text = "MISSION FAILED  //  ESCAPE WINDOW CLOSED"
		result_status.text = "LOST IN THE STORM"
		outcome_accent = Color("f6d365")
	else:
		title.text = "SHIP LOST"
		summary.text = "MISSION FAILED  //  HULL INTEGRITY LOST"
		result_status.text = "SHIP DESTROYED"
		outcome_accent = Color("ff6aa9")
	title.modulate = outcome_accent
	result_status.modulate = outcome_accent
	outcome_rule.color = outcome_accent


func _update_mastery_report() -> void:
	var stats: Dictionary = GameManager.final_mastery
	var correct_reads := int(stats.get("correct_trust_rows", 0))
	var trusted_rows := int(stats.get("trusted_rows", 0))
	var accuracy := 0.0
	if trusted_rows > 0:
		accuracy = float(correct_reads) / float(trusted_rows) * 100.0
		nav_read_value.text = "%d / %d" % [correct_reads, trusted_rows]
		nav_accuracy_caption.text = "%d%% ACCURATE" % roundi(accuracy)
	else:
		nav_read_value.text = "NO TRUST DATA"
		nav_accuracy_caption.text = "NO ROWS COMMITTED"
	nav_accuracy.value = accuracy
	clean_rows_value.text = str(int(stats.get("clean_rows", 0)))
	best_streak_value.text = str(int(stats.get("longest_correct_streak", 0)))
	var manual_seconds := floori(float(stats.get("manual_time", 0.0)))
	recovery_stats.text = "RECOVERIES\n%d\nBLOCKERS CLEARED\n%d\nDAMAGE TAKEN\n%d\nMANUAL TIME\n%02d:%02d" % [
		int(stats.get("successful_recoveries", 0)),
		int(stats.get("blockers_destroyed", 0)),
		int(stats.get("damage_taken", 0)),
		manual_seconds / 60,
		manual_seconds % 60,
	]


func _on_retry_pressed() -> void:
	GameManager.restart_run()


func _on_title_pressed() -> void:
	GameManager.return_to_title()
