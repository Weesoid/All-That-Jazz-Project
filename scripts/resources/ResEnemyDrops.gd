extends Resource
class_name ResEnemyDrops

@export var item:ResItem
@export var drop_count:int=1
@export var drop_count_variance:float=0.5
@export_range(0.0,1.0) var drop_chance:float=1.0

func getDropCount()->int:
	var max_roll = ceil(drop_count*drop_count_variance)
	var count_variance = randi_range(0, max_roll) 
	return drop_count+max_roll
