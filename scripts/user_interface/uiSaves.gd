extends Control

enum Modes {
	SAVE,
	LOAD,
	DELETE
}

@onready var panel = $PanelContainer/MarginContainer/VBoxContainer
@onready var dropdown = $OptionButton

@export var mode: Modes

func _ready():
	createSaveButtons()
	
	if OverworldGlobals.getPlayer().has_node('DebugComponent'):
		dropdown.add_item('Save', 0)
		dropdown.add_item('Load', 1)
		dropdown.add_item('Delete', 2)
		dropdown.show()

func createSaveButtons():
	for i in range(3):
		createSaveButton('Save %s' % str(i+1))
	OverworldGlobals.setMenuFocus(panel)

func createSaveButton(save_name: String):
	var button: Button = OverworldGlobals.createCustomButton()
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if ResourceLoader.exists("res://saves/%s.tres" % save_name):
		var save: SavedGame = load("res://saves/%s.tres" % save_name)
		button.text = save.NAME
	else:
		button.text = 'EMPTY'
	
	button.gui_input.connect(func(_input): slotPressed(save_name, button))
	panel.add_child(button)

func slotPressed(save_name: String, button: Button):
	if Input.is_action_just_pressed("ui_alt_accept"):
		deleteSave(save_name, button)
	elif Input.is_action_just_pressed("ui_click") or Input.is_action_just_pressed('ui_accept'):
		match mode:
			Modes.SAVE: saveGame(save_name, button)
			Modes.LOAD: SaveLoadGlobals.loadGame(load("res://saves/%s.tres" % save_name))

func saveGame(save_name: String, button: Button):
	SaveLoadGlobals.saveGame(save_name)
	var save = load("res://saves/%s.tres" % save_name)
	button.text = save.NAME

func deleteSave(save_name: String, button: Button):
	DirAccess.remove_absolute("res://saves/%s.tres" % save_name)
	button.text = 'EMPTY'

func _on_option_button_item_selected(index):
	match index:
		0: mode = Modes.SAVE
		1: mode = Modes.LOAD
		2: mode = Modes.DELETE
