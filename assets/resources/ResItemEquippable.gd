extends ResItem
class_name ResEquippable

@export var STAT_MODIFICATIONS = {}
var EQUIPPED_COMBATANT: ResCombatant

func equip(_combatant: ResCombatant):
	pass

func unequip():
	pass

func applyStatModifications():
	if STAT_MODIFICATIONS.is_empty(): return
	for key in EQUIPPED_COMBATANT.BASE_STAT_VALUES.keys():
		if STAT_MODIFICATIONS.has(key):
			EQUIPPED_COMBATANT.BASE_STAT_VALUES[key] += STAT_MODIFICATIONS[key]
			EQUIPPED_COMBATANT.STAT_VALUES[key] = EQUIPPED_COMBATANT.BASE_STAT_VALUES[key]

func removeStatModifications():
	if STAT_MODIFICATIONS.is_empty(): return
	for key in EQUIPPED_COMBATANT.BASE_STAT_VALUES.keys():
		if STAT_MODIFICATIONS.has(key):
			EQUIPPED_COMBATANT.BASE_STAT_VALUES[key] -= STAT_MODIFICATIONS[key]
			EQUIPPED_COMBATANT.STAT_VALUES[key] = EQUIPPED_COMBATANT.BASE_STAT_VALUES[key]

func getStringStats():
	var result = ""
	for key in STAT_MODIFICATIONS.keys():
		result += key.to_upper() + ": " + str(STAT_MODIFICATIONS[key]) + "\n"
	return result

func getStatModifications():
	return STAT_MODIFICATIONS
