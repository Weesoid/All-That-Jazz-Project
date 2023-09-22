extends ResItem
class_name ResStackItem

@export var PER_WEIGHT = 1
@export var MAX_STACK = 100

var STACK = 1

func add(count: int, show_prompt=true):
	if (STACK + count) > MAX_STACK:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] could not be added, you have too many!' % [NAME])
	else:
		STACK += count
		WEIGHT = PER_WEIGHT * STACK
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]x%s [color=white]to[/color] %s[/color].' % [count, NAME])

func take(count: int):
	STACK -= count
	WEIGHT = PER_WEIGHT * STACK
	if STACK <= 0:
		PlayerGlobals.INVENTORY.erase(self)
	PlayerGlobals.refreshWeights()

func _to_string():
	return str(NAME, ' x', STACK)
