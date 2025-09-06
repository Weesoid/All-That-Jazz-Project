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
	var str_condition = ''
	if condition != '':
		str_condition += CombatGlobals.stringifyBonusStatConditions(condition.split('/'))+' : '
	return str_condition+'[color=dark_turquoise]'+str(Direction.find_key(direction)).capitalize()+' '+str(move_count)+'[/color]'
