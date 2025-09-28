extends Control

enum Modes {
	SAVE,
	LOAD,
	DELETE,
	NEW_GAME
}

@onready var panel = $PanelContainer/MarginContainer/VBoxContainer
@onready var container = $PanelContainer

@export var mode: Modes
@export var new_game_map = "res://scenes/maps/Sidescroller.tscn"
var initial_mode

func _ready():
	if get_tree().current_scene.name == 'StartMenu':
		createSaveButtons()
		while panel.get_child_count() != 3:
			createSaveButton('EMPTY')
		#container.get_children().sort_custom(func(a, b): return a.text < b.text)
	else:
		mode = Modes.SAVE
		createSaveButton(PlayerGlobals.save_name)
	OverworldGlobals.setMenuFocus(panel)
	initial_mode = mode

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
		button.text = save.name
	else:
		button.text = 'EMPTY'
	button.pressed.connect(func(): slotPressed(save_name, button))
	button.hold_color=Color.RED
	button.hold_time = 5
	button.focus_entered.connect(
		func():
			if mode == Modes.LOAD:
				button.hold_time = 3.0
			else:
				button.hold_time = -1
	)
	button.hold_started.connect(
		func():
			if mode == Modes.LOAD:
				CombatGlobals.spawnIndicator(button.global_position,'[color=YELLOW]Deleting Save!','Show',null,8.0)
			)
	button.held_press.connect(
		func():
			if mode == Modes.LOAD:
				deleteSave(save_name,button)
			)
	if get_tree().current_scene.name == 'StartMenu':
		button.disabled = (mode == Modes.NEW_GAME and button.text != 'EMPTY') or (mode == Modes.LOAD and button.text == 'EMPTY')
	panel.add_child(button)

func slotPressed(save_name: String, button: Button):
	match mode:
		Modes.SAVE:
			#PlayerGlobals.healCombatants()
			saveGame(save_name, button)
			OverworldGlobals.playSound("542003__rob_marion__gasp_lock-and-load.ogg")
			queue_free()
		Modes.LOAD: 
			PlayerGlobals.save_name = save_name.get_basename()
			SaveLoadGlobals.loadGame(save_name)
		Modes.NEW_GAME:
			PlayerGlobals.save_name = generateSaveName()
			OverworldGlobals.changeMap('res://scenes/maps/Sidescroller.tscn', '0,0,0', 'FastTravel', false, true)
			for combatant in PlayerGlobals.team: combatant.initializeCombatant(false)

func saveGame(save_name: String, button: Button):
	SaveLoadGlobals.saveGame(save_name)
	var save = load("res://saves/%s.tres" % save_name)
	button.text = save.name

func deleteSave(save_name: String, button: Button):
	DirAccess.remove_absolute("res://saves/%s.tres" % save_name)
	button.text = 'EMPTY'
	button.disabled = initial_mode == Modes.LOAD
	mode = initial_mode
	container.self_modulate = Color.WHITE

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
		OverworldGlobals.setPlayerInput(true)
		OverworldGlobals.setMouseController(false)

