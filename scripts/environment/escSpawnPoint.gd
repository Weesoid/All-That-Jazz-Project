extends Marker2D
class_name PatrollerSpawnPoint

@export_range(0.0,1.0) var spawn_chance:float=1.0
@export_range(0.0,1.0) var special_chance:float=0.0
@export var faction:CombatGlobals.Enemy_Factions = CombatGlobals.Enemy_Factions.SCAVS
@export var use_map_faction:bool = false

func _ready():
	await get_tree().create_timer(0.1).timeout
	spawn()

func spawn():
	if (spawn_chance < 1.0 and !CombatGlobals.randomRoll(spawn_chance)) or PlayerGlobals.isPatrollerSlain(OverworldGlobals.getCurrentMap().scene_file_path, name): 
		return
	
	var current_map = OverworldGlobals.getCurrentMap()
	var patroller: GenericPatroller
	var patroller_faction = current_map.occupying_faction if (use_map_faction and current_map.occupying_faction != CombatGlobals.Enemy_Factions.UNAFFILIATED) else faction
	var patroller_type = -1 if (special_chance > 0 and CombatGlobals.randomRoll(special_chance)) else 0
	patroller = CombatGlobals.generateFactionPatroller(patroller_faction, patroller_type)
	patroller.spawn_point = self
	patroller.global_position = global_position
	current_map.add_child(patroller)
