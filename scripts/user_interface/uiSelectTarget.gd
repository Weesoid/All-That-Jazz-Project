extends Node2D

@onready var animator = $AnimationPlayer
var attached_combatant: ResCombatant

# WORK ON THIS!!!
func _process(delta):
	if attached_combatant != null:
		if CombatGlobals.getCombatScene().active_combatant == attached_combatant:
			if CombatGlobals.getCombatScene().target_combatant == attached_combatant:
				animator.play("Select")
			else:
				animator.play("Show")
		if CombatGlobals.getCombatScene().valid_targets != null and CombatGlobals.getCombatScene().valid_targets is Array:
			if CombatGlobals.getCombatScene().valid_targets.has(attached_combatant):
				animator.play("Show")
			else:
				animator.play("RESET")
