extends ResItem
class_name ResStackItem

@export var PER_WEIGHT = 1
@export var MAX_STACK = 100

var STACK = 1

func add(count: int, show_prompt=true):
	if (STACK + count) > MAX_STACK:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Max stack for [color=yellow]%s[/color] reached!' % [NAME])
	else:
		STACK += count
		WEIGHT = PER_WEIGHT * STACK
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]x%s %s[/color] to Inventory.' % [count, NAME])

func take(count: int):
	STACK -= count
	WEIGHT = PER_WEIGHT * STACK
	if STACK <= 0:
		PlayerGlobals.INVENTORY.erase(self)
	PlayerGlobals.refreshWeights()

func _to_string():
	return str(NAME, ' x', STACK)
