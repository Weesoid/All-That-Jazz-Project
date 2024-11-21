extends Area2D

@onready var sprite_animator = $Sprite2D/AnimationPlayer
@onready var timer = $Timer
var interacted = false
var patroller_name: String

func _ready():
	sprite_animator.play("Show")
	OverworldGlobals.getCombatantSquadComponent(get_parent().name).addLingeringEffect('Dazed')
	timer.timeout.connect(func():queue_free())

func interact():
	if !interacted:
		interacted = true
		OverworldGlobals.changeToCombat(patroller_name)
		await OverworldGlobals.combat_enetered
		#OverworldGlobals.getComponent(get_parent().name, 'NPCPatrolComponent').immobolize()
		queue_free()

func _exit_tree():
	OverworldGlobals.getCombatantSquadComponent(get_parent().name).removeLingeringEffect('Dazed')
