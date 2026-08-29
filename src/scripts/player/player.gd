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

@export var explosion_template: PackedScene
@onready var anim_player: AnimatedSprite2D = $AnimatedSprite2D

var lives: int
var invulnerability_left := 0.0
var navigation_target_x := 640.0


func _ready() -> void:
	lives = starting_lives
	lives_changed.emit(lives)
	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)


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
	_update_animation(direction)


func set_navigation_target_x(target_x: float) -> void:
	navigation_target_x = clampf(target_x, 32.0, 1248.0)


func take_hit() -> void:
	if lives <= 0 or invulnerability_left > 0.0:
		return
	lives -= 1
	invulnerability_left = invulnerability_duration
	lives_changed.emit(lives)
	if explosion_template != null:
		var explosion: Node = explosion_template.instantiate()
		add_child(explosion)
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


func _update_animation(direction: float) -> void:
	if direction < 0.0:
		if anim_player.animation != "side_left" and (anim_player.animation != "roll_left" or anim_player.get_playing_speed() <= 0.0):
			anim_player.play("roll_left")
	elif direction > 0.0:
		if anim_player.animation != "side_right" and (anim_player.animation != "roll_right" or anim_player.get_playing_speed() <= 0.0):
			anim_player.play("roll_right")
	else:
		if anim_player.animation == "side_left" or (anim_player.animation == "roll_left" and anim_player.get_playing_speed() > 0.0):
			anim_player.play_backwards("roll_left")
		elif anim_player.animation == "side_right" or (anim_player.animation == "roll_right" and anim_player.get_playing_speed() > 0.0):
			anim_player.play_backwards("roll_right")
		elif anim_player.animation == "roll_left" or anim_player.animation == "roll_right":
			pass
		elif anim_player.animation != "default":
			anim_player.play("default")


func _on_animation_finished() -> void:
	if anim_player.animation == "roll_left":
		if anim_player.frame == 0:
			anim_player.play("default")
		else:
			anim_player.play("side_left")
	elif anim_player.animation == "roll_right":
		if anim_player.frame == 0:
			anim_player.play("default")
		else:
			anim_player.play("side_right")
