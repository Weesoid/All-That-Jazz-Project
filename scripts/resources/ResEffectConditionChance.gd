extends ResEffectCondition
class_name ResChanceCondtion

@export_range(0.0,1.0) var chance:float = 0.0

func isPassed(_combatant:ResCombatant)->bool:
	randomize()
	return CombatGlobals.randomRoll(chance)

func _to_string():
	return '\n(%s%% chance)' % str(int(chance*100))
