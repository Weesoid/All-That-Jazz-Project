extends ResAbilityEffect
class_name ResCommandAbilityEffect

@export var ability: ResAbility

func _to_string():
	var str_condition = ''
	if condition != '':
		str_condition += CombatGlobals.stringifyBonusStatConditions(condition.split('/'))+' : '
	return str_condition+'Cast '+ability.name
