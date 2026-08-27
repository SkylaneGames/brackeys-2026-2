extends CanvasLayer

class_name Hud

@onready var ai_systems: Array[NavAi] = _get_ai_systems()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _get_ai_systems() -> Array[NavAi]:
	var result: Array[NavAi] = []

	for child in $NavSystems.get_children():
		if child is NavAi:
			result.append(child)

	return result

func switch_active_ai(index: int):
	for i in ai_systems.size():
		ai_systems[i].set_active(i == index)

func _process(delta: float) -> void:

	# TODO: Switch testing, remove once integrated to game manager.
	if Input.is_key_pressed(Key.KEY_1):
		switch_active_ai(0)
	elif Input.is_key_pressed(Key.KEY_2):
		switch_active_ai(1)
	elif Input.is_key_pressed(Key.KEY_3):
		switch_active_ai(-1)