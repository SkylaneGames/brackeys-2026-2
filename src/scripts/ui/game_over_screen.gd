extends Control

const STAR_COUNT := 120
const TRANSITION_HOLD := 0.12
const TRANSITION_DURATION := 0.55

@onready var title: Label = %Title
@onready var outcome_rule: ColorRect = %OutcomeRule
@onready var score_value: Label = %ScoreValue
@onready var time_value: Label = %TimeValue
@onready var nav_read_value: Label = %NavReadValue
@onready var nav_accuracy: ProgressBar = %NavAccuracy
@onready var nav_accuracy_caption: Label = %NavAccuracyCaption
@onready var clean_rows_value: Label = %CleanRowsValue
@onready var best_streak_value: Label = %BestStreakValue
@onready var recovery_stats: Label = %RecoveryStats
@onready var retry_button: Button = %Retry
@onready var title_button: Button = %TitleButton
@onready var transition_veil: ColorRect = %TransitionVeil

var stars: Array[Vector3] = []
var outcome_accent := Color("63e6ff")
var actions_enabled := false


func _ready() -> void:
	_build_starfield()
	_update_outcome()
	_update_mastery_report()
	retry_button.disabled = true
	title_button.disabled = true
	queue_redraw()
	_play_entrance_transition()


func _input(event: InputEvent) -> void:
	if not actions_enabled:
		if event is InputEventKey or event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
		return
	if event is not InputEventKey or not event.is_pressed() or event.is_echo():
		return
	if event.keycode in [Key.KEY_ENTER, Key.KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		if get_viewport().gui_get_focus_owner() == title_button:
			_on_title_pressed()
		else:
			_on_retry_pressed()
	elif event.is_action("ui_accept"):
		# Space fires during play and must never carry into a debrief action.
		get_viewport().set_input_as_handled()


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


func _play_entrance_transition() -> void:
	transition_veil.visible = true
	transition_veil.color.a = 1.0
	var tween := create_tween()
	tween.tween_interval(TRANSITION_HOLD)
	tween.tween_property(transition_veil, "color:a", 0.0, TRANSITION_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	transition_veil.visible = false
	retry_button.disabled = false
	title_button.disabled = false
	actions_enabled = true
	retry_button.grab_focus()


func _update_outcome() -> void:
	var seconds := floori(GameManager.final_time)
	score_value.text = "%06d" % GameManager.final_score
	time_value.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	if GameManager.run_escaped:
		title.text = "ESCAPE COMPLETE"
		outcome_accent = Color("73ffad")
	elif GameManager.last_failure_reason == GameManager.FailureReason.LEVEL_FAILED:
		title.text = "TIME EXPIRED"
		outcome_accent = Color("f6d365")
	else:
		title.text = "SHIP LOST"
		outcome_accent = Color("ff6aa9")
	title.modulate = outcome_accent
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
		nav_read_value.text = "—"
		nav_accuracy_caption.text = "NO ROUTES CHOSEN"
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
	if not actions_enabled:
		return
	actions_enabled = false
	GameManager.restart_run()


func _on_title_pressed() -> void:
	if not actions_enabled:
		return
	actions_enabled = false
	GameManager.return_to_title()
