extends Resource
class_name ResAbilityEffect

enum AnimateOn {
	TARGET,
	CASTER
}

@export var sound_effect: String = ''
@export var animation: PackedScene
@export var animation_time: float = 0.0
@export var animate_on: AnimateOn
