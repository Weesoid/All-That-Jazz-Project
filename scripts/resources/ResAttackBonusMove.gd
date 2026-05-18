extends ResAttackBonus
class_name ResAttackMove

enum Direction {
	PULL = 1,
	PUSH = -1
}

@export var direction:Direction
@export_range(1,3) var move_count:int

func getAttackEffect():
	return {'move': self}
