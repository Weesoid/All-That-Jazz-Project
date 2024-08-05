extends Node2D
class_name CombatantScene

@onready var temp = $Sprite2D/SheathePoint/SwordSlash
@onready var animator = $AnimationPlayer
@onready var sheathe_point = $Sprite2D/SheathePoint
@onready var unsheathe_point = $WeaponPoint
@export var combatant_resource: ResCombatant

var blocking: bool = false

func moveTo(target, duration:float=0.25, offset:Vector2=Vector2(0,0)):
	var tween = create_tween()
	if target is ResCombatant:
		target = target.SCENE
		if target.combatant_resource is ResEnemyCombatant: 
			offset = Vector2(-40,0)
		else:
			offset = Vector2(40,0)
	tween.tween_property(self, 'global_position', target.global_position + offset, duration)
	await tween.finished

func doAttack(animation: String='Cast_Misc', ability: ResAbility=null):
	animator.play(animation)
	await animator.animation_finished
	animator.play('Idle')
	await get_tree().create_timer(0.5)

func playWeaponAttack():
	temp.reparent(unsheathe_point, false)
	temp.get_node('AnimationPlayer').play('Show')

func sheatheWeapon():
	temp.reparent(sheathe_point, false)
	temp.get_node('AnimationPlayer').play('RESET')

func _unhandled_input(event):
	if Input.is_action_just_pressed('ui_accept'):
		doAttack()
