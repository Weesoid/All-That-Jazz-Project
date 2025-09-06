extends ResAbilityEffect
class_name ResAddTPEffect

@export var add_amount: int

func _to_string():
	var str_condition = ''
	if condition != '':
		str_condition += CombatGlobals.stringifyBonusStatConditions(condition.split('/'))+' : '
	return str_condition+' Add %s TP' % add_amount # Probably continue this idk
