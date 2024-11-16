extends ResStackItem
class_name ResProjectileAmmo

@export var OVERWORLD_EFFECT: GDScript

func applyOverworldEffect(body: CharacterBody2D):
	OVERWORLD_EFFECT.applyEffect(body)

func equip():
	if !OverworldGlobals.getCurrentMap().has_node('PlayerArrow'):
		OverworldGlobals.playSound("res://audio/sounds/709597__alexcoover__unsheath-arrow.ogg", -16.0)
		PlayerGlobals.EQUIPPED_ARROW = self
