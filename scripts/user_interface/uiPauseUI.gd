extends Control

@onready var base = $Container
@onready var inventory = $Container/Inventory
@onready var quests = $Container/Quests
@onready var party = $Container/Posse
@onready var save = $Container/Save
@onready var quit = $Quit
@onready var experience = $Container/HSplitContainer
@onready var exp_bar = $Container/HSplitContainer/Experience
@onready var exp_bar_vals = $Container/HSplitContainer/Experience/Label
@onready var morale_label = $Container/HSplitContainer/Label
@onready var level = $Container/HSplitContainer/Experience/Level
@onready var currency = $Container/Currency

func _ready():
	OverworldGlobals.setPlayerInput(false)
	exp_bar.max_value = PlayerGlobals.getRequiredExp()
	exp_bar.value = PlayerGlobals.CURRENT_EXP
	exp_bar_vals.text = '%s / %s' % [PlayerGlobals.CURRENT_EXP, PlayerGlobals.getRequiredExp()]
	level.text = str(PlayerGlobals.PARTY_LEVEL)
	if PlayerGlobals.PARTY_LEVEL == PlayerGlobals.MAX_PARTY_LEVEL:
		morale_label.text = 'Max'
	currency.text =  '     '+str(PlayerGlobals.addCommaToNum())
	base.get_child(0).grab_focus()
	
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		var bar = preload("res://scenes/user_interface/GeneralCombatantStatus.tscn").instantiate()
		$Container/VBoxContainer.add_child(bar)
		bar.combatant = combatant
	
	if QuestGlobals.QUESTS.is_empty():
		quests.hide()
	if !PlayerGlobals.hasActiveTeam():
		party.hide()
		experience.hide()
	if PlayerGlobals.CURRENCY > 0:
		currency.show()
	# TO DO: ...Need some sort of flag to determine whether or not player is interacting with combatant group...!
#	if !OverworldGlobals.getCurrentMap().SAFE and OverworldGlobals.getCurrentMap().arePatrollersAlerted() and !PlayerGlobals.CLEARED_MAPS.keys().has(OverworldGlobals.getCurrentMap().scene_file_path):
#		party.disabled = true

func _on_tree_exited():
	queue_free()

func _on_inventory_pressed():
	disableButtons()
	loadUserInterface("res://scenes/user_interface/Inventory.tscn")

func _on_posse_pressed():
	disableButtons()
	loadUserInterface("res://scenes/user_interface/CharacterAdjust.tscn")

func _on_quests_pressed():
	disableButtons()
	loadUserInterface("res://scenes/user_interface/Quest.tscn")

func _on_quit_pressed():
	#confirm_dialog.connectYes(leaveToMain)
#	confirm_dialog.dialog.confirmed.connect(leaveToMain)
#	confirm_dialog.dialog.get_cancel_button().pressed.connect(queue_free)
#	confirm_dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
#	confirm_dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
#	confirm_dialog.initial_position =Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	#await confirm_dialog.dialog.confirmed
	if PlayerGlobals.isMapCleared(): 
		SaveLoadGlobals.saveGame(PlayerGlobals.SAVE_NAME)
		leaveToMain()
	else:
		disableButtons()
		var confirm_dialog = load("res://scenes/user_interface/ConfirmationDialog.tscn").instantiate()
		add_child(confirm_dialog)
		confirm_dialog.text.text = 'Area is not safe. Progress will not be saved.'
		confirm_dialog.yes_button.text = 'Quit'
		confirm_dialog.no_button.text = 'Return'
		confirm_dialog.yes_button.pressed.connect(leaveToMain)
		confirm_dialog.no_button.pressed.connect(func():OverworldGlobals.showMenu("res://scenes/user_interface/ConfirmationDialog.tscn"))

func leaveToMain():
	get_tree().change_scene_to_file("res://scenes/user_interface/StartMenu.tscn")

func loadUserInterface(path):
	var ui = load(path).instantiate()
	base.modulate.a = 0
	add_child(ui)

func _on_save_pressed():
	SaveLoadGlobals.saveGame(PlayerGlobals.SAVE_NAME)

func disableButtons():
	quit.hide()
	quit.disabled = true
	for child in base.get_children():
		child.hide()
		if child is Button: child.disabled = true

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_show_menu"):
		OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
