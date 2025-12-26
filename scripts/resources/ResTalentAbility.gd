extends ResTalent
class_name ResAbilityTalent

enum Apply_Type {
	APPEND,
	OVERRIDE
}

@export var ability_modifications: Dictionary
@export var apply_type: Apply_Type = Apply_Type.OVERRIDE
