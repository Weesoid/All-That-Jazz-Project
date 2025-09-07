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

func _to_string():
	return stringifyCondition()+'[color=dark_turquoise]'+getWording()+' '+str(move_count)+'[/color]'

func getWording():
	if target == Target.CASTER and direction == Direction.FORWARD:
		return 'Forward'
	elif target == Target.CASTER and direction == Direction.BACK:
		return 'Back'
	elif target == Target.TARGET and direction == Direction.FORWARD:
		return 'Push'
	elif target == Target.TARGET and direction == Direction.BACK:
		return 'Pull'
