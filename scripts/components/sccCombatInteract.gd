extends Area2D

@onready var sprite_animator = $Sprite2D/AnimationPlayer
var patroller_name: String

func _ready():
	sprite_animator.play("Show")

func interact():
	OverworldGlobals.changeToCombat(patroller_name, '', '', 'Dazed')
	OverworldGlobals.show_player_interaction = true
	queue_free()
