extends ResAttackBonus
class_name ResAttackTP

@export var add_amount: int

func getAttackEffect():
	return {'tp':add_amount}
