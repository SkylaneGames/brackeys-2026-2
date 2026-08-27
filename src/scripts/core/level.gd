class_name Level
extends Node2D

enum FailureReason { OBJECTIVE_FAILED, ENVIRONMENT }

signal completed
signal failed(reason: FailureReason)
signal player_died

@export var player_scene: PackedScene
@onready var player_spawn: Marker2D = %PlayerSpawn

var player: Player


func _ready() -> void:
	GameManager.register_level(self)
	spawn_player()


func spawn_player() -> void:
	if player_scene == null:
		push_error("Level requires a player scene.")
		return
	player = player_scene.instantiate() as Player
	if player == null:
		push_error("Configured player scene must use the Player script.")
		return

	# Place player under spawn point so it inherits it's position, avoiding them spawning in collision with an asteroid.
	player_spawn.add_child(player)
	player.died.connect(player_died.emit)
