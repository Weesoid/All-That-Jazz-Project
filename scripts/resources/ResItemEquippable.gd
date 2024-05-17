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
	CombatGlobals.modifyStat(EQUIPPED_COMBATANT, STAT_MODIFICATIONS, NAME)

func removeStatModifications():
	if STAT_MODIFICATIONS.is_empty() or !isEquipped(): return
	CombatGlobals.resetStat(EQUIPPED_COMBATANT, NAME)

func getStringStats():
	var result = ""
	for key in STAT_MODIFICATIONS.keys():
		if STAT_MODIFICATIONS[key] > 0 and STAT_MODIFICATIONS[key]:
			result += key.to_upper() + " +" + str(STAT_MODIFICATIONS[key]) + "\n"
		else:
			result += key.to_upper() + " " + str(STAT_MODIFICATIONS[key]) + "\n"
	return result

func isEquipped():
	return EQUIPPED_COMBATANT != null

func getStatModifications():
	return STAT_MODIFICATIONS

func getInformation():
	var out = OverworldGlobals.insertTextureCode(ICON)+' '+NAME.to_upper()+'\n'
	out += getStringStats()+"\n"
	out += DESCRIPTION
	return out
