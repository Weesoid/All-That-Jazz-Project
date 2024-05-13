extends Area2D

@onready var sprite_animator = $Sprite2D/AnimationPlayer
@onready var timer = $Timer
var patroller_name: String

func _ready():
	sprite_animator.play("Show")
	OverworldGlobals.getCombatantSquadComponent(get_parent().name).addLingeringEffect('Dazed')
	timer.timeout.connect(func():queue_free())

func interact():
	OverworldGlobals.changeToCombat(patroller_name)
	queue_free()

func _exit_tree():
	OverworldGlobals.getCombatantSquadComponent(get_parent().name).removeLingeringEffect('Dazed')
