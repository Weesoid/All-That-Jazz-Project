extends CombatantScene
class_name PlayerCombatantScene

@onready var block_timer = $BlockCooldownBar/BlockTimer
var blocking: bool = false
#@onready var sheathe_point = $Sprite2D/SheathePoint
#@onready var unsheathe_point = $WeaponPoint

func playWeaponAttack():
	pass
#	temp.reparent(unsheathe_point, false)
#	temp.get_node('AnimationPlayer').play('Show')

func sheatheWeapon():
	pass
#	temp.reparent(sheathe_point, false)
#	temp.get_node('AnimationPlayer').play('RESET')

func setBlocking(set_to: bool):
	blocking = set_to
	if blocking:
		idle_animation = 'Idle_Block'
		animator.play('Idle_Block')
	else:
		idle_animation = 'Idle'
		animator.play('Idle')

func block(bonus_grit: float=0.75):
	CombatGlobals.modifyStat(combatant_resource, {'grit': 0.75}, 'block')
	doAnimation('Block')
	await animator.animation_finished
	CombatGlobals.resetStat(combatant_resource, 'block')
	block_timer.start()

func _unhandled_input(event):
	if Input.is_action_just_pressed('ui_accept') and blocking and !CombatGlobals.getCombatScene().active_combatant is ResPlayerCombatant and block_timer.is_stopped():
		block()

func _process(_delta):
	if combatant_resource.isDead():
		blocking = false
		doAnimation('KO', null, false)
