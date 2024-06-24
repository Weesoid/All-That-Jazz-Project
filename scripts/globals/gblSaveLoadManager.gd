extends Node

var default_save_name: String = 'Save'
var is_loading: bool
var session_start: float
var current_playtime: float

signal done_loading
signal done_saving

func _ready():
	session_start = Time.get_unix_time_from_system()

func getTotalPlaytime()-> String:
	return Time.get_time_string_from_unix_time(int(Time.get_unix_time_from_system() - session_start))

func saveGame(save_name: String=default_save_name):
	var saved_game: SavedGame = SavedGame.new()
	saved_game.current_map_path = OverworldGlobals.getCurrentMap().scene_file_path
	
	var save_data = []
	get_tree().call_group('presist', 'saveData', save_data)
	InventoryGlobals.saveData(save_data)
	QuestGlobals.saveData(save_data)
	PlayerGlobals.saveData(save_data)
	saved_game.save_data = save_data
	saved_game.PLAYTIME = current_playtime + (Time.get_unix_time_from_system() - session_start)
	saved_game.NAME = '%s - %s\nMorale %s\n%s' % [save_name, Time.get_time_string_from_unix_time(int(current_playtime) + int(Time.get_unix_time_from_system() - session_start)), PlayerGlobals.PARTY_LEVEL, OverworldGlobals.getCurrentMapData().NAME]
	ResourceSaver.save(saved_game, "res://saves/%s.tres" % save_name)
	OverworldGlobals.showPlayerPrompt('[color=yellow]Game saved[/color]!')
	done_saving.emit()

func loadGame(saved_game: SavedGame):
	is_loading = true
	get_tree().change_scene_to_file(saved_game.current_map_path)
	await get_tree().create_timer(0.01).timeout
	
	get_tree().call_group('presist', 'loadData')
	QuestGlobals.quest_objective_completed.disconnect(QuestGlobals.checkQuestsForCompleted)
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
	QuestGlobals.quest_objective_completed.connect(QuestGlobals.checkQuestsForCompleted)
	
	session_start = Time.get_unix_time_from_system()
	current_playtime = saved_game.PLAYTIME
	OverworldGlobals.showPlayerPrompt('[color=yellow]Game loaded[/color]!')
	done_loading.emit()
	is_loading = false
