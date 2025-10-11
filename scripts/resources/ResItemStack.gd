extends ResItem
class_name ResStackItem

@export var max_stack = 0
@export var barter_item:bool = false
var stack = 1

func add(count: int, show_prompt=true):
	if (count + stack <= max_stack and max_stack != 0) or max_stack == 0:
		InventoryGlobals.stack_item_changed.emit(self, stack+count, stack)
		stack += count
		if show_prompt: OverworldGlobals.showPrompt('Added [color=yellow]%s (%s)[/color].' % [name, stack])
	else:
		InventoryGlobals.stack_item_changed.emit(self, max_stack, stack)
		stack = max_stack
		if show_prompt: OverworldGlobals.showPrompt('[color=yellow]%s[color=white] max stack reached.' % [name])

func updateItem():
	if !FileAccess.file_exists(parent_item):
		InventoryGlobals.inventory.erase(self)
		#InventoryGlobals.removeItemResource(self)
		return
	
	var loaded_parent_item = load(parent_item)
	name = loaded_parent_item.name
	icon = loaded_parent_item.icon
	description = loaded_parent_item.description
	value = loaded_parent_item.value
	mandatory = loaded_parent_item.mandatory
	max_stack = loaded_parent_item.max_stack
	barter_item = loaded_parent_item.barter_item
	print(max_stack)
	if max_stack > 0 and stack > max_stack:
		stack = max_stack
	if stack < 0:
		InventoryGlobals.inventory.erase(self)

func take(count: int):
	InventoryGlobals.stack_item_changed.emit(self, stack-count, stack)
	stack -= count
	if stack <= 0:
		InventoryGlobals.inventory.erase(self)
