extends ResAbilityAction
class_name ResLimitTPAction

@export_range(1,4) var amount: int = 1

func _to_string():
	return ('Gain %s[img]res://images/user_interface/slashed_tp.png[/img]' % str(amount))
