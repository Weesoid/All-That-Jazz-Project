extends Area2D

@onready var timer = $Timer
var interacted = false
var patroller_name: String

func _ready():
	OverworldGlobals.getCombatantSquadComponent(get_parent().name).addLingeringEffect('Dazed')
	if get_parent() is PlayerScene:
		OverworldGlobals.shakeCamera()
		OverworldGlobals.playEntityAnimation('Player', 'Stun')
		PlayerGlobals.applyBlessing("res://scenes/temporary_blessings/Stun.tscn")
		visible = false
	else:
		var stun_stars = preload("res://scenes/components/DazedQuickAnim.tscn").instantiate()
		stun_stars.global_position = Vector2(0,0)
		add_child(stun_stars)
	timer.timeout.connect(queue_free)
	
#	if get_parent() is PlayerScene:
#		timer.start(3.0)
#	else:
#		timer.start(5.0)

func interact():
	if !interacted and visible:
		interacted = true
		OverworldGlobals.changeToCombat(patroller_name)
		await OverworldGlobals.combat_enetered
		queue_free()

func _exit_tree():
	OverworldGlobals.getCombatantSquadComponent(get_parent().name).removeLingeringEffect('Dazed')
	if get_parent() is PlayerScene:
		get_parent().resetAnimation()
