extends ResAbilityAction
class_name ResCommandAbilityAction

@export var ability: ResAbility

func _to_string():
	return stringifyCondition()+'Cast '+ability.name
