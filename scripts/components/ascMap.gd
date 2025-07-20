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
	removeEmptyEvents()
	await get_tree().process_frame
	done_loading_map = true

func removeEmptyEvents():
	for key in events.keys():
		if (events[key] is Resource and OverworldGlobals.isResourcePlaceholder(events[key])) or events[key] == null:
			events.erase(key)

func getPatrolGroups():
	return get_children().filter(func(child): return child is PatrollerGroup)

func getClearState():
	var total_groups = getPatrolGroups().size()
	var cleared_groups = getPatrolGroups().filter(func(group): return group.isCleared()).size()
	
	if cleared_groups == 0:
		return PatrollerClearState.UNCLEAR
	elif total_groups > cleared_groups:
		return PatrollerClearState.PARTIAL_CLEAR
	elif total_groups == cleared_groups:
		return PatrollerClearState.FULL_CLEAR

func checkGiveClearRewards():
	print(getClearState())
	if getClearState() == PatrollerClearState.FULL_CLEAR and events.has('reward_item'):
		InventoryGlobals.addItemResource(events['reward_item'])
