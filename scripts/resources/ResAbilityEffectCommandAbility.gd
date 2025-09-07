extends ResAbilityEffect
class_name ResCommandAbilityEffect

@export var ability: ResAbility

func _to_string():
	return stringifyCondition()+'Cast '+ability.name
