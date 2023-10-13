extends Resource
class_name ResItem

@export var NAME: String
@export var ICON: Texture
@export var DESCRIPTION: String
@export var VALUE: int
@export var WEIGHT: int = 1
@export var MANDATORY = false

func _to_string():
	return str(NAME)

func getInformation():
	var out = ''
	out += "W: %s V: %s\n\n" % [WEIGHT, VALUE]
	out += DESCRIPTION
	return out
