extends Resource
class_name ResItem

@export var NAME: String
@export var ICON_NAME: String
@export var DESCRIPTION: String
@export var VALUE: int
@export var WEIGHT: int = 1

var ICON

func initializeItem():
	ICON = TextureRect.new()
	ICON.texture = load(str("res://assets/icons/"+ICON_NAME+".png"))

func _to_string():
	return str(NAME)
