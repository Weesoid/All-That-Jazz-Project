extends Node2D
class_name MapData

@export var NAME: String
@export var DESCRIPTION: String
@export var IMAGE: Texture
@export var SAFE: bool = false
var CLEARED: bool = false
var REWARD_BANK: Dictionary = {'currency': 0.0, 'experience':0.0, 'loot':{}}

func _ready():
	if !has_node('Player'): 
		hide()
	if !SAFE:
		clearPatrollers()

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
	PlayerGlobals.addExperience(REWARD_BANK['experience'], true)
	for item in REWARD_BANK['loot'].keys():
		if item is ResStackItem:
			InventoryGlobals.addItemResource(item, REWARD_BANK['loot'][item])
		else:
			for i in range(REWARD_BANK['loot'][item]):
				InventoryGlobals.addItemResource(item)
