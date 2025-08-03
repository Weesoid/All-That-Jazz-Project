extends Control

@onready var container = $VBoxContainer

func _ready():
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		var bar = load("res://scenes/user_interface/GeneralCombatantStatus.tscn").instantiate()
		bar.setStatus(combatant)
		container.add_child(bar)
