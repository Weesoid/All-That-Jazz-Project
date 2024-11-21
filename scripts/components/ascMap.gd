extends Node2D
class_name MapData

@export var NAME: String
@export var DESCRIPTION: String
@export var IMAGE: Texture
@export var SAFE: bool = false
@export var ENEMY_FACTION: CombatGlobals.Enemy_Factions

var CLEARED: bool = false
var INITIAL_PATROLLER_COUNT: int = 0
var REWARD_BANK: Dictionary = {'currency': 0.0, 'experience':0.0, 'loot':{}, 'tamed':[]}
var full_alert: bool = false

func _ready():
	if SaveLoadGlobals.is_loading:
		await SaveLoadGlobals.done_loading
	if !has_node('Player'): 
		hide()
	if !SAFE and (!PlayerGlobals.CLEARED_MAPS.keys().has(scene_file_path) or !PlayerGlobals.CLEARED_MAPS[scene_file_path]['cleared']):
		await get_tree().process_frame
		if PlayerGlobals.CLEARED_MAPS.keys().has(scene_file_path):
			ENEMY_FACTION = PlayerGlobals.CLEARED_MAPS[scene_file_path]['faction']
		spawnPatrollers()
		INITIAL_PATROLLER_COUNT = getPatrollers().size()
		showStartIndicator()
		setSavePoints(false)
		#get_node('FastTravel').hide()

func giveRewards():
	if !OverworldGlobals.isPlayerAlive(): return
	
	var map_clear_indicator = preload("res://scenes/user_interface/MapClearedIndicator.tscn").instantiate()
	map_clear_indicator.added_exp = REWARD_BANK['experience']
	OverworldGlobals.getPlayer().player_camera.add_child(map_clear_indicator)
	map_clear_indicator.showAnimation(true)
	
	PlayerGlobals.CURRENCY += REWARD_BANK['currency']
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
	PlayerGlobals.randomMapUnclear(1, scene_file_path)
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
						patroller = CombatGlobals.generateFactionPatroller(ENEMY_FACTION, randi_range(1,1)) # Only 1 special enemy type so far.
						special_count -= 1
					elif isChancedSpawn(marker):
						patroller = CombatGlobals.generateFactionPatroller(ENEMY_FACTION, randi_range(0,1)) # Only 1 special enemy type so far.
					else:
						patroller = CombatGlobals.generateFactionPatroller(ENEMY_FACTION, 0) 
					patroller.global_position = marker.global_position
					patroller.patrol_area = area
					CombatGlobals.generateCombatantSquad(patroller, ENEMY_FACTION)
					add_child(patroller)

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

func getPatrollers():
	var out = []
	for child in get_children():
		if child is GenericPatroller: out.append(child)
	return out

func arePatrollersAlerted():
	for patroller in getPatrollers():
		if patroller.get_node('NPCPatrolComponent').STATE > 0: return true
	
	return false

func arePatrollersHalved():
	return getPatrollers().size() <= floor(INITIAL_PATROLLER_COUNT / 2.0)
