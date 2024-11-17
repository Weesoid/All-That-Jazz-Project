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
	if !has_node('Player'): 
		hide()
	if !SAFE:
		clearPatrollers()
		INITIAL_PATROLLER_COUNT = getPatrollers().size()

func clearPatrollers():
	if SaveLoadGlobals.is_loading:
		await SaveLoadGlobals.done_loading
	if PlayerGlobals.CLEARED_MAPS.has(NAME):
		for child in OverworldGlobals.getCurrentMap().get_children():
			if child.has_node('NPCPatrolComponent'): child.queue_free()
	
	await get_tree().process_frame
	if !PlayerGlobals.isMapCleared():
		var map_clear_indicator = preload("res://scenes/user_interface/MapClearedIndicator.tscn").instantiate()
		OverworldGlobals.getPlayer().player_camera.add_child(map_clear_indicator)

func giveRewards():
	var map_clear_indicator = preload("res://scenes/user_interface/MapClearedIndicator.tscn").instantiate()
	map_clear_indicator.added_exp = REWARD_BANK['experience']
	OverworldGlobals.getPlayer().player_camera.add_child(map_clear_indicator)
	
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

func spawnPatrollers():
	pass

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
	return getPatrollers().size() <= ceil(INITIAL_PATROLLER_COUNT / 2)
