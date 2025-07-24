extends Resource
class_name ResPower

@export var INPUT_MAP: String = 'xxx'
@export var NAME: String
@export_multiline var DESCRIPTION: String
@export var icon: Texture
@export var POWER_SCRIPT: GDScript
@export var CRYSTAL_COST: int = 0

func setPower():
	PlayerGlobals.power = POWER_SCRIPT
