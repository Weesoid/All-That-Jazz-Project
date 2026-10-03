extends Resource
class_name ResAbilityEffect

enum AnimateOn {
	TARGET,
	CASTER
}

## This effect will not execute unless the target has a combo token
@export var condition: ResEffectCondition
@export var sound_effect: AudioStream
@export var animation: PackedScene
@export var animation_time: float = 0.0
@export var animate_on: AnimateOn

func conditionPassed(target:ResCombatant):
	return condition == null or condition.isPassed(target)

func stringifyConditionUnit()-> String:
	return ''

func stringifyCondition():
	return ''
