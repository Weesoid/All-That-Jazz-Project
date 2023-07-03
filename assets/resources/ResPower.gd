extends Resource
class_name ResPower

@export var NAME: String
@export var DESCRIPTION: String
@export var ICON: Texture
@export var POWER_SCRIPT: GDScript

func setPower():
	PlayerGlobals.POWER = POWER_SCRIPT
