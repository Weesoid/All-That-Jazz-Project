extends ResStackItem
class_name ResProjectileAmmo

@export var OVERWORLD_EFFECT: GDScript

func use():
	STACK -= 1
	if STACK <= 0:
		PlayerGlobals.INVENTORY.erase(self)
	

func applyOverworldEffect(body: CharacterBody2D):
	OVERWORLD_EFFECT.applyEffect(body)

func equip():
	PlayerGlobals.EQUIPPED_ARROW = self
