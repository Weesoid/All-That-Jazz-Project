extends Resource
class_name ResStalkerData

@export var patroller: ResPatrollerProperties
@export var combatant: Array[ResCombatant]
@export var squad_component_properties: Dictionary = {
	"enemy_pool": [],
	"fill_empty": false,
	"random_size": false,
	"unique_id": "",
	"turn_time": 0.0,
	"can_escape": true,
	"do_reinforcements": true,
	"reinforcements_turn": 50
}
@export var warning_flash: PackedScene
@export var flash_follow: bool
@export var stalker_intro: PackedScene
@export var engage_animation: PackedScene
@export var intro_follow: bool
@export var spawn_time: float
@export var spawn_delay: float = 0.5
@export var conditions: Array[String]

func spawn():
	var spawner: StalkerSpawner = load("res://scenes/environment/StalkerSpawner.tscn").instantiate()
	spawner.stalker_data = self
	OverworldGlobals.getCurrentMap().call_deferred('add_child', spawner)

# Handy later
func canSpawn()-> bool:
	if conditions.is_empty():
		return true
	
	for key in conditions:
		if !PlayerGlobals.PROGRESSION_DATA.has(key):
			return false
		elif !PlayerGlobals.PROGRESSION_DATA[key]:
			return false
	
	return true
