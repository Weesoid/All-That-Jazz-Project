extends ResAttackBonus
class_name ResAttackStats

@export var stats:Dictionary= CombatExtras.ALL_STATS

func getAttackEffect():
	return CombatGlobals.getStatChanges(stats)
