extends ResItem
class_name ResStackItem

@export var MAX_STACK = 0
var STACK = 1

func add(count: int, show_prompt=true):
	print('adding!')
	if (count + STACK <= MAX_STACK and MAX_STACK != 0) or MAX_STACK == 0:
		STACK += count
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]x%s [color=white]to[/color] %s[/color].' % [count, NAME])
	else:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s [color=white]cannot be added. Max stack reached.' % [NAME])

func take(count: int):
	STACK -= count
	if STACK <= 0:
		InventoryGlobals.INVENTORY.erase(self)
