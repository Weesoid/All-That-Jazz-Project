extends ResAbilityEffect
class_name ResApplyStatusEffect

enum Target {
	TARGET,
	CASTER
}

@export var target: Target
@export var status_effect: ResStatusEffect
@export var guaranteed:bool=false
@export var add_duration:int=0
@export var cast_animation: String = ''

func _to_string():
	var out = ''
	var condition_str = ' '+condition._to_string() if condition != null else ''
	
	if target == Target.TARGET:
		out += 'Target '
	elif target == Target.CASTER:
		out += 'Self '
	out += status_effect.getMessageIcon()
	return stringifyCondition()+out+condition_str
