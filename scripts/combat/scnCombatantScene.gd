extends Node2D
class_name CombatantScene

#@onready var temp = $Sprite2D/SheathePoint/SwordSlash
@onready var animator = $AnimationPlayer
@onready var sheathe_point = $Sprite2D/SheathePoint
@onready var unsheathe_point = $WeaponPoint
@export var combatant_resource: ResCombatant

var hit_script: GDScript
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

func doAnimation(animation: String='Cast_Weapon', script: GDScript=null):
	if script != null: hit_script = script
	z_index = 99
	animator.play(animation)
	await animator.animation_finished
	animator.play('RESET')
	animator.play('Idle')
	await get_tree().create_timer(0.5)
	script = null
	z_index = 0

func playWeaponAttack():
	pass
#	temp.reparent(unsheathe_point, false)
#	temp.get_node('AnimationPlayer').play('Show')

func sheatheWeapon():
	pass
#	temp.reparent(sheathe_point, false)
#	temp.get_node('AnimationPlayer').play('RESET')

func _on_hit_box_body_entered(body):
	if hit_script != null and body != self: hit_script.applyEffects(body, self)

#func _unhandled_input(event):
#	if Input.is_action_just_pressed('ui_accept'):
#		doAnimation()
