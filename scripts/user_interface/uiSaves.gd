extends Control

enum Modes {
	SAVE,
	LOAD,
	DELETE,
	NEW_GAME
}

@onready var panel = $PanelContainer/MarginContainer/VBoxContainer
@onready var container = $PanelContainer
@onready var delete_label = $Label
@onready var timer = $Timer

@export var mode: Modes
@export var new_game_map = "res://scenes/maps/TestRoom/TestRoomB.tscn"
var initial_mode

func _ready():
	if get_tree().current_scene.name == 'StartMenu':
		createSaveButtons()
		while panel.get_child_count() != 3:
			createSaveButton('EMPTY')
		#container.get_children().sort_custom(func(a, b): return a.text < b.text)
	else:
		mode = Modes.SAVE
		createSaveButton(PlayerGlobals.SAVE_NAME)
	OverworldGlobals.setMenuFocus(panel)
	initial_mode = mode
	if mode != Modes.LOAD:
		delete_label.hide()
#	if mode == Modes.LOAD:
#		createSaveButtons()
#	else:
#		pass
#	if OverworldGlobals.getPlayer().has_node('DebugComponent'):
#		dropdown.add_item('Save', 0)
#		dropdown.add_item('Load', 1)
#		dropdown.add_item('Delete', 2)
#		dropdown.show()

func createSaveButtons():
	var path = "res://saves/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			createSaveButton(file_name.get_basename())
			file_name = dir.get_next()
			#await get_tree().process_frame
	else:
		print("An error occurred when trying to access the path.")
		print(path)
	
	OverworldGlobals.setMenuFocus(panel)

func createSaveButton(save_name: String):
	var button: Button = OverworldGlobals.createCustomButton()
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if ResourceLoader.exists("res://saves/%s.tres" % save_name):
		#await get_tree().process_frame
		var save: SavedGame = load("res://saves/%s.tres" % save_name)
		button.text = save.NAME
	else:
		button.text = 'EMPTY'
	button.pressed.connect(func doAction(): slotPressed(save_name, button))
	if get_tree().current_scene.name == 'StartMenu':
		button.disabled = (mode == Modes.NEW_GAME and button.text != 'EMPTY') or (mode == Modes.LOAD and button.text == 'EMPTY')
	panel.add_child(button)

func slotPressed(save_name: String, button: Button):
	match mode:
		Modes.SAVE:
			PlayerGlobals.healCombatants()
			saveGame(save_name, button)
			OverworldGlobals.playSound("542003__rob_marion__gasp_lock-and-load.ogg")
			queue_free()
		Modes.LOAD: 
			PlayerGlobals.SAVE_NAME = save_name.get_basename()
			SaveLoadGlobals.loadGame(load("res://saves/%s.tres" % save_name))
		Modes.NEW_GAME:
			PlayerGlobals.SAVE_NAME = generateSaveName()
			OverworldGlobals.changeMap(new_game_map, '25.83763,59.06633,0', '', false, true)
			for combatant in PlayerGlobals.TEAM: combatant.initializeCombatant(false)
		Modes.DELETE:
			deleteSave(save_name, button)

func saveGame(save_name: String, button: Button):
	SaveLoadGlobals.saveGame(save_name)
	var save = load("res://saves/%s.tres" % save_name)
	button.text = save.NAME

func deleteSave(save_name: String, button: Button):
	DirAccess.remove_absolute("res://saves/%s.tres" % save_name)
	button.text = 'EMPTY'
	button.disabled = initial_mode == Modes.LOAD
	mode = initial_mode
	container.self_modulate = Color.WHITE
	delete_label.text = 'Hold [SPRINT KEY] to toggle DELETE mode'

func generateSaveName()-> String:
	var path = "res://saves/"
	var dir = DirAccess.open(path)
	var save_names = ['Save 1', 'Save 2', 'Save 3']
	var saves = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			saves.append(file_name.get_basename())
			file_name = dir.get_next()
	
	for save_name in save_names:
		if !saves.has(save_name): 
			return str(save_name)
	
	return 'ERROR'

func _exit_tree():
	if get_tree().current_scene.name != 'StartMenu':
		print('Exit saves setting to true!')
		OverworldGlobals.setPlayerInput(true)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_sprint") and initial_mode == Modes.LOAD:
		timer.start(1.0)
	if Input.is_action_just_released("ui_sprint") and initial_mode == Modes.LOAD:
		timer.stop()

func _on_timer_timeout():
	if mode != Modes.DELETE:
		mode = Modes.DELETE
		container.self_modulate = Color.RED
		delete_label.text = 'Hold [SPRINT KEY] to toggle LOAD mode'
	else:
		mode = initial_mode
		container.self_modulate = Color.WHITE
		delete_label.text = 'Hold [SPRINT KEY] to toggle DELETE mode'
