extends Node
class_name CombatantSquad
 
@export var UNIQUE_ID: String
@export var COMBATANT_SQUAD: Array[ResCombatant]

func getRawDrops():
	var drops = {}
	for member in COMBATANT_SQUAD:
		drops.merge(member.getRawDrops())
	return drops

func getExperience():
	for member in COMBATANT_SQUAD:
		PlayerGlobals.addExperience(member.getExperience())
