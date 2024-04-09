extends Node2D

@onready var animator = $AnimationPlayer
var attached_combatant: ResCombatant

# WORK ON THIS!!!
func _process(delta):
	if attached_combatant != null and CombatGlobals.getCombatScene().target_state != 0:
		if CombatGlobals.getCombatScene().target_combatant is ResCombatant:
			if CombatGlobals.getCombatScene().target_combatant == attached_combatant:
				show()
				animator.play("Select")
			elif CombatGlobals.getCombatScene().valid_targets is Array and CombatGlobals.getCombatScene().valid_targets.has(attached_combatant):
				show()
				animator.play("Show")
			else:
				hide()
				animator.play("RESET")
		if CombatGlobals.getCombatScene().target_combatant is Array and CombatGlobals.getCombatScene().valid_targets.has(attached_combatant):
			show()
			animator.play("Select")
		elif CombatGlobals.getCombatScene().target_combatant is Array and !CombatGlobals.getCombatScene().valid_targets.has(attached_combatant):
			hide()
			animator.play("RESET")
