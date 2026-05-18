extends ResAttackBonus
class_name ResAttackStatusEffect

@export var status_effects: Array[ResStatusEffect]

func getAttackEffect():
	return {'status_effects': status_effects}

