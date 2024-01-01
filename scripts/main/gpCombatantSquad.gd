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
		member.BASE_STAT_VALUES = member.STAT_VALUES.duplicate()
		PlayerGlobals.addExperience(member.getExperience())

func clearSquadEffects():
	for member in COMBATANT_SQUAD:
		member.STATUS_EFFECTS.clear()
