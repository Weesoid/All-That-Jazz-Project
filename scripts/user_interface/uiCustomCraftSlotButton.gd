extends ItemSlot
class_name CraftingSlot

@onready var count_label = $CountLabel

var current_recipe

func _get_drag_data(at_position):
	if item == null:
		return
	var item_copy = item
	set_drag_preview(getPreview())
	setItem(null)
	pick_up_feedback()
	item_dragged.emit(item_copy)
	return item_copy

func _can_drop_data(_at_position, data):
	return data is ResItem and !current_recipe.has(data.getFilename())

func _drop_data(_at_position, data):
	var previous_item=item
	setItem(data)
	
	drop_feedback()
	item_received.emit(item, previous_item)

func setItem(data: ResItem):
	if item != null:
		item_replaced.emit(item)
	item = data
	if data != null:
		icon = data.icon
		description_text = data.getInformation()
		count_label.show()
	else:
		icon = empty_icon
		description_text = ''
		count_label.hide()

func update_count(item_to_craft:ResItem):
	if item_to_craft == null:
		if item != null: count_label.text = str(InventoryGlobals.getItemCount(item))
		return
	
	if item != null:
		var recipe_dict = InventoryGlobals.getRecipe(item_to_craft)
		if recipe_dict.has(item.getFilename()):
			count_label.text = str(InventoryGlobals.getItemCount(item))+'/'+str(recipe_dict[item.getFilename()])
