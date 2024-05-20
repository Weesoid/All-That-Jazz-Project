extends Node

var is_loading: bool
signal done_loading

#func _ready():
#	loadGame()

func saveGame():
	var saved_game: SavedGame = SavedGame.new()
	saved_game.current_map_path = OverworldGlobals.getCurrentMap().scene_file_path
	
	var save_data = []
	get_tree().call_group('presist', 'saveData', save_data)
	InventoryGlobals.saveData(save_data)
	QuestGlobals.saveData(save_data)
	PlayerGlobals.saveData(save_data)
	saved_game.save_data = save_data
	
	ResourceSaver.save(saved_game, "res://saves/save.tres")
	OverworldGlobals.showPlayerPrompt('[color=yellow]Game saved[/color]!')

func loadGame():
	is_loading = true
	var saved_game: SavedGame = load('res://saves/save.tres') as SavedGame
	get_tree().change_scene_to_file(saved_game.current_map_path)
	
	await get_tree().create_timer(0.01).timeout
	get_tree().call_group('presist', 'loadData')
	
	QuestGlobals.quest_objective_completed.disconnect(QuestGlobals.checkQuestsForCompleted)
	for item in saved_game.save_data:
		if item is EntitySaveData:
			var scene: Node2D = load(item.scene_path).instantiate()
			scene.global_position = item.position
			OverworldGlobals.getCurrentMap().add_child(scene)
		if item is InventorySaveData:
			InventoryGlobals.loadData(item)
		elif item is QuestSaveData:
			QuestGlobals.loadData(item)
		elif item is PlayerSaveData:
			PlayerGlobals.loadData(item)
	QuestGlobals.quest_objective_completed.connect(QuestGlobals.checkQuestsForCompleted)
	
	OverworldGlobals.showPlayerPrompt('[color=yellow]Game loaded[/color]!')
	done_loading.emit()
	is_loading = false
	#print_orphan_nodes()
