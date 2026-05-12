extends Resource
class_name ResTalent

@export var name: String
@export var description: String
@export var icon: Texture = preload("res://images/talent_icons/default.png")
@export var cost:int=1
@export var max_rank: int=1
@export var required_level:int=0

func _to_string():
	return name

func getRichDescription()-> String:
	return name.to_upper()+' ('+str(cost)+')'

func getTotalCost(rank:int):
	return rank*cost
