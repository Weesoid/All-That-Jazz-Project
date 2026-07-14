extends ResItem
class_name ResStackItem

@export var max_stack = 9999
@export var barter_item:bool = false
var stack = 1

func add(count: int):
	if (count + stack <= max_stack and max_stack != 0) or max_stack == 0:
		InventoryGlobals.stack_item_changed.emit(self, count)
		stack += count
		#if show_prompt: OverworldGlobals.showPrompt('Added [color=yellow]%s (%s)[/color].' % [name, stack])
	else:
		InventoryGlobals.stack_item_changed.emit(self, count)
		stack = max_stack
		#if show_prompt: OverworldGlobals.showPrompt('[color=yellow]%s[color=white] max stack reached.' % [name])

func updateItem():
#	if !FileAccess.file_exists(resource_path):
#		InventoryGlobals.inventory.erase(self)
#		#InventoryGlobals.removeItemResource(self)
#		return
#
#	var loaded_parent_item = load(parent_item)
#	name = loaded_parent_item.name
#	icon = loaded_parent_item.icon
#	description = loaded_parent_item.description
#	value = loaded_parent_item.value
#	mandatory = loaded_parent_item.mandatory
#	max_stack = loaded_parent_item.max_stack
#	barter_item = loaded_parent_item.barter_item
	if max_stack > 0 and stack > max_stack:
		stack = max_stack
	if stack < 0:
		InventoryGlobals.inventory.erase(self)

func take(count: int):
	stack -= count
	InventoryGlobals.stack_item_changed.emit(self, -count)
	if stack <= 0:
		InventoryGlobals.inventory.erase(self)
