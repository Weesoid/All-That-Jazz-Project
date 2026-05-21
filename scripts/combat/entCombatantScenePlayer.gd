extends CombatantScene
class_name PlayerCombatantScene

@onready var block_timer:Timer = $BlockCooldownBar/BlockTimer

var blocking: bool = false
var allow_block: bool = false
#var weapon: WeaponScene

func _ready():
	initializeShapes()
	block_timer.timeout.connect(checkHasBlockModifier)
	if get_node('Sprite2D').has_node('WarningGradient'):
		$Sprite2D/WarningGradient/AnimationPlayer.play("Show")

func _exit_tree():
	if combatant_resource.stat_modifiers.has('block'):
		CombatGlobals.resetStat(combatant_resource, 'block')
	if block_timer.timeout.is_connected(checkHasBlockModifier):
		block_timer.timeout.disconnect(checkHasBlockModifier)

func checkHasBlockModifier():
	if combatant_resource.stat_modifiers.has('block'):
		CombatGlobals.resetStat(combatant_resource, 'block')

func setBlocking(set_to: bool):
	blocking = set_to
#	if blocking:
#		playIdle('Idle_Block')
#	else:
#		if (combatant_resource.isDead() or combatant_resource.hasStatusEffect('Fading')) and combatant_resource is ResPlayerCombatant:
#			playIdle('Fading')
#		else:
#			playIdle('Idle')

func block(bonus_grit: float=999.0):
	if canBlock():
		"res://images/sprites/daze_diamond.png"# MARKED FOR REPLACE
		CombatGlobals.modifyStat(combatant_resource, {'resist': bonus_grit}, 'block')
		doAnimation('Block', null, {'skip_pause'=true})
		await animator.animation_finished
		CombatGlobals.resetStat(combatant_resource, 'block')

func canBlock()-> bool:
	var combat_scene = CombatGlobals.getCombatScene()
	var is_targeted = combatant_resource in combat_scene.target_combatant \
		if combat_scene.target_combatant is Array \
		else combatant_resource == combat_scene.target_combatant
	
	return blocking \
		and allow_block \
		and (!combat_scene.active_combatant is ResPlayerCombatant) \
		and block_timer.is_stopped() \
		and combatant_resource is ResPlayerCombatant \
		and is_targeted

func _input(_event):
	if Input.is_action_just_pressed('ui_accept') and OverworldGlobals.inCombat():
		block()


#func _on_animation_player_animation_started(anim_name):
#	pass
