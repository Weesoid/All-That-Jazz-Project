extends CombatantScene
class_name PlayerCombatantScene

@onready var block_timer:Timer = $BlockCooldownBar/BlockTimer
@onready var sheathe_point = $Sprite2D/SheathePoint
@onready var unsheathe_point = $WeaponPoint

var blocking: bool = false
var allow_block: bool = false
var weapon: WeaponScene

func _ready():
	CombatGlobals.click_block.connect(block)
	block_timer.timeout.connect(checkHasBlockModifier)
func _exit_tree():
	if combatant_resource.stat_modifiers.has('block'):
		CombatGlobals.resetStat(combatant_resource, 'block')

func checkHasBlockModifier():
	if combatant_resource.stat_modifiers.has('block'):
		CombatGlobals.resetStat(combatant_resource, 'block')

func playWeaponAttack():
	weapon.reparent(unsheathe_point, false)
	weapon.showWeapon()

func sheatheWeapon():
	weapon.reparent(sheathe_point, false)
	weapon.showWeapon(true)

func setBlocking(set_to: bool):
	blocking = set_to
	if blocking:
		playIdle('Idle_Block')
	else:
		if (combatant_resource.isDead() or combatant_resource.hasStatusEffect('Fading')) and combatant_resource is ResPlayerCombatant:
			playIdle('Fading')
		else:
			playIdle('Idle')

func block(bonus_grit: float=10.0):
	if canBlock():
		CombatGlobals.modifyStat(combatant_resource, {'grit': bonus_grit, 'resist': 10.0}, 'block')
		doAnimation('Block', null, {'skip_pause'=true})
		await animator.animation_finished
		CombatGlobals.resetStat(combatant_resource, 'block')

func canBlock()-> bool:
	return blocking and allow_block and (!CombatGlobals.getCombatScene().active_combatant is ResPlayerCombatant or CombatGlobals.getCombatScene().onslaught_mode) and block_timer.is_stopped() and !combatant_resource.isDead() and combatant_resource is ResPlayerCombatant

func _input(_event):
	if Input.is_action_just_pressed('ui_accept'):
		block()
