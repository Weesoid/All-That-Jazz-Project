extends Area2D

@onready var sprite_animator = $Sprite2D/AnimationPlayer
@onready var timer = $Timer
var patroller_name: String

func _ready():
	sprite_animator.play("Show")
	timer.timeout.connect(func(): queue_free())

func interact():
	OverworldGlobals.changeToCombat(patroller_name, '', '', 'Dazed')
	#OverworldGlobals.show_player_interaction = true
	queue_free()
