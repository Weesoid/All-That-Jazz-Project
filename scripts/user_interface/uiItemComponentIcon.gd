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

func update_counts():
	var item_count = InventoryGlobals.getItemCount(item)
	if item.name.contains('Rushy'):
		print('rushy ic ', item_count)
	
	if !is_result:
		required_count.text = '%s/%s' % [str(item_count), str(required)]
		modulate = Color.DARK_RED if required > item_count else Color.WHITE
	else:
		var count_string = getCurrentCountString(item)
		required_count.text = count_string[0]
		required_count.modulate = count_string[1]

## Returns [<Count string>, <String color>] e.g. ["16/16", Color.YELLOW]
static func getCurrentCountString(p_item: ResItem):
	var item_count = InventoryGlobals.getItemCount(p_item)
	var max:int=-1
	if p_item is ResStackItem:
		max = p_item.max_stack
	elif p_item is ResWeapon:
		max = 1
	
	if max > 0 and max != 9999:
		return [str('%s/%s' % [item_count, max]), Color.YELLOW if item_count == max else Color.WHITE]
	else:
		return [str(item_count), Color.YELLOW if item_count == max else Color.WHITE]
