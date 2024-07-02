extends Control

@onready var buttons= $VBoxContainer
@onready var end_sentence = $EndSentence
@onready var animator = $AnimationPlayer
@onready var saves = $Saves

func _ready():
	animator.play('Show')
	await animator.animation_finished
	OverworldGlobals.setMenuFocus(buttons)

func _on_yes_pressed():
	if FileAccess.file_exists("res://saves/Save.tres"):
		var saved_game: SavedGame = load("res://saves/Save.tres")
		OverworldGlobals.changeMap(saved_game.current_map_path, '0,0,0', 'SavePoint', true, true)
		PlayerGlobals.healCombatants()
	else:
		get_tree().quit()

func _on_no_button_down():
	get_tree().quit()
