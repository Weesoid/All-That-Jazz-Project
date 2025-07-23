extends Control

@onready var travel_panel = $FastTravelAreas/MarginContainer/ScrollContainer/VBoxContainer
@onready var description = $PanelContainer2/RichTextLabel
@onready var event_description = $PanelContainer3/RichTextLabel
var map_component_data = {}

func _ready():
	addAllFastTravelPoints()
	loadFastTravelButtons()

func loadFastTravelButtons():
	for location in PlayerGlobals.map_logs.keys():
		var button = OverworldGlobals.createCustomButton()
		var map:MapData = load(location).instantiate()
		button.text = map.NAME
		button.pressed.connect(
			func(): 
				if PlayerGlobals.hasMapEvent(OverworldGlobals.getCurrentMap().scene_file_path):
					checkTravel(location)
				else:
					travel(location)
				)
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

func checkTravel(location):
	var confirm_dialog: CustomConfirmationDialogue = load("res://scenes/user_interface/ConfirmationDialog.tscn").instantiate()
	add_child(confirm_dialog)
	confirm_dialog.text.text = 'Leaving the area will forfeit clear rewards. Are you sure?'
	confirm_dialog.yes_button.text = 'Leave'
	confirm_dialog.no_button.text = 'Return'
	confirm_dialog.yes_button.pressed.connect(
		func():
			PlayerGlobals.randomizeMapEvents(location)
			travel(location)
			)
	confirm_dialog.no_button.pressed.connect(func():OverworldGlobals.showMenu("res://scenes/user_interface/ConfirmationDialog.tscn"))

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
