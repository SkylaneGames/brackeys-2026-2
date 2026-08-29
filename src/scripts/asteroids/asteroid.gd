class_name Asteroid
extends Area2D

@export var fall_speed := 180.0
@export var despawn_y := 780.0
@export var textures: Array[Texture2D] = [
	preload("res://assets/sprites/asteroid_1.png"),
	preload("res://assets/sprites/asteroid_2.png"),
	preload("res://assets/sprites/asteroid_3.png"),
	preload("res://assets/sprites/asteroid_4.png"),
	preload("res://assets/sprites/asteroid_5.png"),
	preload("res://assets/sprites/asteroid_6.png"),
]

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not textures.is_empty():
		sprite_2d.texture = textures.pick_random()


func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if global_position.y > despawn_y:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_hit()
		queue_free()
