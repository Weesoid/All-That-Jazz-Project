extends ResItem
class_name ResStackItem

@export var max_stack = 0
@export var barter_item:bool = false
var stack = 1

func add(count: int, show_prompt=true):
	if (count + stack <= max_stack and max_stack != 0) or max_stack == 0:
		stack += count
		if show_prompt: OverworldGlobals.showPrompt('Added [color=yellow]%s (%s)[/color].' % [name, stack])
	else:
		stack = max_stack
		if show_prompt: OverworldGlobals.showPrompt('[color=yellow]%s[color=white] max stack reached.' % [name])

func updateItem():
	if !FileAccess.file_exists(parent_item):
		InventoryGlobals.removeItemResource(self)
		return
	
	var parent_item = load(parent_item)
	name = parent_item.name
	icon = parent_item.icon
	description = parent_item.description
	value = parent_item.value
	mandatory = parent_item.mandatory
	max_stack = parent_item.max_stack
	barter_item = parent_item.barter_item

func take(count: int):
	stack -= count
	if stack <= 0:
		InventoryGlobals.inventory.erase(self)
