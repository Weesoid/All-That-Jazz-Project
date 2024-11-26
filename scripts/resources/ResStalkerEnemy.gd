extends Resource
class_name ResStalkerEnemy

@export var patroller: PackedScene
@export var combatant: Array[ResCombatant]
@export var squad_component_properties: Dictionary = {
	"enemy_pool": [],
	"fill_empty": false,
	"random_size": false,
	"unique_id": "",
	"tameable_chance": 0.0,
	"turn_time": 0.0,
	"can_escape": true,
	"do_reinforcements": true,
	"reinforcements_turn": 50,
}
@export var warning_flash: PackedScene
@export var flash_on_camera: bool
@export var spawn_time: float
@export var spawn_script: GDScript

func spawn():
	var spawner: StalkerSpawner = load("res://scenes/miscellaneous/StalkerSpawner.tscn").instantiate()
	spawner.stalker_data = self
	OverworldGlobals.getCurrentMap().add_child(spawner)
	#body.doAnimation('Engage')
