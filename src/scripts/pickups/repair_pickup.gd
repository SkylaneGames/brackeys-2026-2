extends Area2D

@export var fall_speed := 90.0
@export var despawn_y := 780.0
var pulse_time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	pulse_time += delta
	rotation = sin(pulse_time * 2.0) * 0.08
	if global_position.y > despawn_y:
		queue_free()


func set_fall_speed(value: float) -> void:
	fall_speed = value


func _on_body_entered(body: Node2D) -> void:
	if body is Player and body.restore_life():
		queue_free()
