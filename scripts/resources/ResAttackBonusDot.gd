extends ResAttackBonus
class_name ResAttackDot

@export var dot_effect: ResDamageOvertimeEffect

func getAttackEffect():
	return {'dot_effect': dot_effect.getDotEffect()}
