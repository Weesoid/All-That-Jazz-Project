extends Node
class_name CombatantSquad
 
@export var COMBATANT_SQUAD: Array[ResCombatant]

func isTeamDead()->bool:
	var dead_count = 0
	for member in COMBATANT_SQUAD:
		if member.isDead(): dead_count += 1
	return dead_count == COMBATANT_SQUAD.size()
