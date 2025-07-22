extends Node2D
class_name MapData

enum PatrollerClearState {
	UNCLEAR,
	PARTIAL_CLEAR,
	FULL_CLEAR
}

@export var NAME: String
@export_multiline var DESCRIPTION: String
@export var IMAGE: Texture
@export var occupying_faction: CombatGlobals.Enemy_Factions
@export var events: Dictionary = {
	'combat_event':preload("res://resources/combat/events/_CombatEvent.tres"),
	'additional_enemies':null,
	'patroller_effect': preload("res://_Resource.tres"),
	#'additional_rewards': {'experience':0, 'loot':{}},
	'reward_item': preload("res://resources/items/_Item.tres")
}
var done_loading_map:bool = false

func _ready():
	if SaveLoadGlobals.is_loading:
		await SaveLoadGlobals.done_loading
	if !has_node('Player'): 
		hide()
	if PlayerGlobals.hasMapEvent(scene_file_path):
		events = getLogMapEvent()
	removeEmptyEvents()
	await get_tree().process_frame
	done_loading_map = true

func getLogMapEvent():
	for log in PlayerGlobals.map_logs[scene_file_path]:
		if log is Dictionary and log.has('map_events'): return log

func removeEmptyEvents():
	for key in events.keys():
		if (events[key] is Resource and OverworldGlobals.isResourcePlaceholder(events[key])) or events[key] == null:
			events.erase(key)

func getPatrolGroups():
	return get_children().filter(func(child): return child is PatrollerGroup)

func getClearState():
	var total_groups = getPatrolGroups().size()
	var cleared_groups = getPatrolGroups().filter(func(group): return group.isCleared()).size()
	
	if cleared_groups == 0 and total_groups > 0:
		return PatrollerClearState.UNCLEAR
	elif total_groups > cleared_groups and total_groups > 0:
		return PatrollerClearState.PARTIAL_CLEAR
	elif total_groups == cleared_groups or total_groups == 0:
		return PatrollerClearState.FULL_CLEAR

func getVerbalClearState():
	if getPatrolGroups().size() == 0:
		return '[color=green]Safe[/color]'
	
	match getClearState():
		0: return '[color=red]Unsafe[/color]'
		1: return '[color=orange]Partially Cleared[/color]'
		2: return '[color=green]Fully Cleared[/color]'

func checkGiveClearRewards():
	if getClearState() != PatrollerClearState.FULL_CLEAR:
		return
	
	if events.has('reward_item'):
		InventoryGlobals.addItemResource(events['reward_item'])
	PlayerGlobals.randomizeMapEvents(scene_file_path)

func clearPatrollers():
	for group in getPatrolGroups():
		PlayerGlobals.addMapLog(scene_file_path, group.name)
