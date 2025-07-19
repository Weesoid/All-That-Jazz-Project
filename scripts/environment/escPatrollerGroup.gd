extends Node
class_name PatrollerGroup

@export var enemy_faction: CombatGlobals.Enemy_Factions
@export var max_spawns: int = 4
@export var events: Dictionary
var reward_bank:Dictionary= {'experience':0.0, 'loot':{}}

func _ready():
	OverworldGlobals.patroller_destroyed.connect(checkGiveRewards)
	if !isCleared(): 
		if canSpawnDestructibleObjectives(): spawnDestructibleObjectives()
		spawnPatrollers()

func isCleared():
	return PlayerGlobals.CLEARED_PATROL_GROUPS.has(self) or (PlayerGlobals.CLEARED_PATROL_GROUPS.has(self) and PlayerGlobals.CLEARED_PATROL_GROUPS[self]['cleared'])

func spawnPatrollers():
	randomize()
	for spawn_point in getSpawnPoints():
		if getPatrollers().size() == max_spawns: return
		
		if isChancedSpawn(spawn_point) and !CombatGlobals.randomRoll(float(spawn_point.name.split(' ')[1])*0.01): 
			continue
		var patroller
		if CombatGlobals.randomRoll(0.75):
			patroller = CombatGlobals.generateFactionPatroller(enemy_faction, 0)
		else:
			patroller = CombatGlobals.generateFactionPatroller(enemy_faction, -1)
		
		patroller.global_position = spawn_point.global_position
		CombatGlobals.generateCombatantSquad(patroller, enemy_faction)
		add_child(patroller)

func spawnDestructibleObjectives():
	var spawn_points = getSpawnPoints()
	spawn_points.shuffle()
	for point in spawn_points:
		if getDestructibles().size() == 3: return
		var objective = load("res://scenes/entities_doodads/DestroyObjective.tscn").instantiate()
		objective.patroller_group = self
		objective.global_position = point.global_position
		add_child(objective)

func getSpawnPoints():
	var out = []
	for child in get_children():
		if child is Marker2D and child.name.contains('SpawnPoint') or child.name.contains('Chance'): out.append(child)
	return out

func isChancedSpawn(marker: Node2D):
	return marker.name.to_lower().contains('chance')

func giveRewards(ignore_stalker:bool=false):
	await get_tree().process_frame
	OverworldGlobals.group_cleared.emit()
	if !OverworldGlobals.isPlayerAlive() or (canSpawnDestructibleObjectives() and getDestructibleObjectives().size() > 0): 
		return
	if PlayerGlobals.current_stalker != null and !ignore_stalker and getPatrollers().size() == 0:
		PlayerGlobals.current_stalker.spawn()
		PlayerGlobals.addClearedPatrolGroup(self)
		return
	
	# UI Map clear indicator handling
	var map_clear_indicator = preload("res://scenes/user_interface/MapClearedIndicator.tscn").instantiate()
	map_clear_indicator.added_exp = reward_bank['experience']
	if events.has('reward_item'):
		reward_bank['loot'][events['reward_item']] = 1
	for item in reward_bank['loot'].keys():
		reward_bank['loot'][item] += ceil(reward_bank['loot'][item])#*events['reward_multipliers']['loot'])
	reward_bank['experience'] += ceil(reward_bank['experience'])#*events['reward_multipliers']['experience'])
	OverworldGlobals.getPlayer().player_camera.add_child(map_clear_indicator)
	map_clear_indicator.showAnimation(true, self)
	
	# Actual giving of rewards
	PlayerGlobals.addExperience(reward_bank['experience'])
	for item in reward_bank['loot'].keys():
		if item is ResStackItem:
			InventoryGlobals.addItemResource(item, reward_bank['loot'][item])
		else:
			for i in range(reward_bank['loot'][item]): InventoryGlobals.addItemResource(item)
#	for combatant in reward_bank['tamed']:
#		PlayerGlobals.addCombatantToTeam(combatant)
	PlayerGlobals.addClearedPatrolGroup(self)
	#PlayerGlobals.randomMapUnclear(ceil(0.25*PlayerGlobals.CLEARED_MAPS.size()), scene_file_path)
	SaveLoadGlobals.saveGame(PlayerGlobals.SAVE_NAME)

func escapePatrollers(random_unclear:bool=true, give_rewards:bool=false, remove_destroyables:bool=true):
	if random_unclear:
		PlayerGlobals.randomMapUnclear(ceil(0.25*PlayerGlobals.CLEARED_MAPS.size()), scene_file_path)
	
	if give_rewards:
		for patroller in getPatrollers():
			var combatant_squad = patroller.get_node("CombatantSquadComponent")
			reward_bank['experience'] += combatant_squad.getExperience()
			combatant_squad.addDrops()
	
	if remove_destroyables:
		for destroyable in getDestructibleObjectives():
			destroyable.active = false
			var animation = load("res://scenes/animations_abilities/Reinforcements.tscn").instantiate()
			call_deferred('add_child', animation)
			await animation.ready
			animation.playAnimation(destroyable.global_position)
			destroyable.queue_free()
	
	for patroller in getPatrollers():
		var animation = load("res://scenes/animations_abilities/Reinforcements.tscn").instantiate()
		call_deferred('add_child', animation)
		await animation.ready
		animation.playAnimation(patroller.global_position)
		patroller.destroy(true)
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout

func checkGiveRewards():
	if getPatrollers().size() == 0:
		OverworldGlobals.showPlayerPrompt('Map cleared!')
		giveRewards()

func canSpawnDestructibleObjectives():
	return events.has('destroy_objective') and getSpawnPoints().size() >= 3

func getDestructibleObjectives():
	return get_children().filter(func(child): return child is DestroyableObjective)

func getPatrollers():
	return get_children().filter(func(child): return child is GenericPatroller)

func getDestructibles():
	return get_children().filter(func(child): return child is DestroyableObjective)
