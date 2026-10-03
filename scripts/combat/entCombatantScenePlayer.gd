extends CombatantScene
class_name PlayerCombatantScene


const block_windows = {
	BlockTiers.PERFECT: 0.0167,
	BlockTiers.GOOD: 0.04
}
const ranged_block_windows = {
	BlockTiers.PERFECT: 20,
	BlockTiers.GOOD: 60
}
#const block_windows = {
#	BlockTiers.PERFECT: 0.00000000000000000003,
#	BlockTiers.GOOD: 0.03
#}
#const ranged_block_windows = {
#	BlockTiers.PERFECT: -20,
#	BlockTiers.GOOD: 620
#}
enum BlockTiers {
	BASIC,
	GOOD,
	PERFECT,
	MISSED
}

@onready var block_timer:Timer = $BlockTimer

var blocking: bool = false
var allow_block: bool = false
#var perfect_block:bool = false
#var weapon: WeaponScene

func _ready():
	initializeShapes()
	block_timer.timeout.connect(checkHasBlockModifier)
	if get_node('Sprite2D').has_node('WarningGradient'):
		$Sprite2D/WarningGradient/AnimationPlayer.play("Show")

func _exit_tree():
	if combatant_resource == null:
		return
	
	if combatant_resource.stat_modifiers.has('block'):
		CombatGlobals.resetStat(combatant_resource, 'block')
	if block_timer.timeout.is_connected(checkHasBlockModifier):
		block_timer.timeout.disconnect(checkHasBlockModifier)

func checkHasBlockModifier():
	if combatant_resource.stat_modifiers.has('block'):
		CombatGlobals.resetStat(combatant_resource, 'block')

func setBlocking(set_to: bool):
	blocking = set_to

func block():
	var block_tier = getBlockTier()
	match block_tier:
		BlockTiers.BASIC: 
			CombatGlobals.modifyStat(combatant_resource, {"block":0.25, "block_tier":0}, 'block')
		BlockTiers.GOOD: 
			CombatGlobals.modifyStat(combatant_resource, {"block":0.5, "block_tier":1}, 'block')
		BlockTiers.PERFECT: 
			CombatGlobals.modifyStat(combatant_resource, {"block":-1,"resist":999, "block_tier":2}, 'block')
	doAnimation('Block', null, {'skip_pause'=true})
	await animator.animation_finished
	CombatGlobals.resetStat(combatant_resource, 'block')
	startBlockCooldown()

func startBlockCooldown():
	block_timer.start(0.25)

# These are perfect values, adjust accordingly
# DEBT: Multiple hitbox frames, or multiple projectiles, probs better to just seperate these in the basic_effects seq tho
func getBlockTier()-> BlockTiers:
	var input_time = CombatGlobals.getCombatScene().active_combatant.combatant_scene.animator.current_animation_position
	var combat_scene: CombatScene = CombatGlobals.getCombatScene()
	var acting_enemy = combat_scene.active_combatant
	var enemy_animator:AnimationPlayer = acting_enemy.combatant_scene.animator
	var animation_name = enemy_animator.current_animation
	if animation_name == '':
		return BlockTiers.MISSED
	elif animation_name.to_lower().contains('melee'):
		var animation: Animation = enemy_animator.get_animation(animation_name)
		var hitbox_track = animation.find_track(".", 5)
		var active_hitbox_time = animation.track_get_key_time(hitbox_track,0)
		var calculated_time = active_hitbox_time-input_time
		print(calculated_time)
		if calculated_time <= block_windows[BlockTiers.PERFECT] and calculated_time > 0:
			return BlockTiers.PERFECT
		elif calculated_time <= block_windows[BlockTiers.GOOD] and calculated_time > 0:
			return BlockTiers.GOOD
		elif calculated_time > 0:
			return BlockTiers.BASIC
	elif animation_name.to_lower().contains('ranged') and combat_scene.has_node("Projectile"):
		var projectile: ProjectileBattles = combat_scene.get_node("Projectile")
		var distance = projectile.global_position.distance_to(global_position)
		#print('>!>: ', projectile.global_position.distance_to(global_position))
		#print(distance, ' < ', ranged_block_windows[BlockTiers.GOOD])
		#print(distance < ranged_block_windows[BlockTiers.GOOD])
		print(distance)
		if distance < ranged_block_windows[BlockTiers.PERFECT]:
			print('P')
			return BlockTiers.PERFECT
		elif distance < ranged_block_windows[BlockTiers.GOOD]:
			print('G')
			return BlockTiers.GOOD
		else:
			print('B')
			return BlockTiers.BASIC
	
	return BlockTiers.MISSED
#		print('calcd time: ', active_hitbox_time-input_time)
#		OverworldGlobals.playSound("res://audio/sounds/721774__maodin204__cash-register.ogg")
		#print('INP TIME: ', input_time)
	
	#print('ZAZA: ', hitbox_track)
	#animation.find_track()
	#animation.find
	
#	print(acting_enemy.combatant_scene.animator.current_animation)
	

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
	if Input.is_action_just_pressed('ui_accept') and CombatGlobals.inCombat() and canBlock():
		#perfect_block = isPerfectBlock()
		block()
		OverworldGlobals.playSound("res://audio/sounds/209403__sgossner__leather-rustle-6.ogg")

