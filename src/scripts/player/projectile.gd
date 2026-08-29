extends Area2D

@export var speed := 720.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	global_position.y -= speed * delta
	if global_position.y < -80.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Asteroid and area.try_destroy():
		queue_free()
