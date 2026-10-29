extends ResDamageProperty
class_name ResDamageTP

@export_range(1,4) var add_amount: int = 1

func getAttackEffect(_target:ResCombatant=null):
	return {'tp':add_amount}

func _to_string():
	return ('Gain %s[img]res://images/user_interface/tp_particle.png[/img]' % str(add_amount))+getStringCondition()
