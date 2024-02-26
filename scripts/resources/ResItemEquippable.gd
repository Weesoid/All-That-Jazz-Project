extends ResItem
class_name ResEquippable

@export var STAT_MODIFICATIONS = {}
var EQUIPPED_COMBATANT: ResCombatant

func equip(_combatant: ResCombatant):
	pass

func unequip():
	pass

func applyStatModifications():
	if STAT_MODIFICATIONS.is_empty() or !isEquipped(): return
	var previous_health = EQUIPPED_COMBATANT.BASE_STAT_VALUES['health']
	for key in EQUIPPED_COMBATANT.BASE_STAT_VALUES.keys():
		if STAT_MODIFICATIONS.has(key):
			if STAT_MODIFICATIONS[key] is float:
				EQUIPPED_COMBATANT.BASE_STAT_VALUES[key] += int(STAT_MODIFICATIONS[key]*EQUIPPED_COMBATANT.BASE_STAT_VALUES[key])
			elif STAT_MODIFICATIONS[key] is int:
				EQUIPPED_COMBATANT.BASE_STAT_VALUES[key] += STAT_MODIFICATIONS[key]
			
	EQUIPPED_COMBATANT.updateStatValues(previous_health)

func removeStatModifications():
	if STAT_MODIFICATIONS.is_empty() or !isEquipped(): return
	var previous_health = EQUIPPED_COMBATANT.BASE_STAT_VALUES['health']
	for key in EQUIPPED_COMBATANT.BASE_STAT_VALUES.keys():
		if STAT_MODIFICATIONS.has(key):
			if STAT_MODIFICATIONS[key] is float:
				EQUIPPED_COMBATANT.BASE_STAT_VALUES[key] -= int(STAT_MODIFICATIONS[key]*EQUIPPED_COMBATANT.BASE_STAT_VALUES[key])
			elif STAT_MODIFICATIONS[key] is int:
				EQUIPPED_COMBATANT.BASE_STAT_VALUES[key] -= STAT_MODIFICATIONS[key]
	
	EQUIPPED_COMBATANT.updateStatValues(previous_health)

func getStringStats():
	var result = ""
	for key in STAT_MODIFICATIONS.keys():
		if STAT_MODIFICATIONS[key] is int:
			if STAT_MODIFICATIONS[key] > 0 and STAT_MODIFICATIONS[key]:
				result += key.to_upper() + " +" + str(STAT_MODIFICATIONS[key]) + "\n"
			else:
				result += key.to_upper() + " " + str(STAT_MODIFICATIONS[key]) + "\n"
		elif STAT_MODIFICATIONS[key] is float:
			if STAT_MODIFICATIONS[key] > 0 and STAT_MODIFICATIONS[key]:
				result += key.to_upper() + " +" + str(STAT_MODIFICATIONS[key]*100) + "%\n"
			else:
				result += key.to_upper() + " " + str(STAT_MODIFICATIONS[key]*100) + "%\n"
	return result

func isEquipped():
	return EQUIPPED_COMBATANT != null

func getStatModifications():
	return STAT_MODIFICATIONS

func getInformation():
	var out = ""
	out += "W: %s V: %s\n\n" % [WEIGHT, VALUE]
	out += getStringStats()+"\n\n"
	out += DESCRIPTION
	return out
