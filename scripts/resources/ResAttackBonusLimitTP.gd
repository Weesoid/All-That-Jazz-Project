extends ResDamageProperty
class_name ResDamageLimitTP

@export_range(1,4) var amount: int = 1

func getAttackEffect(_target:ResCombatant=null):
	return {'limit_tp':amount}

func _to_string():
	return ('Gain %s[img]res://images/user_interface/slashed_tp.png[/img]' % str(amount))+getStringCondition()
