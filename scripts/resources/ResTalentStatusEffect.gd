extends ResTalent
class_name ResStatusEffectTalent

enum Apply_Type {
	APPEND,
	OVERRIDE
}

@export var status_effect: ResStatusEffect
@export var effects: Dictionary


func getRichDescription()-> String:
	return status_effect.getDescription()
