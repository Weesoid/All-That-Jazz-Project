extends Projectile
class_name ProjectileBattles

@export var hit_script: GDScript
@export var target: CombatantScene

func _on_body_entered(body):
	if body is CombatantScene and CombatGlobals.getCombatantType(SHOOTER.combatant_resource) != CombatGlobals.getCombatantType(body.combatant_resource) and target == null:
		hit_script.applyEffects(body, SHOOTER)
	elif target != null and body == target:
		hit_script.applyEffects(body, SHOOTER)
		queue_free()
