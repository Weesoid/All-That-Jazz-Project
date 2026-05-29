extends ResAttackBonus
class_name ResAttackTP

@export var add_amount: int

func getAttackEffect():
	return {'tp':add_amount}

func _to_string():
	return ('Gain %s[img]res://images/user_interface/tp_particle.png[/img]' % str(add_amount))+getStringCondition()
