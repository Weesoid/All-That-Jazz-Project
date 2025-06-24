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
		var stun_stars = preload("res://scenes/animations_quick/Dazed.tscn").instantiate()
		stun_stars.position = Vector2(0,-OverworldGlobals.getEntity(patroller_name).get_node('Sprite2D').texture.get_height()/4)
		add_child(stun_stars)
	timer.timeout.connect(queue_free)
	centerSelf()

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

func centerSelf():
	if get_parent().has_node('CollisionShape2D'):
		position.x = 0
		position.y = -(get_parent().get_node('CollisionShape2D').shape.height/2)
