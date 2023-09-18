extends ResItem
class_name ResStackItem

var STACK = 1

func take(count: int):
	STACK -= count
	if STACK <= 0:
		PlayerGlobals.INVENTORY.erase(self)

func _to_string():
	return str(NAME, ' x', STACK)
