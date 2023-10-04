extends Resource
class_name ResUtilityCharm

@export var NAME: String
@export var DESCRIPTION: String
@export var CHARM_SCRIPT: GDScript
@export var ICON: Texture

func equip():
	CHARM_SCRIPT.equip()

func unequip():
	CHARM_SCRIPT.unequip()
