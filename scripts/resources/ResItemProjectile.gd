extends ResStackItem
class_name ResProjectileAmmo

@export var OVERWORLD_EFFECT: GDScript

func applyOverworldEffect(body: CharacterBody2D):
	OVERWORLD_EFFECT.applyEffect(body)

func equip():
	if !OverworldGlobals.getCurrentMap().has_node('PlayerArrow'):
		PlayerGlobals.EQUIPPED_ARROW = self
