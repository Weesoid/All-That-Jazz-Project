extends ResStackItem
class_name ResCampItem

@export var effects: Array[ResBasicEffect]

func applyEffects():
	for effect in effects:
		print(effect)
