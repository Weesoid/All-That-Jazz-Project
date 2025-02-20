extends ResAbilityEffect
class_name ResMoveEffect

enum Target {
	TARGET,
	CASTER
}
enum Direction {
	FORWARD,
	BACK
}

@export var target: Target
@export var direction: Direction
@export var move_count: int = 1
