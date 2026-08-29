extends ResAbilityEffect
class_name ResHealEffect

@export var base_heal: int = 0
@export_range(0.0,1.0) var percent_heal:float = 0.0
@export var use_multiplier: bool = true
@export var revive_from_ko:bool=false
@export var cast_animation: String = ''

func _to_string():
	var out = ''
	var condition_str = ' '+condition._to_string() if condition != null else ''
	
	#return '[color=green]Heal %s%s [/color] %s' % [str(base_heal), ' (Flat)' if !use_multiplier else '', condition._to_string() if condition != null else ''] #+ ' (Flat)' if !use_multiplier else '' + '[/color]'
	if base_heal > 0:
		out += '[color=green]Heal %s [/color]' % str(base_heal)
		if !use_multiplier:
			out += ' (Flat)'
	if percent_heal > 0:
		if out != '': out += '\n'
		out += '[color=green]Heal %s' % str(int(percent_heal*100))+'%[/color]'
		if !use_multiplier:
			out += ' (Flat)'
	
	out += condition_str
	return out
