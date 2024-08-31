# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var base = $Container
@onready var inventory = $Container/Inventory
@onready var quests = $Container/Quests
@onready var party = $Container/Posse
@onready var save = $Container/Save
@onready var quit = $Quit
@onready var exp_bar = $Container/Experience

@onready var level = $Container/Experience/Level
@onready var currency = $Container/Currency

func _ready():
	OverworldGlobals.setPlayerInput(false)
	exp_bar.value = PlayerGlobals.CURRENT_EXP
	exp_bar.max_value = PlayerGlobals.getRequiredExp()
	level.text = str(PlayerGlobals.PARTY_LEVEL)
	currency.text = 'CHAINS ' + str(PlayerGlobals.CURRENCY)
	base.get_child(0).grab_focus()
	
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		var bar = preload("res://scenes/user_interface/GeneralCombatantStatus.tscn").instantiate()
		$Container/VBoxContainer.add_child(bar)
		bar.combatant = combatant
	
	if QuestGlobals.QUESTS.is_empty():
		quests.hide()
	if !PlayerGlobals.hasActiveTeam():
		party.hide()
		exp_bar.hide()
	if PlayerGlobals.CURRENCY > 0:
		currency.show()
	
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
	get_tree().quit()

func loadUserInterface(path):
	var ui = load(path).instantiate()
	base.modulate.a = 0
	add_child(ui)

func _on_save_pressed():
	SaveLoadGlobals.saveGame()

func disableButtons():
	quit.hide()
	quit.disabled = true
	for child in base.get_children():
		child.hide()
		if child is Button: 
			child.disabled = true

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_show_menu"):
		OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
