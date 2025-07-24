extends ResItem
class_name ResStackItem

@export var MAX_STACK = 0
@export var BARTER_ITEM:bool = false
var STACK = 1

func add(count: int, show_prompt=true):
	if (count + STACK <= MAX_STACK and MAX_STACK != 0) or MAX_STACK == 0:
		STACK += count
		if show_prompt: OverworldGlobals.showPrompt('Added [color=yellow]%s (%s)[/color].' % [NAME, STACK])
	else:
		STACK = MAX_STACK
		if show_prompt: OverworldGlobals.showPrompt('[color=yellow]%s[color=white] max stack reached.' % [NAME])

func take(count: int):
	STACK -= count
	if STACK <= 0:
		InventoryGlobals.inventory.erase(self)
