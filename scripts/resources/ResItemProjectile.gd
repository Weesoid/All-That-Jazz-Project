extends ResStackItem
class_name ResProjectileAmmo

@export var overworld_effect: GDScript

func applyOverworldEffect(body: CharacterBody2D):
	overworld_effect.applyEffect(body)

func equip():
	if !OverworldGlobals.getCurrentMap().has_node('PlayerArrow'):
		OverworldGlobals.playSound("res://audio/sounds/709597__alexcoover__unsheath-arrow.ogg", -16.0)
		PlayerGlobals.equipped_arrow = self
