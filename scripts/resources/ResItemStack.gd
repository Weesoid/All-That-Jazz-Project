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

func take(count: int):
	stack -= count
	if stack <= 0:
		InventoryGlobals.inventory.erase(self)
