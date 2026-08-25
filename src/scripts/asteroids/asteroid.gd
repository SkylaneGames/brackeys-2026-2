class_name Asteroid
extends Area2D

@export var fall_speed := 180.0
@export var despawn_y := 780.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	if global_position.y > despawn_y:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_hit()
		queue_free()
