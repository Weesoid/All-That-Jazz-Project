extends Node2D
class_name ChancedSpawner

@export var spawn_entity: PackedScene
@export var chance_to_spawn: float = 0.0

func _ready():
	randomize()
	if CombatGlobals.randomRoll(chance_to_spawn):
		var spawned_entity = spawn_entity.instantiate()
		spawned_entity.global_position = global_position
		OverworldGlobals.getCurrentMap().call_deferred('add_child', spawned_entity)
	else:
		queue_free()
