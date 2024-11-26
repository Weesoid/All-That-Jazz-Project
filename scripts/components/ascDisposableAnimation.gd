extends Node2D

@export var free_after:bool = true
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.play("Show")
	if free_after:
		await animation_player.animation_finished
		queue_free()
