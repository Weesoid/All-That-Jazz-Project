# TO-DO: GENERAL QUALITY CONTROL
extends Control

@onready var base = $Container
@onready var inventory = $Container/Inventory
@onready var quests = $Container/Quests
@onready var party = $Container/Posse
@onready var save = $Container/Save
@onready var quit = $Container/Quit


func _ready():
	OverworldGlobals.player_can_move = false

func _on_tree_exited():
	OverworldGlobals.player_can_move = true
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

func disableButtons():
	for child in base.get_children():
		if child is Button: child.disabled = true
