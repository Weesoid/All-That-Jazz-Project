extends AbilityAnimation
class_name WeaponScene

@onready var hit_box = $Sprite2D/Area2D
@export var hit_script: GDScript
var equipped_combatant: PlayerCombatantScene

func _enter_tree():
	equipped_combatant = get_parent()

func showWeapon(sheathe:bool=false):
	if !sheathe:
		animator.play('Show')
	else:
		animator.play('RESET')
	await animator.animation_finished

func _on_area_2d_body_entered(body):
	if hit_script == null or body == equipped_combatant or !body is CombatantScene:
		return 
	
	hit_script.applyEffects(body, equipped_combatant)
