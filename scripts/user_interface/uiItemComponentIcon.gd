extends TextureRect
class_name ItemComponentIcon

var item: ResItem
var required: int
var craft_count:int
var is_result:bool=false
@onready var required_count = $RequiredCount
@onready var craft_count_label = $CraftCount

func setItem(p_item:ResItem, p_required:int, p_craft_count:int=-1):
	craft_count_label.hide()
	item = p_item
	required = p_required
	
	texture = item.icon
	if p_craft_count > 0:
		craft_count = p_craft_count
		is_result = true
		if craft_count > 1:
			craft_count_label.text = '+'+str(craft_count)
			craft_count_label.show()
	
	update_counts()

func doPopTween():
	var scale_tween = create_tween()
	scale_tween.tween_property(self,'scale',Vector2(1.25,1.25),0.1).set_ease(Tween.EASE_IN)
	scale_tween.tween_property(self,'scale',Vector2(1,1),0.25).set_ease(Tween.EASE_OUT)

func update_counts(is_repair:bool=false):
	var item_count = InventoryGlobals.getItemCount(item)
	
#	if is_weapon_component_repair and !is_result:
#		var has_weapon = InventoryGlobals.hasItem(item)
#		required_count.text = '1' if has_weapon else '0'
#		modulate = Color.DARK_RED if !has_weapon else Color.WHITE
	if !is_result:
		required_count.text = '%s/%s' % [str(item_count), str(required)]
		modulate = Color.DARK_RED if required > item_count else Color.WHITE
	else:
		var count_string
		if is_repair: 
			count_string = ItemComponentIcon.getCurrentDurabilityString(item)
		else:
			count_string = ItemComponentIcon.getCurrentCountString(item)
		required_count.text = count_string[0]
		required_count.modulate = count_string[1]

## Returns [<Count string>, <String color>] e.g. ["16/16", Color.YELLOW]
static func getCurrentCountString(p_item: ResItem):
	var item_count = InventoryGlobals.getItemCount(p_item)
	var maximum:int=-1
	if p_item is ResStackItem:
		maximum = p_item.max_stack
	elif p_item.isRepairable():
		maximum = 1
	
	if maximum > 0 and maximum != 9999:
		return [str('%s/%s' % [item_count, maximum]), Color.YELLOW if item_count == maximum else Color.WHITE]
	else:
		return [str(item_count), Color.YELLOW if item_count == maximum else Color.WHITE]

static func getCurrentDurabilityString(p_weapon:ResItem):
	return [str(p_weapon.durability)+'/'+str(p_weapon.max_durability), Color.YELLOW if p_weapon.durability == p_weapon.max_durability else Color.WHITE]
