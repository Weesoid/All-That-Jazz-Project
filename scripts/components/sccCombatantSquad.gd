extends Node
class_name CombatantSquad
 
@export var combatant_squad: Array[ResCombatant]
var afflicted_status_effects: Array[String] # Effects in this array will ALWAYS be gone after combat.

func isTeamDead()->bool:
	var dead_count = 0
	for member in combatant_squad:
		if member.isDead(): dead_count += 1
	return dead_count == combatant_squad.size()

func addLingeringEffect(status_effect_name: String):
	afflicted_status_effects.append(status_effect_name)

func removeLingeringEffect(status_effect_name: String):
	afflicted_status_effects.erase(status_effect_name)

func getMember(member_name: String)-> ResCombatant:
	for member in combatant_squad:
		if member.NAME == member_name: return member
	
	return null

func hasMember(member_name: String)-> bool:
	for member in combatant_squad:
		if member.NAME == member_name: return true
	
	return false
