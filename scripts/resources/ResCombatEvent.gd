extends Resource
class_name ResCombatEvent

@export var name: String
@export var warning_message: String
@export var event_message: String
## Multi-target abilities ONLY!
@export var ability: ResAbility
@export var turn_trigger: int
@export var map_overlay: Node2D

func _to_string():
	return name
