extends CombatantScene
class_name PlayerCombatantScene

@onready var block_timer = $BlockCooldownBar/BlockTimer
@onready var sheathe_point = $Sprite2D/SheathePoint
@onready var unsheathe_point = $WeaponPoint

var blocking: bool = false
var allow_block: bool = false
var weapon: WeaponScene

func _ready():
	if combatant_resource is ResPlayerCombatant and combatant_resource.EQUIPPED_WEAPON != null:
		weapon = combatant_resource.EQUIPPED_WEAPON.EFFECT.ANIMATION.instantiate()
		weapon.equipped_combatant = self
		sheathe_point.add_child(weapon)
	CombatGlobals.click_block.connect(block)

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

func block(bonus_grit: float=1.0):
	if canBlock():
		CombatGlobals.modifyStat(combatant_resource, {'grit': bonus_grit, 'resist': 1.0}, 'block')
		doAnimation('Block')
		await animator.animation_finished
		CombatGlobals.resetStat(combatant_resource, 'block')
		block_timer.start()

func canBlock()-> bool:
	return blocking and allow_block and (!CombatGlobals.getCombatScene().active_combatant is ResPlayerCombatant or CombatGlobals.getCombatScene().onslaught_mode) and block_timer.is_stopped() and !combatant_resource.isDead() and combatant_resource is ResPlayerCombatant

func _input(_event):
	if Input.is_action_just_pressed('ui_accept'):
		block()
#	if Input.is_action_just_pressed("ui_click") and canBlock():
#		doAnimation('Cast_Melee', load("res://scripts/combat/abilities/scaRetaliate.gd"))
