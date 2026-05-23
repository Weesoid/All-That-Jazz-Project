extends ResAttackBonus
class_name ResAttackDot

@export var dot_effects: Array[ResDamageOvertimeEffect]

func getAttackEffect():
	var all_effects = []
	for dot in dot_effects:
		all_effects.append(dot.getDotEffect())
	
	return {'dot_effects': all_effects}
