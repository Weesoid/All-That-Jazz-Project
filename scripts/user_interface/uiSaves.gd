extends Control

enum Modes {
	OVERWRITE,
	LOAD,
	DELETE
}

@onready var panel = $PanelContainer/MarginContainer/VBoxContainer
@onready var preview = $PanelContainer2/TextureRect

@export var mode: Modes

func _ready():
	createSaveButtons()

func createSaveButtons():
	for i in range(4):
		createSaveButton('Save %s' % i)
	OverworldGlobals.setMenuFocus(panel)

func createSaveButton(save_name: String):
	var button: Button = OverworldGlobals.createCustomButton()
	if ResourceLoader.exists("res://saves/%s.tres" % save_name):
		var save: SavedGame = load("res://saves/%s.tres" % save_name)
		button.text = save.NAME
#		button.focus_entered.connect(func(): preview.texture = save.IMG_PREVIEW)
#		button.mouse_entered.connect(func(): preview.texture = save.IMG_PREVIEW)
	else:
		button.text = 'EMPTY %s' % save_name
	match mode:
		Modes.OVERWRITE: button.pressed.connect(func(): saveGame(save_name, button))
		Modes.LOAD: button.pressed.connect(func(): SaveLoadGlobals.loadGame(load("res://saves/%s.tres" % save_name)))
		Modes.DELETE: button.pressed.connect(func(): deleteSave(save_name))
	panel.add_child(button)

func saveGame(save_name: String, button: Button):
	SaveLoadGlobals.saveGame(save_name)
	var save = load("res://saves/%s.tres" % save_name)
	button.text = save.NAME
	#preview.texture = save.IMG_PREVIEW

func deleteSave(save_name: String):
	DirAccess.remove_absolute("res://saves/%s.tres" % save_name)
	for child in panel.get_children():
		remove_child(child)
		child.queue_free()
	createSaveButtons()
