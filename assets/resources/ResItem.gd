extends Resource
class_name ResItem

@export var NAME: String
@export var ICON_NAME: String

var ICON
var ITEM_SCRIPT
var ANIMATION

func initializeItem():
	ICON = TextureRect.new()
	ICON.texture = load(str("res://assets/icons/"+ICON_NAME+".png"))
	
