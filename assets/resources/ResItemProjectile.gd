extends ResConsumable
class_name ResProjectileAmmo

@export var OVERWORLD_EFFECT: GDScript

func applyOverworldEffect(body: CharacterBody2D):
	OVERWORLD_EFFECT.applyEffect(body)

func equip():
	PlayerGlobals.EQUIPPED_ARROW = self

func _to_string():
	return str(NAME, ' x', STACK)
