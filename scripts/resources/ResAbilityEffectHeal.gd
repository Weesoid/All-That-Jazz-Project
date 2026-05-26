extends ResAbilityEffect
class_name ResHealEffect

@export var base_heal: int = 0
@export_range(0.0,1.0) var percent_heal:float = 0.0
@export var use_multiplier: bool = true
@export var cast_animation: String = ''

func _to_string():
	return stringifyCondition()+'[color=green]Heal %s%s [/color]' % [str(base_heal), ' (Flat)' if !use_multiplier else ''] #+ ' (Flat)' if !use_multiplier else '' + '[/color]'
