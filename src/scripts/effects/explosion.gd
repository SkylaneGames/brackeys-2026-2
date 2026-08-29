extends Node2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animation.animation_finished.connect(queue_free)
