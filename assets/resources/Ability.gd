extends Resource
class_name Ability

enum TargetType {
	SINGLE,
	MULTI,
	RANDOM
}

enum TargetGroup {
	ALLIES,
	ENEMIES
}

@export var ANIMATION_NAME: String
@export var ABILITY_SCRIPT_NAME: String
@export var TARGET_TYPE: TargetType
@export var TARGET_GROUP: TargetGroup

var ABILITY_SCRIPT
var ANIMATION

signal single_target
signal multi_target
signal random_target

func initializeAbility():
	ABILITY_SCRIPT = load(str("res://assets/scripts/ability_scripts/"+ABILITY_SCRIPT_NAME+".gd"))
	ANIMATION = load(str("res://assets/scene_assets/animations/abilities/"+ANIMATION_NAME+".tscn")).instantiate()

func execute():
	match TARGET_TYPE:
		TargetType.SINGLE: single_target.emit()
		TargetType.RANDOM: random_target.emit()
		TargetType.MULTI: multi_target.emit()
