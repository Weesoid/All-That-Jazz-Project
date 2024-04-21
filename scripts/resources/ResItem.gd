extends Resource
class_name ResItem

@export var NAME: String
@export var ICON: Texture = preload("res://images/sprites/item_unknown.png")
@export var DESCRIPTION: String
@export var VALUE: int
@export var MANDATORY = false

func _to_string():
	return str(NAME)

func getInformation():
	return DESCRIPTION

func getGeneralInfo():
	var out = ''
	out += '[img]res://images/sprites/icon_value.png[/img]%s' % VALUE
	return out

func getRarity():
	if VALUE <= 0 and VALUE < 100:
		return 0 # Common
	elif VALUE >= 100 and VALUE < 200:
		return 1 # Rare
	else:
		return 2 # Epic
