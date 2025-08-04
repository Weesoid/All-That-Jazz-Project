extends Resource
class_name ResPower

@export var input_map: String = 'xxx'
@export var name: String
@export_multiline var description: String
@export var icon: Texture
@export var power_script: GDScript
@export var crystal_cost: int = 0

func setPower():
	PlayerGlobals.power = power_script

func _to_string():
	return name+': '+input_map
