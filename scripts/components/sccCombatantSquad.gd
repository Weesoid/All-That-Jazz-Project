extends Node
class_name CombatantSquad
 
@export var UNIQUE_ID: String
@export var COMBATANT_SQUAD: Array[ResCombatant]
var afflicted_status_effects: Array[String]

func addLingeringEffect(status_effect_name: String):
	afflicted_status_effects.append(status_effect_name)

func removeLingeringEffect(status_effect_name: String):
	afflicted_status_effects.erase(status_effect_name)

func getRawDrops():
	var drops = {}
	for member in COMBATANT_SQUAD:
		drops.merge(member.getRawDrops())
	return drops

func getExperience():
	for member in COMBATANT_SQUAD:
		PlayerGlobals.addExperience(member.getExperience())
