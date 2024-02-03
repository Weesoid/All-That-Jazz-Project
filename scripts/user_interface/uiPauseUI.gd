# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var base = $Container
@onready var inventory = $Container/Inventory
@onready var quests = $Container/Quests
@onready var party = $Container/Posse
@onready var save = $Container/Save
@onready var quit = $Container/Quit
@onready var exp_bar = $Container/Experience

@onready var level = $Container/Level
@onready var currency = $Container/Currency

func _ready():
	OverworldGlobals.setPlayerInput(false)
	exp_bar.value = PlayerGlobals.CURRENT_EXP
	exp_bar.max_value = PlayerGlobals.getRequiredExp()
	level.text = 'POSSE LEVEL ' + str(PlayerGlobals.PARTY_LEVEL)
	currency.text = 'CHAINS ' + str(PlayerGlobals.CURRENCY)

func _on_tree_exited():
	#OverworldGlobals.setPlayerInput(true)
	queue_free()

func _on_inventory_pressed():
	disableButtons()
	loadUserInterface("res://scenes/user_interface/Inventory.tscn")

func _on_posse_pressed():
	disableButtons()
	loadUserInterface("res://scenes/user_interface/PartyMembers.tscn")

func _on_quests_pressed():
	disableButtons()
	loadUserInterface("res://scenes/user_interface/Quest.tscn")

func _on_quit_pressed():
	get_tree().quit()

func loadUserInterface(path):
	var ui = load(path).instantiate()
	base.modulate.a = 0
	add_child(ui)

func _on_save_pressed():
	SaveLoadGlobals.saveGame()

func disableButtons():
	for child in base.get_children():
		if child is Button: child.disabled = true

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
	if Input.is_action_just_pressed("ui_bow"):
		queue_free()
		SaveLoadGlobals.loadGame()

