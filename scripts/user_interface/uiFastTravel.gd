extends Control

@onready var travel_panel = $ScrollContainer/VBoxContainer
#var map_component_data = {}

func _ready():
	addAllFastTravelPoints()
	loadFastTravelButtons()

func loadFastTravelButtons():
	for location in PlayerGlobals.map_logs.keys():
		if !FileAccess.file_exists(location):
			continue
		
		var button = UIGlobals.createCustomButton()
		button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		#button.text = location.get_file().trim_suffix('.tscn')
		var map_state = load(location).instantiate()#.get('map_name')#.get_sta()#.get_method_list()
#		var root_node_index = 0 
#		for i in map_state.get_node_property_count(root_node_index):
#			var prop_name = map_state.get_node_property_name(root_node_index, i)
#			var prop_value = map_state.get_node_property_value(root_node_index, i)
#
#			if prop_name == "map_name":
		button.text = map_state.map_name
		map_state.free()
		#		break
		#map.queue_free()
		#button.text = map._bundled.variants[map._bundled.names.find('name') - 2] as String
		button.pressed.connect(
			func(): 
				if PlayerGlobals.hasMapEvent(OverworldGlobals.getCurrentMap().scene_file_path):
					checkTravel(location)
				else:
					travel(location)
				)
		button.tooltip_text=str(PlayerGlobals.map_logs[location])
			
		if OverworldGlobals.getCurrentMap().scene_file_path == location:
			button.disabled = true
		travel_panel.add_child(button)

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
	confirm_dialog.no_button.pressed.connect(func():UIGlobals.showMenu("res://scenes/user_interface/ConfirmationDialog.tscn"))

func travel(location):
	if OverworldGlobals.player.camping:
		OverworldGlobals.player.fast_travelling=true
		OverworldGlobals.end_camp.connect(
			func(): 
				#await get_tree().process_frame
			#	OverworldGlobals.getCurrentMap().hide()
				OverworldGlobals.changeMap(location, '0,0,0', ['SavePoint','FastTravel'],false)
				, CONNECT_ONE_SHOT)
		UIGlobals.getMenu().doExitTransition()
	else:
		OverworldGlobals.changeMap(location, '0,0,0', ['SavePoint','FastTravel'])

func _on_debug_button_pressed():
	PlayerGlobals.randomizeMapEvents(OverworldGlobals.getCurrentMap().scene_file_path)
	for child in travel_panel.get_children(): child.queue_free()
	await get_tree().process_frame
	loadFastTravelButtons()

func addAllFastTravelPoints():
	pass
#	var maps = ResourceGlobals.loadArrayFromPath("res://scenes/maps/")
#	for map in maps:
#		if map == null: continue
#		var data = map.instantiate()
#		PlayerGlobals.addMapLog(data.scene_file_path)
#		data.queue_free()
