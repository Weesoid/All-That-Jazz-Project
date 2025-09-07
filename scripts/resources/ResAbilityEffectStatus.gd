extends ResAbilityEffect
class_name ResApplyStatusEffect

enum Target {
	TARGET,
	CASTER
}

@export var target: Target
@export var status_effect: ResStatusEffect
@export var cast_animation: String = ''

func _to_string():
	var out = ''
	if target == Target.TARGET:
		out += 'Target '
	elif target == Target.CASTER:
		out += 'Self '
	out += status_effect.getMessageIcon()
	return stringifyCondition()+out
