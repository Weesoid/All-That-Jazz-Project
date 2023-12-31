extends Node
class_name CombatantSquad
 
@export var UNIQUE_ID: String
@export var COMBATANT_SQUAD: Array[ResCombatant]

func getDrops():
	for member in COMBATANT_SQUAD:
		member.getDrops()

func getExperience():
	for member in COMBATANT_SQUAD:
		member.BASE_STAT_VALUES = member.STAT_VALUES.duplicate()
		PlayerGlobals.addExperience(member.getExperience())

func applyEffectToSquad(status_effect: ResStatusEffect):
	for member in COMBATANT_SQUAD:
		print('Adding %s to %s' % [status_effect, member])
		member.STATUS_EFFECTS.append(status_effect.duplicate())

func clearSquadEffects():
	for member in COMBATANT_SQUAD:
		member.STATUS_EFFECTS.clear()
