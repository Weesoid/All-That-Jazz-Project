extends Node2D
class_name MapData

enum PatrollerClearState {
	UNCLEAR,
	PARTIAL_CLEAR,
	FULL_CLEAR
}

@export var map_name: String
@export_multiline var description: String
@export var occupying_faction: CombatGlobals.Enemy_Factions
@export var events: Dictionary = {
	'additional_enemies':null,
	'combat_event':preload("res://_Resource.tres"),
	'patroller_effect': preload("res://_Resource.tres"),
	'bonus_loot':null,
	'bonus_experience':null,
	'reward_item': preload("res://_Resource.tres")
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
	for group in getPatrolGroups():
		group.spawn()
	for save_point in getSavePoints():
		save_point.loadCombatantSquad()

func getLogMapEvent():
	for log in PlayerGlobals.map_logs[scene_file_path]:
		if log is Dictionary and log.has('map_events'): return log

func removeEmptyEvents():
	for key in events.keys():
		if (events[key] is Resource and ResourceGlobals.isResourcePlaceholder(events[key])) or events[key] == null:
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
		0: return '[color=red]Hostiles Active[/color]'
		1: return '[color=orange]Partially Cleared[/color]'
		2: return '[color=green]Fully Cleared[/color]'

func checkGiveClearRewards():
	if getClearState() != PatrollerClearState.FULL_CLEAR:
		return
	
	if events.has('reward_item'):
		InventoryGlobals.addItemResource(events['reward_item'])
	if events.has('bonus_loot'):
		InventoryGlobals.giveItemDict(events['bonus_loot'])
	if events.has('bonus_experience'):
		PlayerGlobals.addExperience(events['bonus_experience'])
	
	PlayerGlobals.randomizeMapEvents(scene_file_path)

func clearPatrollers():
	for group in getPatrolGroups():
		PlayerGlobals.addMapLog(scene_file_path, group.name)

func getSavePoints():
	return  get_children().filter(func(child): return child is SavePoint)
