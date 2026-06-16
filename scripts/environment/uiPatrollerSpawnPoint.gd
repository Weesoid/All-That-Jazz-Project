extends Marker2D

@export_range(0.0,1.0) var spawn_chance:float=1.0
@export var faction: ResFaction
#@export_
# Called when the node enters the scene tree for the first time.
func _ready():
	#await get_tree().create_timer(1.5).timeout
	#print('ragatha')
	await get_tree().process_frame
	spawn()


func spawn():
	#if getPatrollers().size() == max_spawns : return
	print('spawning!!!!!!!')
	if spawn_chance < 1.0 and !CombatGlobals.randomRoll(spawn_chance): 
		return
	var patroller: GenericPatroller
	var faction
#	if CombatGlobals.randomRoll(special_chance):
#		patroller = CombatGlobals.generateFactionPatroller(enemy_faction, -1)
#	else:
	print(OverworldGlobals.getCurrentMap().occupying_faction)
	patroller = CombatGlobals.generateFactionPatroller(OverworldGlobals.getCurrentMap().occupying_faction, 0)
	
	patroller.global_position = global_position
	#CombatGlobals.generateCombatantSquad(patroller, enemy_faction)
	OverworldGlobals.getCurrentMap().add_child(patroller)
	print('spooned')
