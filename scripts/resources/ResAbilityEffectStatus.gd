extends ResAbilityEffect
class_name ResApplyStatusEffect

enum Target {
	TARGET,
	CASTER
}

@export var target: Target
@export var status_effect: ResStatusEffect
@export var cast_animation: String = ''
