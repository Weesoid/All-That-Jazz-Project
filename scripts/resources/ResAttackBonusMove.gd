extends ResAttackBonus
class_name ResAttackMove

enum Direction {
	PUSH,
	PULL
}

@export var direction:Direction=Direction.PUSH
@export_range(1,3) var move_count:int=1

func getAttackEffect():
	return {'move': self}

func getDirection():
	return 1 if direction == Direction.PUSH else -1
