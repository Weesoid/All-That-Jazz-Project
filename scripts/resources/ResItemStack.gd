extends ResItem
class_name ResStackItem

var STACK = 1

func add(count: int, show_prompt=true):
	STACK += count
	if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]x%s [color=white]to[/color] %s[/color].' % [count, NAME])

func take(count: int):
	STACK -= count
	if STACK <= 0:
		InventoryGlobals.INVENTORY.erase(self)
