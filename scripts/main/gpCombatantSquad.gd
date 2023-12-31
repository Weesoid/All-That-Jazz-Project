extends Node
class_name CombatantSquad
 
@export var UNIQUE_ID: String
@export var COMBATANT_SQUAD: Array[ResCombatant]

func getDrops():
	for member in COMBATANT_SQUAD:
		member.getDrops()

func getExperience():
	for member in COMBATANT_SQUAD:
		print(member)
		member.BASE_STAT_VALUES = member.STAT_VALUES.duplicate()
		PlayerGlobals.addExperience(member.getExperience())
