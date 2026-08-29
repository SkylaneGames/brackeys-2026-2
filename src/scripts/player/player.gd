class_name Player
extends CharacterBody2D

signal lives_changed(lives: int)
signal died

@export_range(1, 10) var starting_lives := 3
@export var move_speed := 300.0
@export_range(0.0, 1.0) var navigation_influence := 0.68
@export_range(0.0, 1.0) var manual_correction_influence := 0.78
@export var navigation_response_distance := 120.0
@export var invulnerability_duration := 1.5

var lives: int
var invulnerability_left := 0.0
var navigation_target_x := 640.0


func _ready() -> void:
	lives = starting_lives
	lives_changed.emit(lives)


func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)
	var manual_direction := Input.get_axis("move_left", "move_right")
	var navigation_direction := clampf(
		(navigation_target_x - global_position.x) / navigation_response_distance,
		-1.0,
		1.0
	)
	var direction := clampf(
		navigation_direction * navigation_influence
			+ manual_direction * manual_correction_influence,
		-1.0,
		1.0
	)
	velocity = Vector2(direction * move_speed, 0.0)
	move_and_slide()
	global_position.x = clampf(global_position.x, 32.0, 1248.0)


func set_navigation_target_x(target_x: float) -> void:
	navigation_target_x = clampf(target_x, 32.0, 1248.0)


func take_hit() -> void:
	if lives <= 0 or invulnerability_left > 0.0:
		return
	lives -= 1
	invulnerability_left = invulnerability_duration
	lives_changed.emit(lives)
	if lives == 0:
		died.emit()


func _update_invulnerability(delta: float) -> void:
	if invulnerability_left <= 0.0:
		return
	invulnerability_left = maxf(invulnerability_left - delta, 0.0)
	# Fancy blink to show how much invulnerability is left.
	modulate.a = 0.35 if int(invulnerability_left * 10.0) % 2 == 0 else 1.0
	if invulnerability_left == 0.0:
		modulate.a = 1.0
