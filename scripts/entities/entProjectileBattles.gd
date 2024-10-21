extends Projectile
class_name ProjectileBattles

@export var hit_script: GDScript
@export var target: CombatantScene

func _on_body_entered(body):
	if body is CombatantScene and body.combatant_resource.hasStatusEffect('Overguard') and !CombatGlobals.isSameCombatantType(body.combatant_resource, SHOOTER):
		if body is PlayerCombatantScene:
			body.doAnimation('Block')
		else:
			body.doAnimation('Cast_Melee')
		OverworldGlobals.playSound('348244__newagesoup__punch-boxing-01.ogg')
		hit_script.applyEffects(SHOOTER, body, CombatGlobals.getCombatScene().selected_ability)
		queue_free()
	elif body is CombatantScene and !CombatGlobals.isSameCombatantType(SHOOTER, body) and target == null:
		hit_script.applyEffects(SHOOTER, body, CombatGlobals.getCombatScene().selected_ability)
	elif target != null and body == target:
		hit_script.applyEffects(SHOOTER, body, CombatGlobals.getCombatScene().selected_ability)
		queue_free()

func _exit_tree():
	pass
