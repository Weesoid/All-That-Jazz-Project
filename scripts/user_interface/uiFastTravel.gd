extends Control

@onready var travel_panel = $FastTravelAreas/MarginContainer/ScrollContainer/VBoxContainer
@onready var description = $PanelContainer2/RichTextLabel
@onready var event_description = $PanelContainer3/RichTextLabel
var map_component_data = {}

func _ready():
	#print(PlayerGlobals.map_logs)
	addAllFastTravelPoints()
	#PlayerGlobals.addFastTravelArea(OverworldGlobals.getCurrentMap().scene_file_path, OverworldGlobals.getCurrentMap().getPatrollers().size()<=0)
	loadFastTravelButtons()

func loadFastTravelButtons():
	for location in PlayerGlobals.map_logs.keys():
		var button = OverworldGlobals.createCustomButton()
		var map:MapData = load(location).instantiate()
		button.text = map.NAME
		#map_component_data[location] = [map.NAME, map.DESCRIPTION, map.IMAGE, map.EVENTS]
		button.pressed.connect(func(): travel(location))
		button.focus_entered.connect(
			func():
				getMapInfo(location)
		)
		button.mouse_entered.connect(
			func():
				getMapInfo(location)
		)
		button.tooltip_text=str(PlayerGlobals.map_logs[location])
		if map.getClearState() != MapData.PatrollerClearState.FULL_CLEAR and PlayerGlobals.hasMapEvent(location):
			button.icon = preload("res://images/sprites/icon_patrol_spawned.png")
		elif map.getClearState() != MapData.PatrollerClearState.FULL_CLEAR:
			button.icon = preload("res://images/sprites/icon_patrol_uncleared.png")
			
		if OverworldGlobals.getCurrentMap().scene_file_path == location:
			button.disabled = true
#		if location == OverworldGlobals.getCurrentMap().scene_file_path or !PlayerGlobals.CLEARED_MAPS[location]['fast_travel']:
#			button.disabled = true
#		if !PlayerGlobals.CLEARED_MAPS[location]['cleared']:
#			button.icon = preload("res://images/sprites/icon_multi_enemy.png")
		travel_panel.add_child(button)
		map.queue_free()
	
	OverworldGlobals.setMenuFocus(travel_panel)

func getMapInfo(path):
	var map: MapData = load(path).instantiate()
	var map_log = PlayerGlobals.map_logs[map.scene_file_path]
	var total_patrols = map.getPatrolGroups().size()
	var cleared_patrols = map_log.filter(func(log): return log is String and log.contains('PatrollerGroup')).size()
	getMapEventInfo(map_log)
	description.text = 'Status: %s' % map.getVerbalClearState()
	if total_patrols > 0 or cleared_patrols != total_patrols: 
		if cleared_patrols > 0:
			description.text += ' (%s/%s)' % [str(cleared_patrols),total_patrols]
		description.text += '\nFaction: '+str(CombatGlobals.Enemy_Factions.keys()[map.occupying_faction])
	
	map.queue_free()

func getMapEventInfo(map_log: Array):
	event_description.hide()
	
	for log in map_log:
		if log is Dictionary and log.has('map_events'):
			event_description.text = str(log)
			event_description.show()
			return

func travel(location):
	OverworldGlobals.closeMenu(self)
	OverworldGlobals.changeMap(location, '0,0,0', 'FastTravel')

func _on_debug_button_pressed():
	PlayerGlobals.randomizeMapEvents(OverworldGlobals.getCurrentMap().scene_file_path)
	for child in travel_panel.get_children(): child.queue_free()
	await get_tree().process_frame
	loadFastTravelButtons()

func addAllFastTravelPoints():
	var maps = OverworldGlobals.loadArrayFromPath("res://scenes/maps/")
	for map in maps:
		if map == null: continue
		var data = map.instantiate()
		PlayerGlobals.addMapLog(data.scene_file_path)
		data.queue_free()
