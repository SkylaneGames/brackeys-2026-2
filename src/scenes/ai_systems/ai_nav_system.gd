extends Control
class_name NavAi
@export var designation: String = "A"
@export var is_active: bool = false

@onready var label: Label = $Label
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = "NAV" + " " + designation

	set_active(is_active)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_active(value: bool) -> void:
	is_active = value
	if value:
		animation.speed_scale = 2
		animation.self_modulate.v = 1
	else:
		animation.speed_scale = 1
		animation.self_modulate.v = 0.5
