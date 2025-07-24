extends Node

var is_loading: bool
var session_start: float
var current_playtime: float

signal done_loading
signal done_saving

func getTotalPlaytime()-> String:
	return Time.get_time_string_from_unix_time(int(Time.get_unix_time_from_system() - session_start))

func saveGame(save_name: String, save_current_map:bool=true):
	var saved_game: SavedGame = SavedGame.new()
	var save_data = []
	
	if save_current_map:
		saved_game.current_map_path = OverworldGlobals.getCurrentMap().scene_file_path
		get_tree().call_group('presist', 'saveData', save_data)
	else:
		var existing_game = load("res://saves/%s.tres"%save_name)
		saved_game.current_map_path = existing_game.current_map_path
		for data in existing_game.save_data:
			if data is EntitySaveData and data.scene_path == "res://scenes/entities/Player.tscn": save_data.append(data)
	QuestGlobals.saveData(save_data)
	PlayerGlobals.saveData(save_data)
	InventoryGlobals.saveData(save_data)
	saved_game.save_data = save_data
	saved_game.playtime = current_playtime + (Time.get_unix_time_from_system() - session_start)
	saved_game.NAME = '%s - %s\nMorale %s\n%s' % [save_name, Time.get_time_string_from_unix_time(int(current_playtime) + int(Time.get_unix_time_from_system() - session_start)), PlayerGlobals.team_level, OverworldGlobals.getCurrentMap().NAME]
	ResourceSaver.save(saved_game, "res://saves/%s.tres" % save_name)
	OverworldGlobals.showPrompt('[color=yellow]Game saved[/color]!')
	done_saving.emit()

func loadGame(saved_game: SavedGame):
	is_loading = true
	get_tree().change_scene_to_file(saved_game.current_map_path)
	await get_tree().create_timer(0.01).timeout
	get_tree().call_group('presist', 'loadData')
	await get_tree().process_frame
	
	for item in saved_game.save_data:
		if item is EntitySaveData:
			var scene: Node2D = load(item.scene_path).instantiate()
			scene.global_position = item.position
			if scene is PlayerScene:
				match item.direction:
					0: scene.direction = Vector2(0,1) # Down
					179: scene.direction = Vector2(0,-1) # Up
					-90: scene.direction = Vector2(1, 0) # Right
					90: scene.direction = Vector2(-1,0) # Left
			OverworldGlobals.getCurrentMap().add_child(scene)
		if item is InventorySaveData:
			InventoryGlobals.loadData(item)
		elif item is QuestSaveData:
			QuestGlobals.loadData(item)
		elif item is PlayerSaveData:
			PlayerGlobals.loadData(item)
	
	session_start = Time.get_unix_time_from_system()
	current_playtime = saved_game.playtime
	OverworldGlobals.showPrompt('[color=yellow]Game loaded[/color]!')
	done_loading.emit()
	is_loading = false
	OverworldGlobals.getCurrentMap().show()

func loadSaveFile(save_name: String = PlayerGlobals.save_name):
	return load("res://saves/%s.tres" % save_name)



func resetVariables():
	is_loading = false
	current_playtime = 0
