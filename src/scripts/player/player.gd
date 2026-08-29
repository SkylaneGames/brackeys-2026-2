class_name Player
extends CharacterBody2D

signal lives_changed(lives: int)
signal died

@export_range(1, 10) var starting_lives := 3
@export var move_speed := 300.0
@export_range(0.0, 1.0) var navigation_influence := 0.68
@export_range(0.0, 1.0) var manual_correction_influence := 1.0
@export var navigation_response_distance := 120.0
@export var navigation_arrival_distance := 8.0
@export_range(0.0, 0.25) var movement_deadzone := 0.03
@export var invulnerability_duration := 1.5
@export var shot_cooldown := 0.28

@export var explosion_template: PackedScene
@export var projectile_scene: PackedScene
@onready var anim_player: AnimatedSprite2D = $AnimatedSprite2D

var lives: int
var invulnerability_left := 0.0
var navigation_target_x := 640.0
var shot_cooldown_left := 0.0
var is_correcting := false


func _ready() -> void:
	lives = starting_lives
	lives_changed.emit(lives)
	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)
	shot_cooldown_left = maxf(shot_cooldown_left - delta, 0.0)
	if Input.is_action_pressed("shoot"):
		_shoot()
	var manual_direction := Input.get_axis("move_left", "move_right")
	is_correcting = absf(manual_direction) > movement_deadzone
	var target_delta := navigation_target_x - global_position.x
	var navigation_direction := 0.0
	if absf(target_delta) > navigation_arrival_distance:
		navigation_direction = clampf(target_delta / navigation_response_distance, -1.0, 1.0)
	# Correction temporarily owns steering. The AI resumes when input is released.
	var direction := manual_direction * manual_correction_influence if is_correcting else navigation_direction * navigation_influence
	if absf(direction) < movement_deadzone:
		direction = 0.0
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


func restore_life() -> bool:
	if lives <= 0 or lives >= starting_lives:
		return false
	lives += 1
	lives_changed.emit(lives)
	return true


func _shoot() -> void:
	if projectile_scene == null or shot_cooldown_left > 0.0:
		return
	var projectile := projectile_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector2(0.0, -34.0)
	shot_cooldown_left = shot_cooldown


func _update_invulnerability(delta: float) -> void:
	if invulnerability_left <= 0.0:
		return
	invulnerability_left = maxf(invulnerability_left - delta, 0.0)
	# Fancy blink to show how much invulnerability is left.
	modulate.a = 0.35 if int(invulnerability_left * 10.0) % 2 == 0 else 1.0
	if invulnerability_left == 0.0:
		modulate.a = 1.0


func _update_animation(direction: float) -> void:
	if direction < -movement_deadzone:
		if anim_player.animation != "side_left" and (anim_player.animation != "roll_left" or anim_player.get_playing_speed() <= 0.0):
			anim_player.play("roll_left")
	elif direction > movement_deadzone:
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
