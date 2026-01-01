extends ResTalent
class_name ResStatusEffectTalent

@export var status_effect: ResStatusEffect

func getRichDescription()-> String:
	return '%s\n%s\n%s' % [name.to_upper(), status_effect.description, status_effect.getRichDescription()]
