extends MarginContainer

@onready var info_label = $VBoxContainer/Label

func _ready():
	info_label.text = '
		%s
		' % [PlayerGlobals.save_name]

func loadUserInterface(path):
	var ui = load(path).instantiate()
	#base.modulate.a = 0
	get_parent().get_parent().add_child(ui)

func _on_settings_pressed():
	loadUserInterface("res://scenes/user_interface/Settings.tscn")


func _on_return_menu_pressed():
	PlayerGlobals.resetVariables(false)
	InventoryGlobals.resetVariables()
	OverworldGlobals.resetVariables()
	QuestGlobals.resetVariables()
	SaveLoadGlobals.resetVariables()
	get_tree().change_scene_to_file("res://scenes/user_interface/StartMenu.tscn")


func _on_exit_game_pressed():
	#SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
	#await get_tree().process_frame
	get_tree().quit()
