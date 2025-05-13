extends Resource
class_name ResAbilityEffect

enum AnimateOn {
	TARGET,
	CASTER
}

## This effect will not execute unless the target has a combo token
@export var is_combo_effect: bool
@export var sound_effect: String = ''
@export var animation: PackedScene
@export var animation_time: float = 0.0
@export var animate_on: AnimateOn
