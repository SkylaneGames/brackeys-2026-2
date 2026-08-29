class_name Asteroid
extends Area2D

signal destroyed

@export var fall_speed := 180.0
@export var despawn_y := 780.0
@export var explosion_template: PackedScene
@export var textures: Array[Texture2D] = [
	preload("res://assets/sprites/asteroid_1.png"),
	preload("res://assets/sprites/asteroid_2.png"),
	preload("res://assets/sprites/asteroid_3.png"),
	preload("res://assets/sprites/asteroid_4.png"),
	preload("res://assets/sprites/asteroid_5.png"),
	preload("res://assets/sprites/asteroid_6.png"),
]

@onready var sprite_2d: Sprite2D = $Sprite2D
var is_destructible := false
var marker_time := 0.0


func set_fall_speed(value: float) -> void:
	fall_speed = value


func set_destructible(value: bool) -> void:
	is_destructible = value
	queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not textures.is_empty():
		sprite_2d.texture = textures.pick_random()


func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if is_destructible:
		marker_time += delta
		queue_redraw()
	if global_position.y > despawn_y:
		queue_free()


func _draw() -> void:
	if not is_destructible:
		return
	var marker_color := Color(1.0, 0.78, 0.28, 0.72 + sin(marker_time * 5.0) * 0.18)
	draw_arc(Vector2.ZERO, 58.0, 0.18, 1.2, 12, marker_color, 4.0, true)
	draw_arc(Vector2.ZERO, 58.0, 1.75, 2.77, 12, marker_color, 4.0, true)
	draw_arc(Vector2.ZERO, 58.0, 3.32, 4.34, 12, marker_color, 4.0, true)
	draw_arc(Vector2.ZERO, 58.0, 4.89, 5.91, 12, marker_color, 4.0, true)


func try_destroy() -> bool:
	if not is_destructible:
		return false
	if explosion_template != null:
		var explosion := explosion_template.instantiate() as Node2D
		get_parent().add_child(explosion)
		explosion.global_position = global_position
	destroyed.emit()
	queue_free()
	return true


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_hit()
		queue_free()
