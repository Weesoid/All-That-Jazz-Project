extends ResEffectCondition
class_name ResChanceCondtion

@export_range(0.0,1.0) var chance:float = 0.0

func isPassed(combatant:ResCombatant)->bool:
	randomize()
	return CombatGlobals.randomRoll(chance)
