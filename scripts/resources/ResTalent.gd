extends Resource
class_name ResTalent

@export var name: String
@export var description: String
@export var icon: Texture = preload("res://images/talent_icons/default.png")
@export var max_rank: int=1
@export var required_level:int=0
@export var reuired_talent: ResTalent

func _to_string():
	return name

func getRichDescription()-> String:
	return name
