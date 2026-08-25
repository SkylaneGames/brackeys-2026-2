class_name Player
extends CharacterBody2D

signal lives_changed(lives: int)
signal died

@export_range(1, 10) var starting_lives := 3
@export var move_speed := 420.0

var lives: int


func _ready() -> void:
	lives = starting_lives
	lives_changed.emit(lives)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	velocity = Vector2(direction * move_speed, 0.0)
	move_and_slide()
	global_position.x = clampf(global_position.x, 32.0, 1248.0)


func take_hit() -> void:
	if lives <= 0:
		return
	lives -= 1
	lives_changed.emit(lives)
	if lives == 0:
		died.emit()
