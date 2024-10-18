extends CombatantScene
class_name PlayerCombatantScene

@onready var block_timer = $BlockCooldownBar/BlockTimer
@onready var sheathe_point = $Sprite2D/SheathePoint
@onready var unsheathe_point = $WeaponPoint

var blocking: bool = false
var allow_block: bool = false
var weapon: WeaponScene

func _ready():
	if combatant_resource.EQUIPPED_WEAPON != null:
		weapon = combatant_resource.EQUIPPED_WEAPON.EFFECT.ANIMATION.instantiate()
		weapon.equipped_combatant = self
		sheathe_point.add_child(weapon)

func playWeaponAttack():
	weapon.reparent(unsheathe_point, false)
	weapon.showWeapon()

func sheatheWeapon():
	weapon.reparent(sheathe_point, false)
	weapon.showWeapon(true)

func setBlocking(set_to: bool):
	blocking = set_to
	if blocking:
		idle_animation = 'Idle_Block'
		animator.play('Idle_Block')
	else:
		idle_animation = 'Idle'
		animator.play('Idle')

func block(bonus_grit: float=0.75):
	CombatGlobals.modifyStat(combatant_resource, {'grit': bonus_grit}, 'block')
	doAnimation('Block')
	await animator.animation_finished
	CombatGlobals.resetStat(combatant_resource, 'block')
	block_timer.start()

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_accept') and blocking and allow_block and !CombatGlobals.getCombatScene().active_combatant is ResPlayerCombatant and block_timer.is_stopped() and !combatant_resource.isDead():
		block()
