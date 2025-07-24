extends Control

@onready var buttons= $VBoxContainer
@onready var end_sentence = $EndSentence
@onready var animator = $AnimationPlayer
@onready var saves = $Saves
@onready var penalty = $Penalty
var current_currency = PlayerGlobals.currency
var saved_game: SavedGame = load("res://saves/%s.tres" % PlayerGlobals.save_name)

func _ready():
	randomize()
	OverworldGlobals.shakeCamera(20,20)
	var random_penalty = randf_range(0.2, 0.3)
	penalty.text = '-'+str(int(random_penalty*100))+'% Slips and Morale.'
	var reduced_currency = PlayerGlobals.currency - int(random_penalty * PlayerGlobals.currency)
	var reduced_exp = PlayerGlobals.current_exp - int(random_penalty * PlayerGlobals.getRequiredExp())
	if reduced_currency < 0: reduced_currency = 0
	if reduced_exp < 0: reduced_exp = 0
	for data in saved_game.save_data:
		if data is PlayerSaveData:
			data.currency = reduced_currency
			data.current_exp = reduced_exp
			PlayerGlobals.currency = reduced_currency
			PlayerGlobals.current_exp = reduced_exp
			break
	ResourceSaver.save(saved_game, "res://saves/%s.tres" % PlayerGlobals.save_name)
	
	animator.play('Show')
	OverworldGlobals.setMouseController(true)
	OverworldGlobals.setMenuFocus(buttons)

func _on_yes_pressed():
	buttons.hide()
	penalty.hide()
	if FileAccess.file_exists("res://saves/%s.tres" % PlayerGlobals.save_name):
		OverworldGlobals.changeMap(saved_game.current_map_path, '0,0,0', 'SavePoint', true, true)
		PlayerGlobals.healCombatants(0.25,false)
#		for combatant in OverworldGlobals.getCombatantSquad('Player'):
#			combatant.LINGERING_STATUS_EFFECTS.append('Faded I')
		PlayerGlobals.overworld_stats['stamina'] = 100.0
		OverworldGlobals.getPlayer().setUIVisibility(true)

func _on_no_pressed():
	get_tree().change_scene_to_file("res://scenes/user_interface/StartMenu.tscn")
