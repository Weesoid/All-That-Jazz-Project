extends Resource
class_name ResItem

@export var name: String
@export var icon: Texture = preload("res://images/sprites/item_unknown.png")
@export_multiline var description: String
@export var value: int
@export var mandatory = false
@export var parent_item: String # A path to the original item, only for duplicated items (e.g. Charms)

func _to_string():
	return str(name)

func getInformation():
	var out = '[center]'+OverworldGlobals.insertTextureCode(icon)+' '+name.to_upper()+'\n'
	out += description
	return out

func getGeneralInfo():
	var out = ''
	if value > 0:
		out += '[img]res://images/sprites/trade_slip.png[/img]%s	' % value
	return out

func getRarity():
	if value <= 0 and value < 100:
		return 0 # Common
	elif value >= 100 and value < 200:
		return 1 # Rare
	else:
		return 2 # Epic
