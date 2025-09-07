extends ResAbilityEffect
class_name ResHealEffect

@export var heal := 0
@export var use_multiplier: bool = true
@export var cast_animation: String = ''

func _to_string():
	return stringifyCondition()+'[color=green]Heal %s[/color]' % str(heal)
