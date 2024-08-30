extends Node2D
class_name WeaponScene

@onready var hit_box = $Sprite2D/Area2D
@onready var animator = $AnimationPlayer
@export var hit_script: GDScript
var equipped_combatant: PlayerCombatantScene

func showWeapon(sheathe:bool=false):
	if !sheathe:
		animator.play('Show')
	else:
		animator.play('RESET')

func _on_area_2d_body_entered(body):
	if hit_script != null and body != equipped_combatant: 
		hit_script.applyEffects(body, equipped_combatant)
