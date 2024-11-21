extends Resource
class_name ResPower

@export var INPUT_MAP: String = 'xxx'
@export var NAME: String
@export var DESCRIPTION: String
@export var ICON: Texture
@export var POWER_SCRIPT: GDScript
@export var CRYSTAL_COST: int = 0

func setPower():
	PlayerGlobals.POWER = POWER_SCRIPT
