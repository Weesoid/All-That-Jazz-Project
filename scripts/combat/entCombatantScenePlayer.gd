extends CombatantScene
class_name PlayerCombatantScene

@onready var block_timer:Timer = $BlockTimer

var blocking: bool = false
var allow_block: bool = false
var perfect_block:bool = false
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

func block(bonus_grit: float=999.0):
	if perfect_block:
		CombatGlobals.modifyStat(combatant_resource, {"block":-1,"resist":999}, 'block')
	else:
		CombatGlobals.modifyStat(combatant_resource, {"block":0.5}, 'block')
	doAnimation('Block', null, {'skip_pause'=true})
	await animator.animation_finished
	CombatGlobals.resetStat(combatant_resource, 'block')
	perfect_block=false
	block_timer.start()

func isPerfectBlock(window:float=0.015, projectile_distance:float=50.0)->bool:
	var combat_scene: CombatScene = CombatGlobals.getCombatScene()
	var acting_enemy = combat_scene.active_combatant
	var enemy_animator:AnimationPlayer = acting_enemy.combatant_scene.animator
	var animation_name = enemy_animator.current_animation
	if animation_name == '':
		return false
	elif animation_name.to_lower().contains('melee'):
		var animation: Animation = enemy_animator.get_animation(animation_name)
		var hitbox_track = animation.find_track(".", 5)
		var active_hitbox_time = animation.track_get_key_time(hitbox_track,0)
		var input_time = enemy_animator.current_animation_position
		var calculated_time = active_hitbox_time-input_time
		return calculated_time < window
	elif animation_name.to_lower().contains('ranged') and combat_scene.has_node("Projectile"):
		var projectile: ProjectileBattles = combat_scene.get_node("Projectile")
		print('>!>: ', projectile.global_position.distance_to(global_position))
		return projectile.global_position.distance_to(global_position) < projectile_distance
	
	return false
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
		OverworldGlobals.playSound("res://audio/sounds/209403__sgossner__leather-rustle-6.ogg")
		perfect_block = isPerfectBlock()
		block()
