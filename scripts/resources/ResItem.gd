extends Resource
class_name ResItem

@export var name: String
@export var icon: Texture = preload("res://images/sprites/item_unknown.png")
@export_multiline var description: String
@export var value: int
@export var mandatory:bool = false
#@export var parent_item: String # A path to the original item, only for duplicated items (e.g. Charms)
@export var allow_duplicates:bool=false

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

func getFilename()-> String:
#	if parent_item != '':
#		return parent_item.get_file().replace('.tres','')
#	else:
	return resource_path.get_file().replace('.tres','')

func getRarity():
	if value <= 0 and value < 100:
		return 0 # Common
	elif value >= 100 and value < 200:
		return 1 # Rare
	else:
		return 2 # Epic

func getIconBB():
	return OverworldGlobals.insertTextureCode(icon)

func isRepairable():
	var conditions_met:int=0
	
	for property in get_property_list():
		var p_name = property.name
		if p_name == 'max_durability' or p_name == 'durability' or p_name == 'repair_item' or p_name == 'repair_cost':
			conditions_met += 1
		if conditions_met == 4:
			return true
	
	return false
	
	#print(get_property_list())
