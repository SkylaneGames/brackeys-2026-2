class_name Player
extends CharacterBody2D

signal lives_changed(lives: int)
signal died

@export_range(1, 10) var starting_lives := 3
@export var move_speed := 420.0
@export var invulnerability_duration := 1.5

@export var explosion_template: PackedScene

var lives: int
var invulnerability_left := 0.0


func _ready() -> void:
	lives = starting_lives
	lives_changed.emit(lives)


func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)
	var direction := Input.get_axis("move_left", "move_right")
	velocity = Vector2(direction * move_speed, 0.0)
	move_and_slide()
	global_position.x = clampf(global_position.x, 32.0, 1248.0)


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
