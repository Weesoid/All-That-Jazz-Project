extends Node2D
class_name MapData

@export var NAME: String
@export var DESCRIPTION: String
@export var IMAGE: Texture
@export var SAFE: bool = false
@export var ENEMY_FACTION: CombatGlobals.Enemy_Factions
@export var EVENTS: Dictionary = {
	'combat_event':null,
	'additional_enemies':null,
	'tameable_modifier':0.0,
	'time_limit':0.0,
	'reward_multipliers': {'experience':0.0, 'loot':0.0},
	'patroller_effect': null,
	'reward_item': null,
	'stalker_chance': 0.05 * PlayerGlobals.PARTY_LEVEL,
	'destroy_objective': false
	}
var CLEARED: bool = false
var INITIAL_PATROLLER_COUNT: int = 0
var REWARD_BANK: Dictionary = {'experience':0.0, 'loot':{}, 'tamed':[]}
var STALKER: ResStalkerData
var full_alert: bool = false
var clear_timer: Timer
var give_on_exit:bool = false
var done_loading_map:bool = false

signal map_cleared

func _ready():
	if SaveLoadGlobals.is_loading:
		await SaveLoadGlobals.done_loading
	if !has_node('Player'): 
		hide()
	if PlayerGlobals.CLEARED_MAPS.keys().has(scene_file_path) and !PlayerGlobals.CLEARED_MAPS[scene_file_path]['events'].is_empty():
		var events: Dictionary = PlayerGlobals.CLEARED_MAPS[scene_file_path]['events']
		for key in events.keys():
			if events[key] != null: 
				EVENTS[key] = events[key]
	if !SAFE and (!PlayerGlobals.CLEARED_MAPS.keys().has(scene_file_path) or !PlayerGlobals.CLEARED_MAPS[scene_file_path]['cleared']):
		await get_tree().process_frame
		if PlayerGlobals.CLEARED_MAPS.keys().has(scene_file_path):
			ENEMY_FACTION = PlayerGlobals.CLEARED_MAPS[scene_file_path]['faction']
		#await get_tree().create_timer(0.05).tim
		spawnPatrollers()
		INITIAL_PATROLLER_COUNT = getPatrollers().size()
		showStartIndicator()
		setSavePoints(false)
		if EVENTS['time_limit'] > 0.0:
			clear_timer = Timer.new()
			add_child(clear_timer)
			clear_timer.timeout.connect(escapePatrollers)
			clear_timer.start(EVENTS['time_limit'])
			OverworldGlobals.getPlayer().player_camera.add_child(load("res://scenes/user_interface/TimeLimit.tscn").instantiate())
		if canSpawnDestructibleObjectives():
			spawnDestructibleObjectives()
		if CombatGlobals.randomRoll(EVENTS['stalker_chance']):
			pickStalker()
	
	await get_tree().process_frame
	done_loading_map = true

func giveRewards(ignore_stalker:bool=false):
	await get_tree().process_frame
	map_cleared.emit()
	if clear_timer != null and !clear_timer.is_stopped(): 
		clear_timer.stop()
	if !OverworldGlobals.isPlayerAlive() or (canSpawnDestructibleObjectives() and getDestructibleObjectives().size() > 0): 
		return
	if STALKER != null and !ignore_stalker:
		STALKER.spawn()
		give_on_exit = true
		PlayerGlobals.addToClearedMaps(scene_file_path, true, has_node('FastTravel'))
		PlayerGlobals.clearMaps()
		return
	
	var map_clear_indicator = preload("res://scenes/user_interface/MapClearedIndicator.tscn").instantiate()
	map_clear_indicator.added_exp = REWARD_BANK['experience']
	if EVENTS['reward_item'] != null:
		REWARD_BANK['loot'][EVENTS['reward_item']] = 1
	for item in REWARD_BANK['loot'].keys():
		REWARD_BANK['loot'][item] += ceil(REWARD_BANK['loot'][item]*EVENTS['reward_multipliers']['loot'])
	REWARD_BANK['experience'] += ceil(REWARD_BANK['experience']*EVENTS['reward_multipliers']['experience'])
	OverworldGlobals.getPlayer().player_camera.add_child(map_clear_indicator)
	map_clear_indicator.showAnimation(true)
	
	PlayerGlobals.addExperience(REWARD_BANK['experience'])
	for item in REWARD_BANK['loot'].keys():
		if item is ResStackItem:
			InventoryGlobals.addItemResource(item, REWARD_BANK['loot'][item])
		else:
			for i in range(REWARD_BANK['loot'][item]):
				InventoryGlobals.addItemResource(item)
	for combatant in REWARD_BANK['tamed']:
		PlayerGlobals.addCombatantToTeam(combatant)
	PlayerGlobals.addToClearedMaps(scene_file_path, true, has_node('FastTravel'))
	PlayerGlobals.randomMapUnclear(ceil(0.25*PlayerGlobals.CLEARED_MAPS.size()), scene_file_path)
	setSavePoints(true)
	SaveLoadGlobals.saveGame(PlayerGlobals.SAVE_NAME)

func setSavePoints(set_to:bool):
	get_node('SavePoint').visible = set_to
	get_node('SavePoint').set_collision_layer_value(1, set_to)
	get_node('SavePoint').set_collision_mask_value(1, set_to)
	get_node('SavePoint').get_node('InteractComponent').monitoring = set_to
	get_node('SavePoint').get_node('InteractComponent').monitorable = set_to

func spawnPatrollers():
	randomize()
	var valid_specials = CombatGlobals.FACTION_PATROLLER_PROPERTIES[ENEMY_FACTION].getValidTypes(true)
	
	for area in get_children():
		if area is Area2D and area.has_node('SpawnPoints'):
			var special_count = ceil(countSpawnPoints(area)*0.25)
			var shuffled_area = area.get_children()
			shuffled_area.shuffle()
			for marker in shuffled_area:
				if marker is Marker2D:
					if isChancedSpawn(marker) and !CombatGlobals.randomRoll(float(marker.name.split(' ')[1])*0.01): continue
					var patroller
					if special_count != 0:
						patroller = CombatGlobals.generateFactionPatroller(ENEMY_FACTION, valid_specials.pick_random())
						special_count -= 1
					elif isChancedSpawn(marker):
						patroller = CombatGlobals.generateFactionPatroller(ENEMY_FACTION, valid_specials.pick_random())
					else:
						patroller = CombatGlobals.generateFactionPatroller(ENEMY_FACTION, 0) 
					patroller.global_position = marker.global_position
					patroller.patrol_area = area
					CombatGlobals.generateCombatantSquad(patroller, ENEMY_FACTION)
					add_child(patroller)

func spawnDestructibleObjectives():
	var spawn_count = 0
	var areas = getPatrolAreas()
	areas.shuffle()
	for area in areas:
		var objective = load("res://scenes/entities_doodads/DestroyObjective.tscn").instantiate()
		objective.global_position = area.get_children().pick_random().global_position
		add_child(objective)
		spawn_count += 1

func showStartIndicator():
	var map_clear_indicator = preload("res://scenes/user_interface/MapClearedIndicator.tscn").instantiate()
	OverworldGlobals.getPlayer().player_camera.add_child(map_clear_indicator)
	map_clear_indicator.showAnimation(false)

func countSpawnPoints(area):
	var out = 0
	for child in area.get_children():
		if child is Marker2D and !isChancedSpawn(child): out += 1
	return out

func isChancedSpawn(marker: Node2D):
	return marker.name.to_lower().contains('chance')

func getPatrolAreas():
	var out = []
	for child in get_children():
		if child is Area2D and child.has_node('SpawnPoints'): out.append(child)
	return out

func canSpawnDestructibleObjectives():
	return EVENTS['destroy_objective'] and getPatrolAreas().size() >= 3

func getDestructibleObjectives():
	var out = []
	for child in get_children():
		if child is DestroyableObjective: out.append(child)
	return out

func getPatrollers():
	var out = []
	for child in get_children():
		if child is GenericPatroller and child.has_node('NPCPatrolComponent'): out.append(child)
	return out

func arePatrollersAlerted():
	for patroller in getPatrollers():
		if patroller.get_node('NPCPatrolComponent').STATE > 0: return true
	
	return false

func arePatrollersHalved():
	return getPatrollers().size() <= floor(INITIAL_PATROLLER_COUNT / 2.0)

func escapePatrollers(random_unclear:bool=true, give_rewards:bool=false, remove_destroyables:bool=true):
	if random_unclear:
		PlayerGlobals.randomMapUnclear(ceil(0.25*PlayerGlobals.CLEARED_MAPS.size()), scene_file_path)
	if give_rewards:
		for patroller in getPatrollers():
			REWARD_BANK['experience'] += patroller.get_node("NPCPatrolComponent").COMBAT_SQUAD.getExperience()
			patroller.get_node("NPCPatrolComponent").COMBAT_SQUAD.addDrops()
	if remove_destroyables:
		for destroyable in getDestructibleObjectives():
			destroyable.active = false
			var animation = load("res://scenes/animations/Reinforcements.tscn").instantiate()
			call_deferred('add_child', animation)
			await animation.ready
			animation.playAnimation(destroyable.global_position)
			destroyable.queue_free()
	for patroller in getPatrollers():
		var animation = load("res://scenes/animations/Reinforcements.tscn").instantiate()
		call_deferred('add_child', animation)
		await animation.ready
		animation.playAnimation(patroller.global_position)
		patroller.get_node('NPCPatrolComponent').destroy(false)
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout

func pickStalker():
	randomize()
	var valid_stalkers = []
	for stalker in OverworldGlobals.loadArrayFromPath("res://resources/combat/stalkers/", func(stalker): return stalker.canSpawn()):
		valid_stalkers.append(stalker)
	STALKER = valid_stalkers.pick_random()
